-- Migration 029 : Unifier les politiques admin avec is_admin() (évite la récursion)
-- À appliquer dans Supabase SQL Editor

-- ── 1. Créer / remplacer is_admin() (SECURITY DEFINER + row_security off) ────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE
SET row_security = off
AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin');
$$;
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- ── 2. Politique SELECT sur users (sans récursion) ───────────────────────────
DROP POLICY IF EXISTS "users_admin_select" ON users;
CREATE POLICY "users_admin_select"
  ON users FOR SELECT
  USING (auth.uid() = id OR is_admin());

-- ── 3. Politiques admin sur retraits (sans récursion) ────────────────────────
DROP POLICY IF EXISTS "retraits_admin_select" ON retraits;
CREATE POLICY "retraits_admin_select"
  ON retraits FOR SELECT
  USING (is_admin());

DROP POLICY IF EXISTS "retraits_admin_update" ON retraits;
CREATE POLICY "retraits_admin_update"
  ON retraits FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());
