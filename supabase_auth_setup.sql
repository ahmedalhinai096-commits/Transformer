s-- ============================================
-- TEAM AUTHENTICATION - SUPABASE SETUP
-- ============================================
-- Run this SQL in your Supabase SQL Editor (Dashboard → SQL Editor → New Query)
--
-- This creates a secure team_auth table with bcrypt-hashed passwords
-- and an RPC function for server-side password verification.
-- No plaintext passwords are stored or exposed to the frontend.
-- ============================================

-- 1. ENABLE pgcrypto EXTENSION (for password hashing)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. CREATE team_auth TABLE
CREATE TABLE IF NOT EXISTS public.team_auth (
  id SERIAL PRIMARY KEY,
  team_name TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ENABLE ROW LEVEL SECURITY (block direct table access)
ALTER TABLE public.team_auth ENABLE ROW LEVEL SECURITY;
-- No SELECT/INSERT/UPDATE/DELETE policies = nobody can read the table directly via REST API.
-- The RPC function uses SECURITY DEFINER to bypass RLS.

-- 4. CREATE SERVER-SIDE LOGIN VERIFICATION FUNCTION
--    This function runs with the table owner's privileges (SECURITY DEFINER),
--    so the anon role can call it but cannot read the table directly.
CREATE OR REPLACE FUNCTION public.verify_team_login(p_team TEXT, p_password TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.team_auth
    WHERE team_name = p_team
      AND password_hash = extensions.crypt(p_password, password_hash)
  );
$$;

-- 5. GRANT EXECUTE PERMISSION TO ANON ROLE
GRANT EXECUTE ON FUNCTION public.verify_team_login(TEXT, TEXT) TO anon;

-- 6. SEED TEAM CREDENTIALS (bcrypt-hashed)
--    ⚠️ IMPORTANT: Change these passwords after initial setup!
--    To update a password later, run:
--      UPDATE public.team_auth SET password_hash = extensions.crypt('NEW_PASSWORD', extensions.gen_salt('bf')) WHERE team_name = 'TEAM_NAME';
INSERT INTO public.team_auth (team_name, password_hash, is_admin) VALUES
  ('Ibri',       extensions.crypt('ib11',      extensions.gen_salt('bf')), false),
  ('Wadi Alain', extensions.crypt('wa22',      extensions.gen_salt('bf')), false),
  ('Araqi',      extensions.crypt('ar33',      extensions.gen_salt('bf')), false),
  ('Hijermat',   extensions.crypt('hj44',      extensions.gen_salt('bf')), false),
  ('Dank',       extensions.crypt('dk55',      extensions.gen_salt('bf')), false),
  ('Yanqul',     extensions.crypt('yq66',      extensions.gen_salt('bf')), false),
  ('__admin__',  extensions.crypt('admin2025', extensions.gen_salt('bf')), true)
ON CONFLICT (team_name) DO NOTHING;

-- ============================================
-- HELPER: CHANGE A TEAM PASSWORD
-- ============================================
-- UPDATE public.team_auth
-- SET password_hash = extensions.crypt('NEW_PASSWORD_HERE', extensions.gen_salt('bf'))
-- WHERE team_name = 'TEAM_NAME_HERE';
--
-- Example - change admin password:
-- UPDATE public.team_auth
-- SET password_hash = extensions.crypt('myNewSecurePassword', extensions.gen_salt('bf'))
-- WHERE team_name = '__admin__';
-- ============================================
