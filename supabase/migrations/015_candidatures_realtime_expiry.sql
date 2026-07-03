-- Migration 015 : Candidatures Realtime + expiration automatique des courses

-- ── 1. CANDIDATURES dans la publication Realtime ──────────────────────────────
-- BUG PRINCIPAL : sans cette ligne, abonnerCandidatures() ne reçoit jamais les
-- nouvelles propositions des TR → le client reste bloqué sur "Diffusion en cours"
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE candidatures;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- ── 2. Ajouter 'expiree' dans le CHECK statut de courses ─────────────────────
ALTER TABLE courses
  DROP CONSTRAINT IF EXISTS courses_statut_check;

ALTER TABLE courses
  ADD CONSTRAINT courses_statut_check
  CHECK (statut IN (
    'en_attente', 'acceptee', 'en_cours',
    'terminee',   'annulee',  'expiree',  'livree'
  ));

-- ── 3. Colonne expires_at = created_at + 1 heure ─────────────────────────────
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

-- Backfill pour les courses en_attente existantes
UPDATE courses
SET expires_at = created_at + interval '1 hour'
WHERE expires_at IS NULL;

-- Trigger pour les nouvelles courses
CREATE OR REPLACE FUNCTION set_course_expires_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.expires_at IS NULL THEN
    NEW.expires_at := NEW.created_at + interval '1 hour';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_course_expires_at ON courses;
CREATE TRIGGER trg_course_expires_at
  BEFORE INSERT ON courses
  FOR EACH ROW EXECUTE FUNCTION set_course_expires_at();

-- ── 4. Fonction d'expiration (appelable manuellement ou via pg_cron) ──────────
CREATE OR REPLACE FUNCTION expirer_courses_inactives()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE nb int;
BEGIN
  UPDATE courses
  SET statut = 'expiree', updated_at = now()
  WHERE statut = 'en_attente'
    AND expires_at < now();
  GET DIAGNOSTICS nb = ROW_COUNT;
  RETURN nb;
END;
$$;

GRANT EXECUTE ON FUNCTION expirer_courses_inactives() TO authenticated;

-- ── 5. pg_cron : expiration automatique toutes les 15 min ─────────────────────
-- Optionnel — nécessite l'extension pg_cron (Supabase > Database > Extensions)
-- Sans pg_cron, l'expiration est déclenchée côté app à chaque chargement.
DO $$
BEGIN
  BEGIN
    PERFORM cron.unschedule('expirer-courses-inactives');
  EXCEPTION WHEN others THEN NULL;  -- schéma cron absent ou job inexistant
  END;
  BEGIN
    PERFORM cron.schedule(
      'expirer-courses-inactives',
      '*/15 * * * *',
      'SELECT expirer_courses_inactives()'
    );
    RAISE NOTICE 'pg_cron : job expirer-courses-inactives planifié toutes les 15 min.';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'pg_cron non disponible — expiration gérée côté application.';
  END;
END $$;
