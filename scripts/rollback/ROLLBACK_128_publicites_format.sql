-- ROLLBACK de la migration 128 (publicites.format).
-- ⚠️ N'exécuter QUE si l'APK/admin web lisant `format` n'est plus en service :
-- un SELECT PostgREST référençant une colonne supprimée échoue en entier.
-- Ordre sûr : revenir à l'ancien build (sans lecture de `format`) PUIS ce rollback.

DROP INDEX IF EXISTS public.idx_publicites_interstitiel;

ALTER TABLE public.publicites DROP CONSTRAINT IF EXISTS chk_publicites_format;

ALTER TABLE public.publicites DROP COLUMN IF EXISTS format;
