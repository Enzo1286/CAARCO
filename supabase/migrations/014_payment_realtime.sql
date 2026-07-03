-- Migration 014 : Realtime courses + RPC paiement atomique

-- ── 1. Courses dans la publication Realtime ───────────────────────────────────
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE courses;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- ── 2. S'assurer que 'recette' est dans le CHECK de transactions_wallet ────────
ALTER TABLE transactions_wallet
  DROP CONSTRAINT IF EXISTS transactions_wallet_type_check;

ALTER TABLE transactions_wallet
  ADD CONSTRAINT transactions_wallet_type_check
  CHECK (type IN ('recharge','paiement','remboursement','recette'));

-- ── 3. RPC process_ride_payment — atomique : débit client + crédit TR ─────────
CREATE OR REPLACE FUNCTION process_ride_payment(
  p_client_id uuid,
  p_ride_id   uuid,
  p_tr_id     uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_montant          int;
  v_client_wallet_id uuid;
  v_tr_wallet_id     uuid;
  v_solde_client     int;
  v_reference        text;
BEGIN
  -- Récupérer le montant exact de la course
  SELECT prix_fcfa INTO v_montant
  FROM courses
  WHERE id = p_ride_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'course_not_found'; END IF;

  -- Wallet client
  SELECT id, solde_fcfa INTO v_client_wallet_id, v_solde_client
  FROM wallets
  WHERE user_id = p_client_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'client_wallet_not_found'; END IF;
  IF v_solde_client < v_montant THEN RAISE EXCEPTION 'insufficient_funds'; END IF;

  -- Wallet transporteur (créer s'il n'existe pas)
  INSERT INTO wallets(user_id, solde_fcfa)
  VALUES (p_tr_id, 0)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_tr_wallet_id FROM wallets WHERE user_id = p_tr_id;

  v_reference := 'PAY-' || UPPER(SUBSTRING(p_ride_id::text FROM 1 FOR 8));

  -- Débit client
  UPDATE wallets
  SET solde_fcfa = solde_fcfa - v_montant, updated_at = now()
  WHERE id = v_client_wallet_id;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
  VALUES (v_client_wallet_id, 'paiement', v_montant, 'validee', v_reference);

  -- Crédit transporteur
  UPDATE wallets
  SET solde_fcfa = solde_fcfa + v_montant, updated_at = now()
  WHERE id = v_tr_wallet_id;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
  VALUES (v_tr_wallet_id, 'recette', v_montant, 'validee', v_reference);

  -- Marquer la course comme payée + livrée
  UPDATE courses
  SET statut_paiement = 'paye', statut = 'livree', updated_at = now()
  WHERE id = p_ride_id;

  RETURN jsonb_build_object(
    'reference', v_reference,
    'montant',   v_montant
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_ride_payment(uuid, uuid, uuid) TO authenticated;
