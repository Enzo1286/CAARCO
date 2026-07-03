-- ══════════════════════════════════════════════════════════════════════════════
-- Migration 062 — positions_gps + completed_at + code_promo + crons manquants
-- Date : 2026-05-30
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. Table positions_gps (RGPD : purge auto 30j) ───────────────────────────
CREATE TABLE IF NOT EXISTS public.positions_gps (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  course_id  UUID        REFERENCES public.courses(id),
  lat        FLOAT8      NOT NULL,
  lng        FLOAT8      NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.positions_gps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "gps_insert" ON public.positions_gps;
DROP POLICY IF EXISTS "gps_select" ON public.positions_gps;

CREATE POLICY "gps_insert" ON public.positions_gps
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "gps_select" ON public.positions_gps
  FOR SELECT USING (
    user_id = auth.uid()
    OR course_id IN (
      SELECT id FROM public.courses
      WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_positions_gps_user_course
  ON public.positions_gps(user_id, course_id, created_at DESC);

-- ── 2. Colonnes manquantes sur courses ────────────────────────────────────────
-- completed_at : marqué par le trigger after_course_terminee
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- code_promo : code promo appliqué à la course
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS code_promo TEXT;

-- ── 3. Cron : expiration auto des courses en_attente (toutes les 15 min) ──────
SELECT cron.schedule(
  'expirer-courses-inactives',
  '*/15 * * * *',
  'SELECT expirer_courses_inactives()'
)
WHERE NOT EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'expirer-courses-inactives'
);

-- ── 4. Cron : purge RGPD des positions GPS (chaque nuit à 2h) ────────────────
SELECT cron.schedule(
  'caarco-purge-gps',
  '0 2 * * *',
  $$DELETE FROM public.positions_gps WHERE created_at < NOW() - INTERVAL '30 days'$$
)
WHERE NOT EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'caarco-purge-gps'
);
