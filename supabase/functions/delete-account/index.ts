import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    console.error('delete-account: missing Authorization header')
    return new Response('Unauthorized', { status: 401, headers: corsHeaders })
  }

  try {
    // Standard Supabase Edge Function pattern: anon client + user JWT + persistSession: false
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: { headers: { Authorization: authHeader } },
        auth: { persistSession: false },
      }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      console.error('delete-account: getUser failed:', userError?.message)
      return new Response('Unauthorized', { status: 401, headers: corsHeaders })
    }

    // Delete using admin (service role) client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
      console.error('delete-account: deleteUser failed:', deleteError.message)
      return new Response('Internal Server Error', { status: 500, headers: corsHeaders })
    }

    console.log('delete-account: account deleted for user', user.id)
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('delete-account: unexpected error:', error)
    return new Response('Internal Server Error', { status: 500, headers: corsHeaders })
  }
})
