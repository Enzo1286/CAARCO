-- Migration 056 : Tables et colonnes pour le système de motivation CAARCO
-- Jalons client, classement TR, bonus KYC, statut VIP

-- ── Colonnes users ────────────────────────────────────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_approuve_le  TIMESTAMPTZ;  -- bonus commission 10% pendant 7j
ALTER TABLE users ADD COLUMN IF NOT EXISTS top_tr_mois      BOOLEAN DEFAULT false; -- badge Top 10 TR du mois
ALTER TABLE users ADD COLUMN IF NOT EXISTS rang_tr_mois     INTEGER;       -- classement mensuel entre TR
ALTER TABLE users ADD COLUMN IF NOT EXISTS statut_vip       BOOLEAN DEFAULT false; -- client VIP (100 courses)

-- ── Table jalons_client ───────────────────────────────────────────────────────
-- Enregistre les surprises débloquées à chaque palier de courses.
-- Créée automatiquement par trigger. Révélée et créditée sur action du client.
CREATE TABLE IF NOT EXISTS jalons_client (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  jalon           INTEGER     NOT NULL,  -- 10 | 20 | 30 | 50 | 100
  recompense_type TEXT        NOT NULL,  -- 'wallet_credit' | 'vip'
  recompense_valeur INTEGER,             -- montant XAF (NULL pour VIP)
  statut          TEXT        NOT NULL DEFAULT 'en_attente'
                              CHECK (statut IN ('en_attente', 'revele')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revele_at       TIMESTAMPTZ,
  UNIQUE (client_id, jalon)
);

ALTER TABLE jalons_client ENABLE ROW LEVEL SECURITY;

-- Client : lecture de ses propres jalons
CREATE POLICY "jalons_client_lecture" ON jalons_client
  FOR SELECT USING (auth.uid() = client_id);

-- Index pour la recherche par client
CREATE INDEX IF NOT EXISTS idx_jalons_client_id ON jalons_client (client_id);
