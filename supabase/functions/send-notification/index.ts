import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

const jsonHeader = { 'Content-Type': 'application/json' }

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

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { userId, title, body } = await req.json()

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: userId, title, body' }),
        { headers: jsonHeader, status: 400 }
      )
    }

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
      JSON.stringify({ success: false, error: error.message }),
      { headers: jsonHeader, status: 500 }
    )
  }
})
