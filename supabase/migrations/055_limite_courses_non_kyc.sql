-- Migration 055 : Limite de 2 courses/mois pour les transporteurs sans KYC validé
-- À partir de la 3e course du mois, la RPC candidater_course lève LIMITE_KYC_ATTEINTE
-- → l'app redirige le TR vers SoumissionKYCScreen.

CREATE OR REPLACE FUNCTION candidater_course(p_course_id UUID, p_transporteur_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET row_security = off AS $$
DECLARE
  v_methode        TEXT;
  v_prix           INTEGER;
  v_commission     INTEGER;
  v_solde          INTEGER;
  v_kyc_valide     BOOLEAN;
  v_courses_mois   INTEGER;
  v_candidature    JSONB;
BEGIN
  -- ── 1. Course disponible ───────────────────────────────────────────────────
  SELECT methode_paiement, prix_fcfa
    INTO v_methode, v_prix
    FROM courses
   WHERE id = p_course_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = 'Cette course n''est plus disponible.';
  END IF;

  -- ── 2. Limite mensuelle pour TR non vérifiés ───────────────────────────────
  SELECT COALESCE(kyc_valide, false)
    INTO v_kyc_valide
    FROM users
   WHERE id = p_transporteur_id;

  IF NOT v_kyc_valide THEN
    SELECT COUNT(*)::INTEGER INTO v_courses_mois
      FROM courses
     WHERE transporteur_id = p_transporteur_id
       AND statut          = 'terminee'
       AND date_trunc('month', COALESCE(completed_at, updated_at)) =
           date_trunc('month', NOW());

    IF v_courses_mois >= 2 THEN
      RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE'
        USING HINT = 'Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC pour continuer sans restriction.';
    END IF;
  END IF;

  -- ── 3. Vérification solde wallet (courses en espèces) ─────────────────────
  IF v_methode = 'especes' THEN
    v_commission := ROUND(v_prix::numeric * 0.15)::INTEGER;
    SELECT COALESCE(solde_fcfa, 0) INTO v_solde
      FROM wallets WHERE user_id = p_transporteur_id;
    IF v_solde < v_commission THEN
      RAISE EXCEPTION 'SOLDE_INSUFFISANT'
        USING HINT = format(
          'Solde wallet (%s XAF) insuffisant pour la commission de %s XAF.',
          v_solde, v_commission
        );
    END IF;
  END IF;

  -- ── 4. Insérer / mettre à jour la candidature ──────────────────────────────
  INSERT INTO candidatures (course_id, transporteur_id, statut)
  VALUES (p_course_id, p_transporteur_id, 'propose')
  ON CONFLICT (course_id, transporteur_id)
    DO UPDATE SET statut = 'propose', updated_at = NOW()
  RETURNING to_jsonb(candidatures.*) INTO v_candidature;

  RETURN v_candidature;
END;
$$;

GRANT EXECUTE ON FUNCTION candidater_course(UUID, UUID) TO authenticated;
