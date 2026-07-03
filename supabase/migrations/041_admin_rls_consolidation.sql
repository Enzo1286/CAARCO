-- Migration 041 : Consolidation des politiques admin
-- À appliquer si les utilisateurs n'apparaissent pas dans le dashboard admin
-- Résout les problèmes de récursion RLS en utilisant SECURITY DEFINER

-- ── 1. Fonction is_admin() sans récursion RLS ─────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE
SET row_security = off
AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin');
$$;
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- ── 2. Policy SELECT sur users (admin voit tout le monde) ────────────────────
DROP POLICY IF EXISTS "users_admin_select" ON users;
DROP POLICY IF EXISTS "users_own_data"     ON users;

-- Recréer une politique unifiée qui couvre les deux cas
CREATE POLICY "users_select"
  ON users FOR SELECT
  USING (auth.uid() = id OR is_admin());

-- Maintenir la politique ALL d'origine pour les non-admins (INSERT, UPDATE, DELETE)
-- Elle n'existait que pour SELECT + UPDATE, donc on la recrée proprement
DROP POLICY IF EXISTS "users_update_soi" ON users;
CREATE POLICY "users_update_soi"
  ON users FOR UPDATE
  USING (auth.uid() = id OR is_admin())
  WITH CHECK (auth.uid() = id OR is_admin());

-- ── 3. Admin peut INSERT de nouveaux utilisateurs (ex: créer un compte admin) ─
DROP POLICY IF EXISTS "users_admin_insert" ON users;
CREATE POLICY "users_admin_insert"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id OR is_admin());

-- ── 4. Politiques retraits ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "retraits_admin_select" ON retraits;
DROP POLICY IF EXISTS "retraits_admin_update" ON retraits;

CREATE POLICY "retraits_admin_select"
  ON retraits FOR SELECT
  USING (transporteur_id = auth.uid() OR is_admin());

CREATE POLICY "retraits_admin_update"
  ON retraits FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── 5. Admin voit toutes les courses ─────────────────────────────────────────
DROP POLICY IF EXISTS "courses_admin_select" ON courses;
CREATE POLICY "courses_admin_select"
  ON courses FOR SELECT
  USING (
    client_id = auth.uid()
    OR transporteur_id = auth.uid()
    OR statut = 'en_attente'
    OR is_admin()
  );

-- ── 6. Admin voit les dossiers KYC de tous les transporteurs ────────────────
ALTER TABLE IF EXISTS transporteurs_kyc ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kyc_admin_select" ON transporteurs_kyc;
CREATE POLICY "kyc_admin_select"
  ON transporteurs_kyc FOR SELECT
  USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "kyc_admin_update" ON transporteurs_kyc;
CREATE POLICY "kyc_admin_update"
  ON transporteurs_kyc FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── 7. Admin voit tous les paiements ─────────────────────────────────────────
DROP POLICY IF EXISTS "paiements_admin_select" ON paiements;
CREATE POLICY "paiements_admin_select"
  ON paiements FOR SELECT
  USING (client_id = auth.uid() OR is_admin());

-- ── 8. Admin voit tous les wallets ───────────────────────────────────────────
DROP POLICY IF EXISTS "wallets_admin_select" ON wallets;
CREATE POLICY "wallets_admin_select"
  ON wallets FOR SELECT
  USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "wallets_admin_update" ON wallets;
CREATE POLICY "wallets_admin_update"
  ON wallets FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

-- ── 9. Diagnostic : compter les écarts auth.users vs public.users ─────────────
-- (Exécuter manuellement pour diagnostiquer des comptes "fantômes")
-- SELECT count(*) FROM auth.users au
-- WHERE NOT EXISTS (SELECT 1 FROM public.users pu WHERE pu.id = au.id);
