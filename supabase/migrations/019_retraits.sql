-- Migration 019 : Table retraits (demandes de retrait des transporteurs)

CREATE TABLE IF NOT EXISTS retraits (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  montant_fcfa     INTEGER     NOT NULL CHECK (montant_fcfa >= 1000),
  methode          TEXT        NOT NULL CHECK (methode IN ('orange_money', 'mtn_momo')),
  numero_mobile    TEXT        NOT NULL,
  statut           TEXT        NOT NULL DEFAULT 'en_attente'
                               CHECK (statut IN ('en_attente', 'traite', 'refuse')),
  note_admin       TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index pour requêtes par transporteur
CREATE INDEX IF NOT EXISTS retraits_transporteur_id_idx ON retraits(transporteur_id);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION maj_retraits_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_retraits_updated_at ON retraits;
CREATE TRIGGER trg_retraits_updated_at
  BEFORE UPDATE ON retraits
  FOR EACH ROW EXECUTE FUNCTION maj_retraits_updated_at();

-- RLS
ALTER TABLE retraits ENABLE ROW LEVEL SECURITY;

-- Transporteur : voir ses propres demandes
CREATE POLICY "retraits_select_own"
  ON retraits FOR SELECT
  USING (transporteur_id = auth.uid());

-- Transporteur : créer ses demandes
CREATE POLICY "retraits_insert_own"
  ON retraits FOR INSERT
  WITH CHECK (transporteur_id = auth.uid());

-- Transporteur : ne peut pas modifier après soumission
-- (les admins passent par service_role)
