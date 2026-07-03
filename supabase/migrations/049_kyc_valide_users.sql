-- Migration 049 : badge "TR vérifié" — colonne kyc_valide sur users + trigger auto

-- 1. Ajouter la colonne
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS kyc_valide BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Rétroactivement marquer les TR déjà approuvés
UPDATE public.users u
SET kyc_valide = TRUE
FROM public.transporteurs_kyc k
WHERE k.user_id = u.id AND k.statut_kyc = 'approuve';

-- 3. Trigger : quand admin approuve/révoque un KYC → users.kyc_valide se met à jour seul
CREATE OR REPLACE FUNCTION public.sync_kyc_valide()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.statut_kyc = 'approuve' THEN
    UPDATE public.users SET kyc_valide = TRUE  WHERE id = NEW.user_id;
  ELSE
    -- Rejet, infos_manquantes, retour en attente → retrait du badge
    UPDATE public.users SET kyc_valide = FALSE WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_sync_kyc_valide ON public.transporteurs_kyc;
CREATE TRIGGER trigger_sync_kyc_valide
  AFTER INSERT OR UPDATE OF statut_kyc ON public.transporteurs_kyc
  FOR EACH ROW EXECUTE FUNCTION public.sync_kyc_valide();
