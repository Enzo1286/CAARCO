-- Migration 050 : dates de délivrance et d'expiration des documents KYC

-- 1. Ajouter les colonnes de dates sur transporteurs_kyc
ALTER TABLE public.transporteurs_kyc
  ADD COLUMN IF NOT EXISTS cni_delivrance   DATE,
  ADD COLUMN IF NOT EXISTS cni_expiration   DATE,
  ADD COLUMN IF NOT EXISTS permis_delivrance DATE,
  ADD COLUMN IF NOT EXISTS permis_expiration DATE;

-- 2. Vue pratique pour l'admin : dossiers avec statut de validité des documents
CREATE OR REPLACE VIEW public.kyc_validite AS
SELECT
  k.user_id,
  k.type_vehicule,
  k.statut_kyc,
  k.cni_expiration,
  k.permis_expiration,
  -- Jours restants avant expiration (NULL si pas de date renseignée)
  (k.cni_expiration    - CURRENT_DATE)::INTEGER AS cni_jours_restants,
  (k.permis_expiration - CURRENT_DATE)::INTEGER AS permis_jours_restants,
  -- Statut de chaque document : 'ok' | 'alerte' | 'expire' | 'inconnu'
  CASE
    WHEN k.cni_expiration IS NULL                              THEN 'inconnu'
    WHEN k.cni_expiration < CURRENT_DATE                      THEN 'expire'
    WHEN k.cni_expiration < CURRENT_DATE + INTERVAL '30 days' THEN 'alerte'
    ELSE 'ok'
  END AS cni_statut,
  CASE
    WHEN k.permis_expiration IS NULL                              THEN 'inconnu'
    WHEN k.permis_expiration < CURRENT_DATE                      THEN 'expire'
    WHEN k.permis_expiration < CURRENT_DATE + INTERVAL '30 days' THEN 'alerte'
    ELSE 'ok'
  END AS permis_statut,
  u.nom,
  u.telephone
FROM public.transporteurs_kyc k
JOIN public.users u ON u.id = k.user_id
WHERE k.statut_kyc = 'approuve';

-- 3. Fonction utilitaire : retourne les TR dont un document expire dans N jours
--    Utilisée par l'Edge Function de notification
CREATE OR REPLACE FUNCTION public.tr_documents_expirant(jours INTEGER DEFAULT 30)
RETURNS TABLE(
  user_id UUID,
  nom TEXT,
  telephone TEXT,
  cni_expiration DATE,
  permis_expiration DATE
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    k.user_id,
    u.nom,
    u.telephone,
    k.cni_expiration,
    k.permis_expiration
  FROM public.transporteurs_kyc k
  JOIN public.users u ON u.id = k.user_id
  WHERE k.statut_kyc = 'approuve'
    AND (
      (k.cni_expiration    BETWEEN CURRENT_DATE AND CURRENT_DATE + jours)
      OR
      (k.permis_expiration BETWEEN CURRENT_DATE AND CURRENT_DATE + jours)
    );
$$;
