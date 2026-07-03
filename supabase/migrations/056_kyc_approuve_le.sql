-- Migration 056 : Date d'approbation KYC pour commission réduite post-validation
-- Ajoute approuve_le sur transporteurs_kyc + trigger auto.
-- La logique commission 10% (vs 15%) pendant 7 jours est appliquée
-- dans liberer_sequestre_course (migration 057 qui remplace la fonction complète).

-- ── 1. Colonne approuve_le ────────────────────────────────────────────────────
ALTER TABLE transporteurs_kyc
  ADD COLUMN IF NOT EXISTS approuve_le TIMESTAMPTZ;

-- Backfill : TRs déjà approuvés reçoivent une date fictive dans le passé
-- (évite qu'ils bénéficient du bonus 7j rétroactivement)
UPDATE transporteurs_kyc
   SET approuve_le = '2000-01-01 00:00:00+00'
 WHERE statut_kyc = 'approuve' AND approuve_le IS NULL;

-- ── 2. Trigger : sette approuve_le au moment de l'approbation admin ───────────
CREATE OR REPLACE FUNCTION set_kyc_approuve_le()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.statut_kyc = 'approuve'
     AND (OLD.statut_kyc IS DISTINCT FROM 'approuve') THEN
    NEW.approuve_le := NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kyc_approuve_le ON transporteurs_kyc;
CREATE TRIGGER trg_kyc_approuve_le
  BEFORE UPDATE ON transporteurs_kyc
  FOR EACH ROW EXECUTE FUNCTION set_kyc_approuve_le();
