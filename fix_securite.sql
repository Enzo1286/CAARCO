-- ═══════════════════════════════════════════════════════════════════
-- CORRECTIONS SÉCURITÉ CAARCO — Review 2026-06-20
-- ═══════════════════════════════════════════════════════════════════

-- ─── 1. RPC valider_kyc ──────────────────────────────────────────────────────
-- Remplace les UPDATE directs depuis KYCValidationScreen (client anon).
-- SECURITY DEFINER : vérifie côté serveur que l'appelant est admin.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.valider_kyc(
  p_user_id UUID,
  p_action  TEXT,     -- 'approuve' | 'rejete' | 'infos_manquantes'
  p_motif   TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role       TEXT;
  v_maintenant TIMESTAMPTZ := NOW();
BEGIN
  SELECT role INTO v_role FROM public.users WHERE id = auth.uid();
  IF v_role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'ACCES_REFUSE : rôle admin requis (rôle actuel : %)', COALESCE(v_role, 'non_connecte');
  END IF;

  IF p_action NOT IN ('approuve', 'rejete', 'infos_manquantes') THEN
    RAISE EXCEPTION 'ACTION_INVALIDE : %', p_action;
  END IF;

  UPDATE public.transporteurs_kyc
  SET statut_kyc  = p_action,
      motif_rejet = CASE WHEN p_action <> 'approuve' THEN p_motif ELSE NULL END,
      valide_at   = CASE WHEN p_action = 'approuve'  THEN v_maintenant ELSE NULL END,
      valide_par  = CASE WHEN p_action = 'approuve'  THEN auth.uid()   ELSE NULL END
  WHERE user_id = p_user_id;

  IF p_action = 'approuve' THEN
    UPDATE public.users
    SET statut          = 'actif',
        kyc_valide      = true,
        kyc_approuve_le = v_maintenant
    WHERE id = p_user_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.valider_kyc(UUID, TEXT, TEXT) TO authenticated;


-- ─── 2. RPC changer_statut_course ────────────────────────────────────────────
-- Valide les transitions de statut et vérifie la propriété de la course.
-- Utilise SELECT ... FOR UPDATE pour éviter les race conditions.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.changer_statut_course(
  p_course_id    UUID,
  p_statut_cible TEXT,
  p_extra        JSONB DEFAULT '{}'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id         UUID := auth.uid();
  v_user_role       TEXT;
  v_statut_actuel   TEXT;
  v_client_id       UUID;
  v_transporteur_id UUID;
BEGIN
  -- Verrouiller la ligne pour éviter les transitions concurrentes
  SELECT statut, client_id, transporteur_id
  INTO v_statut_actuel, v_client_id, v_transporteur_id
  FROM public.courses
  WHERE id = p_course_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE : %', p_course_id;
  END IF;

  SELECT role INTO v_user_role FROM public.users WHERE id = v_user_id;

  -- Vérifier la propriété selon le rôle
  IF v_user_role = 'client' AND v_client_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'ACCES_REFUSE : course ne vous appartient pas';
  END IF;
  IF v_user_role = 'transporteur' AND (v_transporteur_id IS NULL OR v_transporteur_id IS DISTINCT FROM v_user_id) THEN
    RAISE EXCEPTION 'ACCES_REFUSE : course non assignée';
  END IF;

  -- Matrice des transitions autorisées
  IF NOT (
    (v_statut_actuel = 'en_attente' AND p_statut_cible IN ('acceptee',  'annulee'))
    OR (v_statut_actuel = 'acceptee'  AND p_statut_cible IN ('en_cours', 'annulee'))
    OR (v_statut_actuel = 'en_cours'  AND p_statut_cible IN ('terminee', 'litige'))
    OR (v_statut_actuel = 'litige'    AND p_statut_cible IN ('terminee', 'annulee') AND v_user_role = 'admin')
  ) THEN
    RAISE EXCEPTION 'TRANSITION_INVALIDE : % → %', v_statut_actuel, p_statut_cible;
  END IF;

  UPDATE public.courses
  SET statut     = p_statut_cible,
      updated_at = NOW()
  WHERE id = p_course_id;

  RETURN jsonb_build_object(
    'course_id',    p_course_id,
    'statut_avant', v_statut_actuel,
    'statut_apres', p_statut_cible
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.changer_statut_course(UUID, TEXT, JSONB) TO authenticated;


-- ─── 3. Rendre le bucket kyc-documents privé ─────────────────────────────────
-- À faire dans le Dashboard Supabase → Storage → kyc-documents → Policies
-- (ne peut pas être fait via SQL, nécessite l'interface Storage ou Management API)
-- ─────────────────────────────────────────────────────────────────────────────
