-- Migration 034 — Sécurité : liberer_sequestre_course ne libère que les paiements
-- confirmés par Moneroo (statut = 'sequestre'), jamais les paiements 'initie'
-- (paiement démarré côté client mais non encore confirmé par l'opérateur).
--
-- Avant : statut IN ('sequestre', 'initie')  ← pouvait libérer de l'argent jamais reçu
-- Après : statut = 'sequestre'               ← seulement si Moneroo a confirmé

CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_paiement_id          UUID;
  v_montant              INT;
  v_client_id            UUID;
  v_transporteur_id      UUID;
  v_wallet_tr            UUID;
  v_net                  INT;
  v_commission           INT;
  v_pct_parrainage       NUMERIC;
  v_parrain_client       UUID;
  v_parrain_transporteur UUID;
  v_wallet_parrain       UUID;
  v_comm_parrain         INT;
BEGIN

  -- ── Récupérer UNIQUEMENT les paiements confirmés par Moneroo (sequestre) ────
  -- On n'accepte plus 'initie' : cela signifie que Moneroo n'a pas encore validé
  -- le transfert d'argent. Libérer un paiement 'initie' = créditer le TR sans argent réel.
  SELECT id, montant_fcfa
    INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id
     AND statut = 'sequestre'
   ORDER BY created_at DESC
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  -- ── Récupérer client et transporteur ────────────────────────────────────────
  SELECT client_id, transporteur_id
    INTO v_client_id, v_transporteur_id
    FROM courses
   WHERE id = p_course_id;

  IF v_transporteur_id IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- ── Calcul commission CAARCO (15%) et net transporteur (85%) ────────────────
  v_commission := ROUND(v_montant * 0.15);
  v_net        := v_montant - v_commission;

  -- ── Crédit transporteur ─────────────────────────────────────────────────────
  INSERT INTO wallets(user_id, solde_fcfa)
    VALUES (v_transporteur_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_tr FROM wallets WHERE user_id = v_transporteur_id;

  UPDATE wallets
     SET solde_fcfa = solde_fcfa + v_net,
         updated_at = NOW()
   WHERE id = v_wallet_tr;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  -- ── Libérer le paiement ──────────────────────────────────────────────────────
  UPDATE paiements
     SET statut    = 'libere',
         libere_at = NOW()
   WHERE id = v_paiement_id;

  UPDATE courses
     SET statut_paiement = 'libere',
         updated_at      = NOW()
   WHERE id = p_course_id;

  -- ── Parrainage (prélevé sur la commission CAARCO) ────────────────────────────
  SELECT valeur::NUMERIC
    INTO v_pct_parrainage
    FROM parametres
   WHERE cle = 'taux_commission_parrainage'
   LIMIT 1;

  v_pct_parrainage := COALESCE(v_pct_parrainage, 0.10);

  -- Parrain du client
  SELECT parrain_id INTO v_parrain_client
    FROM users WHERE id = v_client_id AND parrain_id IS NOT NULL;

  IF v_parrain_client IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_client, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_client;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW()
      WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  -- Parrain du transporteur
  SELECT parrain_id INTO v_parrain_transporteur
    FROM users WHERE id = v_transporteur_id AND parrain_id IS NOT NULL;

  IF v_parrain_transporteur IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_transporteur, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_transporteur;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW()
      WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  RETURN jsonb_build_object(
    'ok',          true,
    'paiement_id', v_paiement_id,
    'net_tr',      v_net,
    'commission',  v_commission
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO service_role;
