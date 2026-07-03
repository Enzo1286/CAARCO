-- Migration 011 : paiement direct client → transporteur (atomique)

-- 1. Ajouter le type 'recette' pour les encaissements côté transporteur
ALTER TABLE transactions_wallet
  DROP CONSTRAINT IF EXISTS transactions_wallet_type_check;
ALTER TABLE transactions_wallet
  ADD CONSTRAINT transactions_wallet_type_check
  CHECK (type IN ('recharge','paiement','remboursement','recette'));

-- 2. RPC atomique : le client paie un transporteur depuis son wallet
--    SECURITY DEFINER → peut créditer le wallet d'un autre utilisateur
CREATE OR REPLACE FUNCTION payer_course_wallet(
  p_destinataire_id uuid,
  p_montant         int,
  p_reference       text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payeur_id       uuid := auth.uid();
  v_wallet_payeur   uuid;
  v_wallet_receveur uuid;
  v_solde           int;
BEGIN
  -- Validation
  IF v_payeur_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;
  IF p_montant <= 0 THEN
    RAISE EXCEPTION 'Montant invalide : doit être > 0';
  END IF;
  IF v_payeur_id = p_destinataire_id THEN
    RAISE EXCEPTION 'Impossible de se payer soi-même';
  END IF;

  -- Wallet du payeur (doit exister)
  SELECT id, solde_fcfa
    INTO v_wallet_payeur, v_solde
    FROM wallets
   WHERE user_id = v_payeur_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Portefeuille introuvable — rechargez d''abord votre wallet';
  END IF;
  IF v_solde < p_montant THEN
    RAISE EXCEPTION 'Solde insuffisant (disponible : % XAF)', v_solde;
  END IF;

  -- Wallet du receveur : créé automatiquement s'il n'existe pas encore
  INSERT INTO wallets (user_id, solde_fcfa)
    VALUES (p_destinataire_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_receveur
    FROM wallets WHERE user_id = p_destinataire_id;

  -- Débit payeur + Crédit receveur (atomique dans la même transaction)
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - p_montant, updated_at = now()
   WHERE id = v_wallet_payeur;

  UPDATE wallets
     SET solde_fcfa = solde_fcfa + p_montant, updated_at = now()
   WHERE id = v_wallet_receveur;

  -- Enregistrement des deux lignes de transaction
  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
  VALUES
    (v_wallet_payeur,   'paiement', p_montant, 'validee', p_reference),
    (v_wallet_receveur, 'recette',  p_montant, 'validee', p_reference);
END;
$$;

-- Autoriser les utilisateurs authentifiés à appeler cette fonction
GRANT EXECUTE ON FUNCTION payer_course_wallet(uuid, int, text) TO authenticated;
