-- Migration 058 : Crons pg_cron pour le système de motivation CAARCO

-- Classement TR — recalcul quotidien à minuit (actuel mois glissant)
SELECT cron.schedule(
  'caarco-classement-tr-quotidien',
  '0 0 * * *',
  $$SELECT calculer_classement_mensuel()$$
);

-- Bonus volume mensuel — le 1er du mois à 2h du matin (sur le mois précédent)
SELECT cron.schedule(
  'caarco-bonus-volume-mensuel',
  '0 2 1 * *',
  $$SELECT calculer_bonus_volume_mensuel()$$
);

-- Prime qualité mensuelle — le 1er du mois à 2h30 (sur le mois précédent)
SELECT cron.schedule(
  'caarco-prime-qualite-mensuel',
  '30 2 1 * *',
  $$SELECT calculer_prime_qualite_mensuel()$$
);
