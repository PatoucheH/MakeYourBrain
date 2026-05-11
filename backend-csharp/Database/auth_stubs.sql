-- Auth schema stubs for local PostgreSQL development.
-- Supabase provides these natively; this file recreates minimal stubs
-- so the public schema functions that reference auth.uid() / auth.users compile.
--
-- When the C# backend calls RPCs, it passes user IDs as explicit parameters,
-- so auth.uid() returning NULL for non-JWT connections is acceptable.
-- The PostgreSQL superuser (postgres) bypasses RLS automatically.

CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT,
    phone       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    last_sign_in_at TIMESTAMPTZ,
    raw_user_meta_data JSONB DEFAULT '{}'::jsonb,
    is_anonymous BOOLEAN DEFAULT false
);

-- Returns the UUID of the currently authenticated user from JWT claims.
-- In local dev, set: SET LOCAL "request.jwt.claims" = '{"sub":"<uuid>","role":"authenticated"}';
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::uuid;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL::uuid;
END;
$$;

-- Returns the role of the currently authenticated user from JWT claims.
CREATE OR REPLACE FUNCTION auth.role()
RETURNS text LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN current_setting('request.jwt.claims', true)::jsonb ->> 'role';
EXCEPTION WHEN OTHERS THEN
    RETURN 'anon';
END;
$$;

-- Returns JWT claims as JSONB.
CREATE OR REPLACE FUNCTION auth.jwt()
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN current_setting('request.jwt.claims', true)::jsonb;
EXCEPTION WHEN OTHERS THEN
    RETURN '{}'::jsonb;
END;
$$;
