-- Migration 064 — Fix confirmer_livraison
-- Problème : le RPC exigeait statut = 'en_cours' strictement.
-- Si le TR était hors ligne lors de "Colis pris en charge", la queue n'avait
-- pas encore synchronisé le statut en base → RPC échouait avec "Course introuvable"
-- affiché sous "Code incorrect" dans l'app.
-- Correction : accepter statut IN ('en_cours', 'acceptee') + trim OTP des deux côtés.

CREATE OR REPLACE FUNCTION confirmer_livraison(p_course_id UUID, p_otp TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_course RECORD;
BEGIN
  -- Verrouiller la ligne pour éviter les doubles appels concurrents
  SELECT id, otp_livraison, transporteur_id, client_id, prix_fcfa, statut
    INTO v_course
    FROM courses
   WHERE id = p_course_id
     AND transporteur_id = auth.uid()
     AND statut IN ('en_cours', 'acceptee')   -- acceptee : sync offline en retard
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course introuvable, statut incorrect, ou non autorisé';
  END IF;

  -- Valider l'OTP (trim des deux côtés pour robustesse)
  IF v_course.otp_livraison IS NULL OR TRIM(v_course.otp_livraison) != TRIM(p_otp) THEN
    RAISE EXCEPTION 'Code OTP incorrect';
  END IF;

  -- Forcer le statut en_cours si la sync offline était en retard
  UPDATE courses
     SET statut       = 'terminee',
         completed_at = NOW(),
         updated_at   = NOW()
   WHERE id = p_course_id;

  -- Libérer le séquestre (RPC atomique existante)
  PERFORM liberer_sequestre_course(p_course_id);

  RETURN jsonb_build_object('success', true, 'course_id', p_course_id);
END;
$$;

GRANT EXECUTE ON FUNCTION confirmer_livraison(UUID, TEXT) TO authenticated;
