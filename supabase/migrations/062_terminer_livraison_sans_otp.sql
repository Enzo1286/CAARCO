-- Migration 062 — terminer_livraison sans OTP
-- OTP supprimé côté TR ; la confirmation vient du bouton "Conclure" côté client.
-- Le TR appuie sur "J'ai livré" → ce RPC marque la course terminée + libère le séquestre.

CREATE OR REPLACE FUNCTION terminer_livraison(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_course RECORD;
BEGIN
  SELECT * INTO v_course FROM public.courses WHERE id = p_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = 'Course inexistante.';
  END IF;

  IF auth.uid() != v_course.transporteur_id THEN
    RAISE EXCEPTION 'NON_AUTORISE'
      USING HINT = 'Seul le transporteur assigné peut terminer la course.';
  END IF;

  IF LOWER(v_course.statut) NOT IN ('en_cours', 'acceptee') THEN
    RAISE EXCEPTION 'STATUT_INVALIDE'
      USING HINT = format('Statut actuel: %s — attendu en_cours ou acceptee.', v_course.statut);
  END IF;

  -- Marquer la course terminée
  UPDATE public.courses SET
    statut       = 'terminee',
    completed_at = NOW(),
    updated_at   = NOW()
  WHERE id = p_course_id;

  -- Libérer le séquestre (Mobile Money uniquement ; espèces = pas de séquestre)
  IF LOWER(COALESCE(v_course.methode_paiement, '')) != 'especes' THEN
    UPDATE public.paiements SET
      statut    = 'libere',
      libere_at = NOW()
    WHERE course_id = p_course_id
      AND LOWER(statut) IN ('sequestre', 'en_attente', 'initie');
  END IF;

  RETURN jsonb_build_object(
    'success',   true,
    'course_id', p_course_id,
    'statut',    'terminee'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION terminer_livraison(UUID) TO authenticated;
