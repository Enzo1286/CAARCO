-- Migration 045 : correction candidater_course — suppression de updated_at inexistant

CREATE OR REPLACE FUNCTION candidater_course(p_course_id UUID, p_transporteur_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET row_security = off AS $$
DECLARE
  v_methode     TEXT;
  v_prix        INTEGER;
  v_commission  INTEGER;
  v_solde       INTEGER;
  v_candidature JSONB;
BEGIN
  SELECT methode_paiement, prix_fcfa
    INTO v_methode, v_prix
    FROM courses
   WHERE id = p_course_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = 'Cette course n''est plus disponible.';
  END IF;

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

  INSERT INTO candidatures (course_id, transporteur_id, statut)
  VALUES (p_course_id, p_transporteur_id, 'propose')
  ON CONFLICT (course_id, transporteur_id)
    DO UPDATE SET statut = 'propose'
  RETURNING to_jsonb(candidatures.*) INTO v_candidature;

  RETURN v_candidature;
END;
$$;

GRANT EXECUTE ON FUNCTION candidater_course(UUID, UUID) TO authenticated;
