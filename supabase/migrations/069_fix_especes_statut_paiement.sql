-- Migration 069 — Fix "En attente de paiement" pour les courses espèces
--
-- Problème : migration 060 (commission 20%) a remplacé debiter_commission_especes
--   mais a SUPPRIMÉ la ligne qui marquait statut_paiement = 'paye'.
--   Résultat : le TR voit toujours la bannière "En attente de paiement" même
--   après avoir encaissé les espèces.
--
-- Fix :
--   1. terminer_livraison → marque statut_paiement = 'paye' immédiatement
--      pour les courses espèces (le client a payé le TR en liquide sur place)
--   2. debiter_commission_especes → confirme aussi le statut (double sécurité)

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. terminer_livraison — ajouter la mise à jour statut_paiement pour espèces
-- ══════════════════════════════════════════════════════════════════════════════
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

  -- Paiement Mobile Money → libérer le séquestre
  IF LOWER(COALESCE(v_course.methode_paiement, '')) != 'especes' THEN
    UPDATE public.paiements SET
      statut    = 'libere',
      libere_at = NOW()
    WHERE course_id = p_course_id
      AND LOWER(statut) IN ('sequestre', 'en_attente', 'initie');

  -- Espèces → marquer immédiatement comme payé (le client a remis le liquide)
  ELSE
    UPDATE public.courses
    SET statut_paiement = 'paye', updated_at = NOW()
    WHERE id = p_course_id;
  END IF;

  RETURN jsonb_build_object(
    'success',   true,
    'course_id', p_course_id,
    'statut',    'terminee'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION terminer_livraison(UUID) TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. debiter_commission_especes — restaurer statut_paiement = 'paye'
--    (supprimé par erreur dans migration 060)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION debiter_commission_especes(p_course_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_tr_id   UUID;  v_prix    INTEGER;
  v_methode TEXT;  v_comm    INTEGER;
  v_wallet  UUID;  v_solde   INTEGER;
BEGIN
  SELECT transporteur_id, prix_fcfa, methode_paiement
    INTO v_tr_id, v_prix, v_methode
    FROM public.courses WHERE id = p_course_id;

  IF v_tr_id IS NULL THEN
    RAISE EXCEPTION 'Course introuvable : %', p_course_id;
  END IF;
  IF v_methode != 'especes' THEN
    RAISE EXCEPTION 'Course non espèces (methode: %)', v_methode;
  END IF;

  v_comm := ROUND(v_prix * 0.20);

  SELECT id, solde_fcfa INTO v_wallet, v_solde
    FROM public.wallets WHERE user_id = v_tr_id;

  IF v_wallet IS NULL THEN
    RAISE EXCEPTION 'Wallet introuvable pour le transporteur : %', v_tr_id;
  END IF;
  IF v_solde < v_comm THEN
    -- Ne pas bloquer si solde insuffisant : on déduit ce qui est possible
    v_comm := v_solde;
  END IF;

  IF v_comm > 0 THEN
    UPDATE public.wallets
    SET solde_fcfa = solde_fcfa - v_comm
    WHERE id = v_wallet;

    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
      VALUES (v_wallet, 'debit_commission_especes', v_comm, p_course_id::TEXT, 'complete');
  END IF;

  -- Marquer la course payée (bannière disparaît côté TR)
  UPDATE public.courses
  SET statut_paiement = 'paye', updated_at = NOW()
  WHERE id = p_course_id;

  RETURN v_comm;
END;
$$;

GRANT EXECUTE ON FUNCTION debiter_commission_especes(UUID) TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. Corriger les courses espèces déjà terminées dont statut_paiement est resté bloqué
-- ══════════════════════════════════════════════════════════════════════════════
UPDATE public.courses
SET statut_paiement = 'paye', updated_at = NOW()
WHERE statut = 'terminee'
  AND methode_paiement = 'especes'
  AND (statut_paiement IS NULL OR statut_paiement IN ('en_attente', 'non_paye'));
