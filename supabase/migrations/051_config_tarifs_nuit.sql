-- Migration 051 : paramètres de tarification nuit dans configurations_systeme

-- Insérer (ou mettre à jour) les paramètres de majoration nuit
INSERT INTO public.configurations_systeme (cle, valeur)
VALUES
  ('majoration_nuit_pct', '0.20'),   -- 20 % de majoration la nuit
  ('heure_debut_nuit',    '20'),     -- nuit commence à 20h (était 22h)
  ('heure_fin_nuit',      '5')       -- nuit se termine à 5h
ON CONFLICT (cle) DO UPDATE
  SET valeur = EXCLUDED.valeur,
      updated_at = NOW();
