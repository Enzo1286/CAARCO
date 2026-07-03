-- ═══════════════════════════════════════════════════════════════════════
-- Migration 060 — Commission CAARCO : 15% → 20%
-- Date : 2026-06-09
-- Décision : Cedric Timene (propriétaire CAARCO)
-- Impact : liberer_sequestre_course, debiter_commission_especes,
--          candidater_course, calcul_bonus_parrainage_mensuel
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1. Mettre à jour la description dans configurations_systeme ─────────
UPDATE public.configurations_systeme
SET valeur = 'Taux commission pendant la période KYC (10% vs 20% standard)',
    updated_at = NOW()
WHERE cle = 'kyc_commission_taux';

-- ── 2. liberer_sequestre_course — taux standard 0.15 → 0.20 ────────────
CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_pid UUID;    v_montant INT;
  v_cl  UUID;    v_tr      UUID;
  v_wid UUID;    v_net     INT;
  v_comm INT;    v_taux    NUMERIC;
  v_kyc_dt TIMESTAMPTZ;
  v_pct_parr NUMERIC;
  v_parr_cl UUID; v_parr_tr UUID;
  v_wparr UUID;   v_cp INT;
BEGIN
  SELECT id, montant_fcfa INTO v_pid, v_montant
    FROM public.paiements
   WHERE course_id = p_course_id AND statut = 'sequestre'
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  SELECT client_id, transporteur_id INTO v_cl, v_tr
    FROM public.courses WHERE id = p_course_id;

  IF v_tr IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- Commission dynamique : 10% pendant 7j post-KYC, sinon 20%
  SELECT kyc_approuve_le INTO v_kyc_dt FROM public.users WHERE id = v_tr;
  v_taux := CASE
    WHEN v_kyc_dt IS NOT NULL AND NOW() - v_kyc_dt < INTERVAL '7 days' THEN 0.10
    ELSE 0.20
  END;
  v_comm := ROUND(v_montant * v_taux);
  v_net  := v_montant - v_comm;

  -- Créditer transporteur
  INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_tr, 0)
    ON CONFLICT (user_id) DO NOTHING;
  UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_net WHERE user_id = v_tr;
  SELECT id INTO v_wid FROM public.wallets WHERE user_id = v_tr;

  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wid, 'credit_course', v_net, p_course_id::TEXT, 'complete');

  -- Marquer le paiement comme libéré
  UPDATE public.paiements
     SET statut = 'libere', libere_at = NOW()
   WHERE id = v_pid;

  UPDATE public.courses
     SET statut = 'terminee', completed_at = NOW()
   WHERE id = p_course_id AND statut != 'terminee';

  -- Parrainage client
  BEGIN
    SELECT code_parrainage INTO v_cp FROM public.users WHERE id = v_cl;
    IF v_cp IS NOT NULL THEN
      SELECT id INTO v_parr_cl FROM public.users
       WHERE code_parrainage = v_cp AND id != v_cl LIMIT 1;
    END IF;
  EXCEPTION WHEN OTHERS THEN v_parr_cl := NULL; END;

  IF v_parr_cl IS NOT NULL THEN
    SELECT pct_commission_reversee INTO v_pct_parr
      FROM public.configurations_parrainage LIMIT 1;
    v_pct_parr := COALESCE(v_pct_parr, 0.10);
    DECLARE v_bonus_parr INT := GREATEST(0, ROUND(v_comm * v_pct_parr));
    BEGIN
      INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_parr_cl, 0)
        ON CONFLICT (user_id) DO NOTHING;
      SELECT id INTO v_wparr FROM public.wallets WHERE user_id = v_parr_cl;
      UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_bonus_parr WHERE user_id = v_parr_cl;
      INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
        VALUES (v_wparr, 'bonus_parrainage', v_bonus_parr, p_course_id::TEXT, 'complete');
    END;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'montant', v_montant,
    'commission', v_comm,
    'net_tr', v_net,
    'taux', v_taux
  );
END;
$$;

-- ── 3. debiter_commission_especes — 0.15 → 0.20 ──────────────────────
CREATE OR REPLACE FUNCTION debiter_commission_especes(p_course_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_tr_id    UUID;   v_prix     INTEGER;
  v_methode  TEXT;   v_comm     INTEGER;
  v_wallet   UUID;   v_solde    INTEGER;
BEGIN
  SELECT transporteur_id, prix_fcfa, methode_paiement
    INTO v_tr_id, v_prix, v_methode
    FROM public.courses WHERE id = p_course_id;
  IF v_tr_id IS NULL THEN RAISE EXCEPTION 'Course introuvable : %', p_course_id; END IF;
  IF v_methode != 'especes' THEN RAISE EXCEPTION 'Course non espèces (methode: %)', v_methode; END IF;

  v_comm := ROUND(v_prix * 0.20);
  SELECT id, solde_fcfa INTO v_wallet, v_solde FROM public.wallets WHERE user_id = v_tr_id;
  IF v_wallet IS NULL THEN RAISE EXCEPTION 'Wallet introuvable pour le transporteur : %', v_tr_id; END IF;
  IF v_solde < v_comm THEN
    RAISE EXCEPTION 'Solde insuffisant (solde: % XAF, commission: % XAF)', v_solde, v_comm;
  END IF;

  UPDATE public.wallets SET solde_fcfa = solde_fcfa - v_comm WHERE id = v_wallet;
  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wallet, 'debit_commission_especes', v_comm, p_course_id::TEXT, 'complete');

  RETURN v_comm;
END;
$$;
GRANT EXECUTE ON FUNCTION debiter_commission_especes(UUID) TO authenticated;

-- ── 4. candidater_course — vérif wallet espèces 0.15 → 0.20 ──────────
-- Mise à jour du calcul de la commission requise pour les courses espèces
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
  IF NOT FOUND THEN RAISE EXCEPTION 'Course introuvable : %', p_course_id; END IF;
  IF v_course.statut NOT IN ('EN_RECHERCHE','DEMANDE') THEN
    RAISE EXCEPTION 'Course non disponible (statut: %)', v_course.statut;
  END IF;

  SELECT statut_kyc INTO v_kyc_statut FROM public.transporteurs_kyc WHERE user_id = p_transporteur_id;
  IF v_kyc_statut IS NULL THEN v_kyc_statut := 'EN_ATTENTE'; END IF;
  IF v_kyc_statut != 'APPROUVE' THEN
    SELECT COUNT(*) INTO v_mois_nb
      FROM public.courses
     WHERE transporteur_id = p_transporteur_id
       AND statut = 'terminee'
       AND DATE_TRUNC('month', completed_at) = DATE_TRUNC('month', NOW());
    IF v_mois_nb >= 2 THEN
      RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE'
        USING HINT = 'Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC pour continuer.';
    END IF;
  END IF;

  -- Vérif solde pour cours espèces (commission 20%)
  v_methode := v_course.methode_paiement;
  v_prix    := v_course.prix_fcfa;
  IF v_methode = 'especes' THEN
    v_commission := ROUND(v_prix::NUMERIC * 0.20)::INTEGER;
    SELECT COALESCE(solde_fcfa, 0) INTO v_solde
      FROM public.wallets WHERE user_id = p_transporteur_id;
    IF v_solde < v_commission THEN
      RAISE EXCEPTION 'SOLDE_INSUFFISANT'
        USING HINT = format('Solde wallet (%s XAF) insuffisant pour la commission de %s XAF.', v_solde, v_commission);
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
