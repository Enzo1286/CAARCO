-- ============================================================
-- Migration 020 — RLS courses + statuts paiements Moneroo
-- ============================================================

-- ── 1. RLS sur la table courses (idempotent) ─────────────────────────────────
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Client : voit toutes ses propres courses (aucun filtre de statut)
DROP POLICY IF EXISTS "courses_client_lecture" ON courses;
CREATE POLICY "courses_client_lecture" ON courses
  FOR SELECT USING (client_id = auth.uid());

-- Transporteur : voit les courses en_attente (pour accepter) + ses courses assignées
DROP POLICY IF EXISTS "courses_transporteur_lecture" ON courses;
CREATE POLICY "courses_transporteur_lecture" ON courses
  FOR SELECT USING (
    statut = 'en_attente'
    OR transporteur_id = auth.uid()
  );

-- Client : peut créer une course
DROP POLICY IF EXISTS "courses_client_insert" ON courses;
CREATE POLICY "courses_client_insert" ON courses
  FOR INSERT WITH CHECK (client_id = auth.uid());

-- Client & Transporteur : peuvent mettre à jour les courses qui les concernent
DROP POLICY IF EXISTS "courses_update" ON courses;
CREATE POLICY "courses_update" ON courses
  FOR UPDATE USING (
    client_id = auth.uid() OR transporteur_id = auth.uid()
  );

-- ── 2. Étendre les statuts paiements pour Moneroo ────────────────────────────
-- Remplacer la contrainte existante par une qui inclut initie / sequestre / libere

ALTER TABLE paiements DROP CONSTRAINT IF EXISTS paiements_statut_check;
ALTER TABLE paiements DROP CONSTRAINT IF EXISTS paiements_methode_check;

ALTER TABLE paiements
  ADD CONSTRAINT paiements_statut_check
  CHECK (statut IN (
    'en_attente',   -- créé, pas encore payé
    'initie',       -- checkout Moneroo ouvert
    'valide',       -- paiement confirmé (espèces / wallet)
    'sequestre',    -- paiement Mobile Money confirmé, en attente OTP
    'libere',       -- séquestre libéré vers le transporteur
    'rembourse',    -- remboursé au client
    'echec'         -- paiement échoué
  ));

ALTER TABLE paiements
  ADD CONSTRAINT paiements_methode_check
  CHECK (methode IN ('orange_money', 'mtn_momo', 'wallet'));

-- Ajouter les colonnes Moneroo si absentes
ALTER TABLE paiements
  ADD COLUMN IF NOT EXISTS moneroo_payment_id TEXT,
  ADD COLUMN IF NOT EXISTS moneroo_checkout_url TEXT;

-- ── 3. Table transactions_wallet : ajouter colonne moneroo ───────────────────
ALTER TABLE transactions_wallet
  ADD COLUMN IF NOT EXISTS moneroo_payment_id TEXT,
  ADD COLUMN IF NOT EXISTS moneroo_checkout_url TEXT;

-- Étendre statut transactions si nécessaire
ALTER TABLE transactions_wallet DROP CONSTRAINT IF EXISTS transactions_wallet_statut_check;
ALTER TABLE transactions_wallet
  ADD CONSTRAINT transactions_wallet_statut_check
  CHECK (statut IN ('en_attente', 'initie', 'validee', 'echouee', 'annulee'));

-- ── 4. RPC crediter_wallet (appelée par le webhook Moneroo) ──────────────────
CREATE OR REPLACE FUNCTION crediter_wallet(p_wallet_id UUID, p_montant INTEGER)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE wallets
  SET solde_fcfa = solde_fcfa + p_montant,
      updated_at = NOW()
  WHERE id = p_wallet_id;
END;
$$;

-- Sécurité : retirer l'accès public hérité par défaut, accorder uniquement au service_role
-- (le webhook Moneroo s'exécute avec service_role, pas avec anon/authenticated)
REVOKE EXECUTE ON FUNCTION crediter_wallet(UUID, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION crediter_wallet(UUID, INTEGER) TO service_role;

-- ── 5. Donner Realtime sur courses aux deux rôles ────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'courses'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE courses;
  END IF;
END $$;
