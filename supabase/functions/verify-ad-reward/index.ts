import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// URL des clés publiques Google pour vérifier la signature SSV
const GOOGLE_VERIFIER_KEYS_URL = 'https://gstatic.com/admob/reward/verifier-keys.json'

serve(async (req) => {
  // AdMob envoie un GET — toute autre méthode est rejetée
  if (req.method !== 'GET') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  const url = new URL(req.url)
  const params = url.searchParams

  const userId        = params.get('user_id')
  const transactionId = params.get('transaction_id')
  const signature     = params.get('signature')
  const keyId         = params.get('key_id')

  // AdMob envoie une requête de vérification sans paramètres lors de la configuration
  // de l'URL SSV dans la console. On retourne 200 pour valider l'URL.
  if (!userId || !transactionId || !signature || !keyId) {
    return new Response('OK', { status: 200 })
  }

  try {
    // 1. Vérifier la signature ECDSA d'AdMob
    const isValid = await verifyAdMobSignature(url.search, signature, keyId)
    if (!isValid) {
      console.error('SSV: signature invalide pour transaction', transactionId)
      return new Response('Forbidden', { status: 403 })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Anti-replay : insérer le transaction_id (unique)
    //    Si déjà présent → violation de contrainte → on ignore silencieusement
    const { error: insertError } = await supabaseAdmin
      .from('ad_reward_transactions')
      .insert({ transaction_id: transactionId, user_id: userId })

    if (insertError) {
      // Contrainte unique violée = replay attack ou doublon AdMob
      console.log('SSV: transaction déjà traitée', transactionId)
      // On retourne 200 pour éviter qu'AdMob ne relance indéfiniment
      return new Response('OK', { status: 200 })
    }

    // 3. Ajouter les vies via service_role (bypass RLS)
    const { error: livesError } = await supabaseAdmin.rpc('add_lives_from_ad', {
      p_user_id: userId,
    })

    if (livesError) {
      console.error('SSV: erreur ajout vies', livesError)
      return new Response('Internal Error', { status: 500 })
    }

    console.log(`SSV: +2 vies accordées à ${userId} (transaction: ${transactionId})`)
    return new Response('OK', { status: 200 })

  } catch (error) {
    console.error('SSV: erreur fatale', error)
    return new Response('Internal Error', { status: 500 })
  }
})

/**
 * Vérifie la signature ECDSA P-256 / SHA-256 du callback AdMob SSV.
 * Le message signé = query string SANS le paramètre &signature=...
 * (signature est toujours le dernier paramètre selon la spec AdMob)
 */
async function verifyAdMobSignature(
  rawSearch: string,
  signature: string,
  keyId: string
): Promise<boolean> {
  try {
    // Récupérer les clés publiques Google (avec cache 15 min implicite)
    const keysResponse = await fetch(GOOGLE_VERIFIER_KEYS_URL)
    if (!keysResponse.ok) throw new Error('Impossible de récupérer les clés Google')

    const keysData = await keysResponse.json()
    const keyInfo = keysData.keys?.find(
      (k: { keyId: number; pem: string }) => String(k.keyId) === keyId
    )

    if (!keyInfo) {
      console.error('SSV: key_id inconnu:', keyId)
      return false
    }

    // Construire le message à vérifier (query string sans &signature=...)
    const message = buildVerificationMessage(rawSearch)

    // Importer la clé publique EC P-256
    const publicKey = await importEcPublicKey(keyInfo.pem)

    // Décoder la signature base64url → bytes
    const signatureBytes = decodeSignature(signature)
    const messageBytes = new TextEncoder().encode(message)

    return await crypto.subtle.verify(
      { name: 'ECDSA', hash: { name: 'SHA-256' } },
      publicKey,
      signatureBytes,
      messageBytes
    )
  } catch (e) {
    console.error('SSV: erreur vérification signature', e)
    return false
  }
}

/**
 * Extrait le message à vérifier du query string.
 * Selon la spec AdMob, &signature=... est TOUJOURS le dernier paramètre.
 */
function buildVerificationMessage(rawSearch: string): string {
  const query = rawSearch.startsWith('?') ? rawSearch.slice(1) : rawSearch
  const sigIdx = query.lastIndexOf('&signature=')
  return sigIdx !== -1 ? query.substring(0, sigIdx) : query
}

/**
 * Importe une clé publique PEM EC (P-256) pour WebCrypto.
 */
async function importEcPublicKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace('-----BEGIN PUBLIC KEY-----', '')
    .replace('-----END PUBLIC KEY-----', '')
    .replace(/\n/g, '')

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  return crypto.subtle.importKey(
    'spki',
    binaryDer,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['verify']
  )
}

/**
 * Décode une signature base64url en Uint8Array.
 * Si la signature est en format DER (0x30...), la convertit en format P1363 (r||s).
 */
function decodeSignature(base64url: string): Uint8Array {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
  const padded = base64 + '='.repeat((4 - base64.length % 4) % 4)
  const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0))

  // DER format commence par 0x30 — conversion vers P1363 (raw r||s)
  if (bytes[0] === 0x30) {
    return derToP1363(bytes)
  }
  return bytes
}

/**
 * Convertit une signature ECDSA DER en format P1363 (r||s, 64 octets).
 */
function derToP1363(der: Uint8Array): Uint8Array {
  let offset = 2 // skip 0x30 + length

  offset++ // skip 0x02 (integer tag)
  const rLen = der[offset++]
  const r = der.slice(offset, offset + rLen)
  offset += rLen

  offset++ // skip 0x02
  const sLen = der[offset++]
  const s = der.slice(offset, offset + sLen)

  // Pad chaque composant à 32 octets (P-256 → 256 bits)
  const p1363 = new Uint8Array(64)
  const rBytes = r.length > 32 ? r.slice(r.length - 32) : r
  const sBytes = s.length > 32 ? s.slice(s.length - 32) : s
  p1363.set(rBytes, 32 - rBytes.length)
  p1363.set(sBytes, 64 - sBytes.length)
  return p1363
}
