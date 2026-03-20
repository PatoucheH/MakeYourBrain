import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

const jsonHeader = { 'Content-Type': 'application/json' }
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function getJwtPayload(authHeader: string): Record<string, unknown> | null {
  const token = authHeader.replace('Bearer ', '')
  const parts = token.split('.')
  if (parts.length !== 3) return null
  try {
    const base64Url = parts[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const padded = base64 + '='.repeat((4 - base64.length % 4) % 4)
    return JSON.parse(atob(padded))
  } catch {
    return null
  }
}

async function getAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const pemContents = serviceAccount.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '')

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const now = getNumericDate(0)
  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: getNumericDate(60 * 60),
    },
    cryptoKey
  )

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text()
    throw new Error(`Failed to get access token: ${error}`)
  }

  const { access_token } = await tokenResponse.json()
  return access_token
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200 })
  }

  // Réservé aux utilisateurs authentifiés (pas à l'anon key)
  const payload = getJwtPayload(req.headers.get('Authorization') ?? '')
  if (!payload || payload.role !== 'authenticated') {
    return new Response(
      JSON.stringify({ success: false, error: 'Forbidden' }),
      { headers: jsonHeader, status: 403 }
    )
  }

  // C1: L'appelant doit être un UUID valide extrait du JWT
  const callerId = payload.sub as string
  if (!callerId || !UUID_REGEX.test(callerId)) {
    return new Response(
      JSON.stringify({ success: false, error: 'Forbidden' }),
      { headers: jsonHeader, status: 403 }
    )
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const ALLOWED_NOTIFICATION_TYPES = ['match_found', 'your_turn', 'match_over', 'pvp_invitation', 'pvp_invitation_accepted'] as const
    type NotificationType = typeof ALLOWED_NOTIFICATION_TYPES[number]

    // Invitation types skip active-match verification
    const INVITATION_TYPES = ['pvp_invitation', 'pvp_invitation_accepted']

    const NOTIFICATION_CONTENT: Record<NotificationType, { en: { title: string; body: string }; fr: { title: string; body: string } }> = {
      match_found: {
        en: { title: 'Match found!', body: 'An opponent is waiting! Open the app to play.' },
        fr: { title: 'Match trouvé !', body: 'Un adversaire t\'attend ! Ouvre l\'app pour jouer.' },
      },
      your_turn: {
        en: { title: 'Your turn!', body: 'Your opponent has played. It\'s your turn!' },
        fr: { title: 'C\'est ton tour !', body: 'Ton adversaire a joué. À toi de jouer !' },
      },
      match_over: {
        en: { title: 'Match over!', body: 'Your match result is available!' },
        fr: { title: 'Match terminé !', body: 'Le résultat de ta partie est disponible !' },
      },
      pvp_invitation: {
        en: { title: 'PvP Challenge!', body: '{name} challenges you to a match!' },
        fr: { title: 'Défi PvP !', body: '{name} vous défie en match !' },
      },
      pvp_invitation_accepted: {
        en: { title: 'Challenge Accepted!', body: '{name} accepted your PvP challenge!' },
        fr: { title: 'Défi Accepté !', body: '{name} a accepté votre défi PvP !' },
      },
    }

    const { userId, notificationType } = await req.json()

    if (!userId || !notificationType) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: userId, notificationType' }),
        { headers: jsonHeader, status: 400 }
      )
    }

    // Valider le format UUID du destinataire
    if (!UUID_REGEX.test(userId)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid user ID' }),
        { headers: jsonHeader, status: 400 }
      )
    }

    // Valider le type de notification (whitelist stricte — pas de texte libre)
    if (!ALLOWED_NOTIFICATION_TYPES.includes(notificationType as NotificationType)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid notification type' }),
        { headers: jsonHeader, status: 400 }
      )
    }

    if (callerId === userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Forbidden' }),
        { headers: jsonHeader, status: 403 }
      )
    }

    // Pour les types hors invitation, vérifier qu'un match actif existe entre les deux joueurs
    if (!INVITATION_TYPES.includes(notificationType)) {
      const { data: match } = await supabaseAdmin
        .from('pvp_matches')
        .select('id')
        .or(`and(player1_id.eq.${callerId},player2_id.eq.${userId}),and(player1_id.eq.${userId},player2_id.eq.${callerId})`)
        .neq('status', 'completed')
        .neq('status', 'cancelled')
        .maybeSingle()

      if (!match) {
        return new Response(
          JSON.stringify({ success: false, error: 'Forbidden' }),
          { headers: jsonHeader, status: 403 }
        )
      }
    }

    // Récupérer la langue préférée du destinataire + pseudo de l'appelant (pour invitations)
    const [recipientResult, callerResult] = await Promise.all([
      supabaseAdmin.from('user_stats').select('preferred_language').eq('user_id', userId).maybeSingle(),
      INVITATION_TYPES.includes(notificationType)
        ? supabaseAdmin.from('user_stats').select('username').eq('user_id', callerId).maybeSingle()
        : Promise.resolve({ data: null }),
    ])

    const recipientStats = recipientResult.data
    const callerStats = callerResult.data
    const senderName = (callerStats as { username?: string } | null)?.username ?? 'Someone'

    const lang = recipientStats?.preferred_language === 'fr' ? 'fr' : 'en'
    const content = NOTIFICATION_CONTENT[notificationType as NotificationType][lang]
    const title = content.title
    const body = content.body.replace('{name}', senderName)

    // ===== RÉCUPÉRER LES TOKENS FCM DE L'UTILISATEUR =====
    const { data: tokens, error: tokensError } = await supabaseAdmin
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', userId)

    if (tokensError) throw tokensError

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No FCM tokens found for this user' }),
        { headers: jsonHeader, status: 404 }
      )
    }

    // ===== GÉNÉRER L'ACCESS TOKEN OAUTH2 =====
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')
    const projectId = serviceAccount.project_id
    const accessToken = await getAccessToken(serviceAccount)

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    // ===== ENVOYER LA NOTIFICATION À CHAQUE TOKEN =====
    const results = await Promise.all(
      tokens.map(async ({ token }) => {
        const response = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
            },
          }),
        })

        const result = await response.json()

        // Supprimer les tokens FCM invalides ou expirés
        if (!response.ok) {
          const status = result?.error?.status
          if (status === 'UNREGISTERED' || status === 'INVALID_ARGUMENT' || status === 'NOT_FOUND') {
            await supabaseAdmin.from('user_fcm_tokens').delete().eq('token', token)
          }
        }

        return { token: token.substring(0, 20) + '...', status: response.status, result }
      })
    )

    return new Response(
      JSON.stringify({ success: true, sent: results.length, results }),
      { headers: jsonHeader }
    )

  } catch (error) {
    console.error('💥 Erreur fatale:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { headers: jsonHeader, status: 500 }
    )
  }
})
