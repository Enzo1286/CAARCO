-- ============================================================
-- Migration 021 — Libération du séquestre vers le transporteur
-- ============================================================

-- ── 1. Ajouter libere_at sur paiements (si absent) ──────────────────────────
ALTER TABLE paiements
  ADD COLUMN IF NOT EXISTS libere_at TIMESTAMPTZ;

-- ── 2. RPC liberer_sequestre_course ─────────────────────────────────────────
-- Libère le paiement Mobile Money mis en séquestre vers le wallet du transporteur.
-- Commission CAARCO : 15% | Net transporteur : 85%
-- SECURITY DEFINER : bypass RLS pour créditer le wallet d'un autre utilisateur
CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_paiement_id   UUID;
  v_montant       INT;
  v_transporteur  UUID;
  v_wallet_tr     UUID;
  v_net           INT;
  v_commission    INT;
BEGIN
  -- 1. Récupérer le paiement en séquestre (ou initié) pour cette course
  SELECT id, montant_fcfa
    INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id
     AND statut IN ('sequestre', 'initie')
   ORDER BY created_at DESC
   LIMIT 1;

  -- Aucun paiement Mobile Money trouvé (espèces ou wallet déjà traité)
  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_mobile_payment');
  END IF;

  -- 2. Récupérer le transporteur assigné
  SELECT transporteur_id
    INTO v_transporteur
    FROM courses
   WHERE id = p_course_id;

  IF v_transporteur IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- 3. Calcul commission (15%) et net transporteur (85%)
  v_commission := ROUND(v_montant * 0.15);
  v_net        := v_montant - v_commission;

  -- 4. Wallet transporteur — créé automatiquement s'il n'existe pas
  INSERT INTO wallets(user_id, solde_fcfa)
    VALUES (v_transporteur, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_tr
    FROM wallets
   WHERE user_id = v_transporteur;

  -- 5. Créditer le transporteur
  UPDATE wallets
     SET solde_fcfa = solde_fcfa + v_net,
         updated_at = NOW()
   WHERE id = v_wallet_tr;

  -- 6. Enregistrer dans l'historique des transactions
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  -- 7. Libérer le paiement
  UPDATE paiements
     SET statut    = 'libere',
         libere_at = NOW()
   WHERE id = v_paiement_id;

  -- 8. Marquer la course comme payée et libérée
  UPDATE courses
     SET statut_paiement = 'libere',
         updated_at      = NOW()
   WHERE id = p_course_id;

  RETURN jsonb_build_object(
    'success',          true,
    'net_transporteur', v_net,
    'commission',       v_commission,
    'montant_total',    v_montant
  );
END;
$$;

-- Accessible aux utilisateurs authentifiés (transporteur après OTP)
-- et au service_role (appelé depuis le webhook Moneroo)
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO service_role;

-- ── 3. RLS sur paiements — autoriser le transporteur à lire ses paiements ───
-- Le transporteur doit pouvoir lire le statut du paiement de ses courses
DROP POLICY IF EXISTS "paiements_transporteur_lecture" ON paiements;
CREATE POLICY "paiements_transporteur_lecture" ON paiements
  FOR SELECT USING (
    course_id IN (
      SELECT id FROM courses WHERE transporteur_id = auth.uid()
    )
  );
