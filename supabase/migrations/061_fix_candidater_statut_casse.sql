-- Migration 061 — Fix candidater_course : accepter statuts lowercase (en_attente)
-- Cause : migration 060 vérifiait 'EN_RECHERCHE'/'DEMANDE' mais l'app stocke 'en_attente'
-- Fix : accepter tous les statuts qui signifient "disponible pour candidature"

CREATE OR REPLACE FUNCTION candidater_course(p_course_id UUID, p_transporteur_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_course        RECORD;
  v_candidature   jsonb;
  v_methode       TEXT;
  v_prix          INTEGER;
  v_commission    INTEGER;
  v_solde         INTEGER;
  v_mois_nb       INTEGER;
  v_kyc_statut    TEXT;
BEGIN
  SELECT * INTO v_course FROM public.courses WHERE id = p_course_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = 'Cette course n''est plus disponible.';
  END IF;

  -- Accepter les deux conventions de casse utilisées dans le projet
  IF LOWER(v_course.statut) NOT IN ('en_attente', 'en_recherche', 'demande') THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = format('Course non disponible pour candidature (statut: %s)', v_course.statut);
  END IF;

  -- Vérification limite KYC (2 courses/mois si non approuvé)
  SELECT statut_kyc INTO v_kyc_statut
    FROM public.transporteurs_kyc WHERE user_id = p_transporteur_id;
  IF v_kyc_statut IS NULL THEN v_kyc_statut := 'EN_ATTENTE'; END IF;

  IF v_kyc_statut NOT IN ('APPROUVE', 'approuve') THEN
    SELECT COUNT(*) INTO v_mois_nb
      FROM public.courses
     WHERE transporteur_id = p_transporteur_id
       AND LOWER(statut) = 'terminee'
       AND DATE_TRUNC('month', completed_at) = DATE_TRUNC('month', NOW());
    IF v_mois_nb >= 2 THEN
      RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE'
        USING HINT = 'Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC pour continuer.';
    END IF;
  END IF;

  -- Vérif solde wallet pour courses espèces (commission 20%)
  v_methode := v_course.methode_paiement;
  v_prix    := v_course.prix_fcfa;
  IF v_methode = 'especes' THEN
    v_commission := ROUND(v_prix::NUMERIC * 0.20)::INTEGER;
    SELECT COALESCE(solde_fcfa, 0) INTO v_solde
      FROM public.wallets WHERE user_id = p_transporteur_id;
    IF v_solde < v_commission THEN
      RAISE EXCEPTION 'SOLDE_INSUFFISANT'
        USING HINT = format(
          'Solde wallet (%s XAF) insuffisant pour la commission de %s XAF.',
          v_solde, v_commission
        );
    END IF;
  END IF;

  INSERT INTO public.candidatures(course_id, transporteur_id, statut)
    VALUES (p_course_id, p_transporteur_id, 'propose')
    ON CONFLICT (course_id, transporteur_id) DO UPDATE SET statut = 'propose'
    RETURNING to_jsonb(candidatures.*) INTO v_candidature;

  RETURN v_candidature;
END;
$$;

GRANT EXECUTE ON FUNCTION candidater_course(UUID, UUID) TO authenticated;
