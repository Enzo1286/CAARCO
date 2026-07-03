-- ============================================================
-- Migration 063 — Security fixes
-- 1. confirmer_livraison : validation OTP serveur + transition statut + libération séquestre (atomique)
-- 2. valider_recharge_atomique : validation transaction + crédit wallet (atomique + idempotent)
-- ============================================================

-- ── 1. confirmer_livraison ────────────────────────────────────────────────────
-- Remplace la validation OTP côté client.
-- Vérifie que la course appartient bien au transporteur connecté,
-- que l'OTP correspond, puis passe la course en 'terminee' et libère le séquestre.
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
     AND statut = 'en_cours'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course introuvable, statut incorrect, ou non autorisé';
  END IF;

  -- Valider l'OTP
  IF v_course.otp_livraison IS NULL OR v_course.otp_livraison != p_otp THEN
    RAISE EXCEPTION 'Code OTP incorrect';
  END IF;

  -- Transition de statut
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

-- ── 2. valider_recharge_atomique ─────────────────────────────────────────────
-- Marque la transaction comme validée ET crédite le wallet dans une seule transaction.
-- Idempotent : si la transaction est déjà 'validee', retourne sans rien faire.
CREATE OR REPLACE FUNCTION valider_recharge_atomique(
  p_transaction_id UUID,
  p_wallet_id      UUID,
  p_montant        INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tx RECORD;
BEGIN
  -- Verrouiller la transaction pour l'idempotence
  SELECT id, statut INTO v_tx
    FROM transactions_wallet
   WHERE id = p_transaction_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;

  -- Déjà validée : retour sans erreur (idempotent)
  IF v_tx.statut = 'validee' THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'already_validated');
  END IF;

  -- Créditer le wallet
  UPDATE wallets
     SET solde_fcfa = solde_fcfa + p_montant,
         updated_at = NOW()
   WHERE id = p_wallet_id;

  -- Marquer la transaction comme validée
  UPDATE transactions_wallet
     SET statut     = 'validee',
         updated_at = NOW()
   WHERE id = p_transaction_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION valider_recharge_atomique(UUID, UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION valider_recharge_atomique(UUID, UUID, INT) TO service_role;
