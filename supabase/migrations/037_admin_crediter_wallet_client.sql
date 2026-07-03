-- Migration 035 — Fonction admin : créditer le wallet d'un client
-- Appelée depuis le panneau admin (role 'admin') avec SECURITY DEFINER
-- Évite de contourner le RLS en donnant au code admin un accès contrôlé

CREATE OR REPLACE FUNCTION admin_crediter_wallet_client(
  p_user_id UUID,
  p_montant  INT,
  p_motif    TEXT DEFAULT 'Crédit administrateur'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet_id UUID;
  v_reference TEXT;
BEGIN
  -- Vérifier que le montant est positif
  IF p_montant <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'montant_invalide');
  END IF;

  -- Créer le wallet si inexistant
  INSERT INTO wallets(user_id, solde_fcfa)
    VALUES (p_user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_user_id;

  IF v_wallet_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'wallet_introuvable');
  END IF;

  -- Créditer le solde
  UPDATE wallets
     SET solde_fcfa = solde_fcfa + p_montant,
         updated_at = NOW()
   WHERE id = v_wallet_id;

  -- Référence unique
  v_reference := 'ADMIN-' || to_char(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

  -- Enregistrer la transaction
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_id, 'recharge', p_montant, 'validee', v_reference);

  RETURN jsonb_build_object(
    'ok',        true,
    'wallet_id', v_wallet_id,
    'montant',   p_montant,
    'reference', v_reference
  );
END;
$$;

-- Seul le rôle 'authenticated' peut appeler cette fonction
-- (le contrôle du rôle 'admin' est fait côté app — la fonction est SECURITY DEFINER)
GRANT EXECUTE ON FUNCTION admin_crediter_wallet_client(UUID, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_crediter_wallet_client(UUID, INT, TEXT) TO service_role;
