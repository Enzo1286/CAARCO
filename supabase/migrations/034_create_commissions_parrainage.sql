-- ============================================================
-- Migration 034 — Création de la table commissions_parrainage
-- ============================================================
-- Corrige : relation "commissions_parrainage" does not exist
-- Cette table stocke l'historique des commissions versées
-- aux parrains lors de chaque course payée.
-- ============================================================

CREATE TABLE IF NOT EXISTS commissions_parrainage (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parrain_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  filleul_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id    UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  montant_fcfa INTEGER NOT NULL CHECK (montant_fcfa > 0),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_commissions_parrainage_parrain
  ON commissions_parrainage(parrain_id);

CREATE INDEX IF NOT EXISTS idx_commissions_parrainage_filleul
  ON commissions_parrainage(filleul_id);

ALTER TABLE commissions_parrainage ENABLE ROW LEVEL SECURITY;

-- Le parrain peut voir ses propres commissions
CREATE POLICY "parrain_voit_ses_commissions"
  ON commissions_parrainage
  FOR SELECT
  USING (auth.uid() = parrain_id);

-- Les fonctions SECURITY DEFINER (process_ride_payment) peuvent insérer
-- sans restriction RLS (elles tournent avec les droits du owner)
