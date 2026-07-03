-- ═══════════════════════════════════════════════════════════════
-- Migration 052 — Mode maintenance d'urgence
-- Bouton coupe-circuit : active/désactive l'accès à toute l'app
-- ═══════════════════════════════════════════════════════════════

INSERT INTO public.configurations_systeme (cle, valeur)
VALUES
  ('maintenance_mode',    'false'),
  ('maintenance_message', 'L''application est temporairement indisponible pour maintenance. Nous revenons très vite.')
ON CONFLICT (cle) DO UPDATE
  SET valeur     = EXCLUDED.valeur,
      updated_at = NOW();

-- Activer Realtime sur configurations_systeme pour push instantané
ALTER TABLE public.configurations_systeme REPLICA IDENTITY FULL;
