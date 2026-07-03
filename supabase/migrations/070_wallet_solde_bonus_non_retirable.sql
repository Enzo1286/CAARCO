-- Migration 070 — Recharges admin non-retirables (solde_bonus)
--
-- Règle métier : les crédits ajoutés manuellement par l'admin (promotions,
-- compensations, remboursements en crédit) ne peuvent PAS être retirés sur
-- Mobile Money. Seuls les revenus de courses (type 'recette') sont retirables.
--
-- Architecture : on ajoute solde_bonus à la table wallets.
--   solde_fcfa   = total disponible (bonus + revenus de courses)
--   solde_bonus  = part non-retirable (crédits admin)
--   solde_retirable = solde_fcfa - solde_bonus (ce qui peut être viré)
--
-- Contrainte : solde_fcfa >= solde_bonus en permanence
--   → garanti par traiter_retrait_admin qui vérifie avant de déduire

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. Ajouter la colonne solde_bonus
-- ══════════════════════════════════════════════════════════════════════════════
ALTER TABLE wallets
  ADD COLUMN IF NOT EXISTS solde_bonus INTEGER NOT NULL DEFAULT 0
  CHECK (solde_bonus >= 0);

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. Initialiser solde_bonus depuis l'historique des transactions 'recharge'
--    (les crédits admin passés deviennent aussi non-retirables rétroactivement)
-- ══════════════════════════════════════════════════════════════════════════════
UPDATE wallets w
SET solde_bonus = LEAST(
  w.solde_fcfa,
  COALESCE((
    SELECT SUM(tw.montant_fcfa)
    FROM transactions_wallet tw
    WHERE tw.wallet_id = w.id
      AND tw.type = 'recharge'
  ), 0)
);

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. admin_crediter_wallet_client — incrémenter aussi solde_bonus
-- ══════════════════════════════════════════════════════════════════════════════
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
  IF p_montant <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'montant_invalide');
  END IF;

  -- Créer le wallet si inexistant
  INSERT INTO wallets(user_id, solde_fcfa, solde_bonus)
    VALUES (p_user_id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_user_id;

  IF v_wallet_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'wallet_introuvable');
  END IF;

  -- Créditer les deux soldes (total + bonus non-retirable)
  UPDATE wallets
     SET solde_fcfa  = solde_fcfa  + p_montant,
         solde_bonus = solde_bonus + p_montant,
         updated_at  = NOW()
   WHERE id = v_wallet_id;

  v_reference := 'ADMIN-' || to_char(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

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

GRANT EXECUTE ON FUNCTION admin_crediter_wallet_client(UUID, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_crediter_wallet_client(UUID, INT, TEXT) TO service_role;

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. traiter_retrait_admin — vérifier que le retrait ne dépasse pas le retirable
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION traiter_retrait_admin(
  p_retrait_id uuid,
  p_statut     text,
  p_note       text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_retrait     retraits%ROWTYPE;
  v_wallet_id   uuid;
  v_solde_total INTEGER;
  v_solde_bonus INTEGER;
  v_retirable   INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Accès refusé — admin requis';
  END IF;

  IF p_statut NOT IN ('traite', 'refuse') THEN
    RAISE EXCEPTION 'Statut invalide : %', p_statut;
  END IF;

  SELECT * INTO v_retrait
  FROM retraits
  WHERE id = p_retrait_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Retrait introuvable ou déjà traité';
  END IF;

  UPDATE retraits
  SET statut     = p_statut,
      note_admin = p_note,
      updated_at = now()
  WHERE id = p_retrait_id;

  IF p_statut = 'traite' THEN
    SELECT id, solde_fcfa, COALESCE(solde_bonus, 0)
      INTO v_wallet_id, v_solde_total, v_solde_bonus
      FROM wallets
     WHERE user_id = v_retrait.transporteur_id;

    IF FOUND THEN
      v_retirable := v_solde_total - v_solde_bonus;

      -- Vérification : le montant doit rester dans la part retirable
      IF v_retrait.montant_fcfa > v_retirable THEN
        RAISE EXCEPTION 'Montant dépasse le solde retirable (retirable: % XAF, demandé: % XAF)',
          v_retirable, v_retrait.montant_fcfa;
      END IF;

      UPDATE wallets
      SET solde_fcfa = GREATEST(v_solde_bonus, solde_fcfa - v_retrait.montant_fcfa),
          updated_at = now()
      WHERE id = v_wallet_id;
    END IF;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION traiter_retrait_admin(uuid, text, text) TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. Vue pratique pour l'affichage côté app
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW wallets_avec_retirable AS
SELECT
  w.id,
  w.user_id,
  w.solde_fcfa                            AS solde_total,
  COALESCE(w.solde_bonus, 0)              AS solde_bonus,
  GREATEST(0, w.solde_fcfa - COALESCE(w.solde_bonus, 0)) AS solde_retirable,
  w.updated_at
FROM wallets w;

GRANT SELECT ON wallets_avec_retirable TO authenticated;
