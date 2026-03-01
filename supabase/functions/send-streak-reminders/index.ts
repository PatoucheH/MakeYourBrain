import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

const jsonHeader = { 'Content-Type': 'application/json' }

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

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const nowUtc = new Date()
    const nowUtcHour = nowUtc.getUTCHours()

    // Calcule quels offsets UTC correspondent à 22h locale en ce moment
    // heure locale = UTC + offset → on veut UTC + offset = 22
    // ex: si UTC=20h → offset +2 est à 22h locale (20 + 2 = 22)
    const targetOffsets: number[] = []
    for (let offset = -12; offset <= 14; offset++) {
      if (((nowUtcHour + offset) + 24) % 24 === 22) {
        targetOffsets.push(offset)
      }
    }

    if (targetOffsets.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No timezone at 22h right now', sent: 0 }),
        { headers: jsonHeader }
      )
    }

    // Récupère les users avec streak >= 2 dans les timezones ciblées
    const { data: users, error: usersError } = await supabaseAdmin
      .from('user_stats')
      .select('user_id, current_streak, last_played_at, preferred_language, timezone_offset_hours')
      .gte('current_streak', 2)
      .in('timezone_offset_hours', targetOffsets)

    if (usersError) throw usersError
    if (!users || users.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No eligible users', sent: 0 }),
        { headers: jsonHeader }
      )
    }

    // Filtre les users dont la streak est encore sauvable :
    // - ont joué EXACTEMENT hier dans leur timezone (diff = 1 jour)
    // - n'ont pas encore joué aujourd'hui
    // Un diff >= 2 signifie que la streak est déjà brisée → pas de notif
    const usersToNotify = users.filter(user => {
      if (!user.last_played_at) return false
      const offset = user.timezone_offset_hours ?? 0
      const localNow = new Date(nowUtc.getTime() + offset * 3_600_000)
      const localLastPlayed = new Date(new Date(user.last_played_at).getTime() + offset * 3_600_000)
      const todayStr = localNow.toISOString().slice(0, 10)
      const lastPlayedStr = localLastPlayed.toISOString().slice(0, 10)
      const yesterday = new Date(localNow.getTime() - 86_400_000)
      const yesterdayStr = yesterday.toISOString().slice(0, 10)
      // Joué hier ET pas encore aujourd'hui → streak sauvable
      return lastPlayedStr === yesterdayStr && todayStr !== lastPlayedStr
    })

    if (usersToNotify.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'All eligible users already played today', sent: 0 }),
        { headers: jsonHeader }
      )
    }

    // Prépare FCM
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')
    const projectId = serviceAccount.project_id
    const accessToken = await getAccessToken(serviceAccount)
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    let sent = 0

    for (const user of usersToNotify) {
      const { data: tokens, error: tokensError } = await supabaseAdmin
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', user.user_id)

      if (tokensError || !tokens?.length) continue

      const lang = user.preferred_language ?? 'en'
      const streak = user.current_streak
      const title = lang === 'fr' ? '🔥 Ne perds pas ta série !' : '🔥 Don\'t lose your streak!'
      const body = lang === 'fr'
        ? `Tu as ${streak} jour${streak > 1 ? 's' : ''} de suite. Joue maintenant avant minuit !`
        : `You have a ${streak}-day streak. Play now before midnight!`

      await Promise.all(
        tokens.map(({ token }) =>
          fetch(fcmUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body },
                data: { type: 'streak' },
              },
            }),
          })
        )
      )

      sent++
    }

    return new Response(
      JSON.stringify({ success: true, sent }),
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
