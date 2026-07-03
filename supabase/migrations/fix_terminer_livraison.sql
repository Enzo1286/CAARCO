-- Fix terminer_livraison sans OTP

-- 1. Corriger le trigger points (SECURITY DEFINER pour bypass RLS client)
CREATE OR REPLACE FUNCTION crediter_points_course()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  pts INTEGER;
BEGIN
  IF NEW.statut = 'terminee' AND OLD.statut <> 'terminee' THEN
    pts := GREATEST(1, FLOOR(COALESCE(NEW.prix_fcfa, 0) / 100));
    INSERT INTO transactions_points(user_id, montant, motif, course_id)
    VALUES (NEW.client_id, pts, 'course', NEW.id)
    ON CONFLICT DO NOTHING;
    UPDATE users SET points = points + pts WHERE id = NEW.client_id;
  END IF;
  RETURN NEW;
END;
$$;

-- 2. Créer terminer_livraison (sans OTP)
CREATE OR REPLACE FUNCTION terminer_livraison(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_course RECORD;
BEGIN
  SELECT * INTO v_course FROM public.courses WHERE id = p_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE';
  END IF;

  IF auth.uid() != v_course.transporteur_id THEN
    RAISE EXCEPTION 'NON_AUTORISE';
  END IF;

  IF LOWER(COALESCE(v_course.statut,'')) NOT IN ('en_cours','acceptee') THEN
    RAISE EXCEPTION 'STATUT_INVALIDE: %', v_course.statut;
  END IF;

  UPDATE public.courses SET
    statut = 'terminee', completed_at = NOW(), updated_at = NOW()
  WHERE id = p_course_id;

  PERFORM liberer_sequestre_course(p_course_id);

  RETURN jsonb_build_object('success', true, 'statut', 'terminee');
END;
$$;

GRANT EXECUTE ON FUNCTION terminer_livraison(UUID) TO authenticated;
