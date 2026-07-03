-- ============================================================
-- Migration 033 — Sécurisation du paiement wallet
-- ============================================================
-- Problèmes corrigés :
--   A. Commission CAARCO 15% manquante (transporteur prenait 100%)
--   B. statut = 'livree' invalide → violation contrainte → état incohérent
--   C. Non-atomicité de payerAvecWallet (insert validee avant vérif solde)
--   D. Parrainage ignoré sur les paiements wallet
-- ============================================================


-- ── 0. COLONNES MANQUANTES SUR paiements ────────────────────────────────────
ALTER TABLE paiements
  ADD COLUMN IF NOT EXISTS commission_fcfa    INTEGER,
  ADD COLUMN IF NOT EXISTS net_transporteur   INTEGER,
  ADD COLUMN IF NOT EXISTS libere_at          TIMESTAMPTZ;


-- ── 1. REMPLACER process_ride_payment ───────────────────────────────────────
-- DROP nécessaire car l'ancienne version avait un ordre de paramètres différent
DROP FUNCTION IF EXISTS process_ride_payment(uuid, uuid, uuid);

CREATE OR REPLACE FUNCTION process_ride_payment(
  p_client_id uuid,
  p_tr_id     uuid,
  p_ride_id   uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_montant             int;
  v_client_wallet_id    uuid;
  v_tr_wallet_id        uuid;
  v_solde_client        int;
  v_net                 int;
  v_commission          int;
  v_reference           text;
  v_pct_parrainage      numeric;
  v_parrain_client      uuid;
  v_parrain_tr          uuid;
  v_wallet_parrain      uuid;
  v_comm_parrain        int;
BEGIN

  -- ── Vérifications d'identité ────────────────────────────────────────────
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'non_authentifie';
  END IF;
  IF auth.uid() != p_client_id THEN
    RAISE EXCEPTION 'identite_invalide';
  END IF;

  -- ── Récupérer le montant DEPUIS LA BASE (jamais du client) ──────────────
  SELECT prix_fcfa INTO v_montant
    FROM courses
   WHERE id = p_ride_id
     AND client_id = p_client_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'course_introuvable';
  END IF;
  IF v_montant IS NULL OR v_montant <= 0 THEN
    RAISE EXCEPTION 'montant_invalide';
  END IF;

  -- ── Wallet client : existence + solde suffisant (atomique) ──────────────
  SELECT id, solde_fcfa
    INTO v_client_wallet_id, v_solde_client
    FROM wallets
   WHERE user_id = p_client_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'wallet_client_introuvable — rechargez votre portefeuille';
  END IF;

  IF v_solde_client < v_montant THEN
    RAISE EXCEPTION 'fonds_insuffisants — solde : % XAF, requis : % XAF',
      v_solde_client, v_montant;
  END IF;

  -- ── Calcul commission CAARCO (15%) et net transporteur (85%) ────────────
  v_commission := ROUND(v_montant * 0.15);
  v_net        := v_montant - v_commission;

  v_reference := 'WAL-' || UPPER(SUBSTRING(p_ride_id::text FROM 1 FOR 8));

  -- ── Wallet transporteur (créé automatiquement si absent) ────────────────
  INSERT INTO wallets(user_id, solde_fcfa)
    VALUES (p_tr_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_tr_wallet_id
    FROM wallets
   WHERE user_id = p_tr_id;

  -- ── Débit client (montant total) ─────────────────────────────────────────
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - v_montant,
         updated_at = now()
   WHERE id = v_client_wallet_id;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_client_wallet_id, 'paiement', v_montant, 'validee', v_reference);

  -- ── Crédit transporteur (85% du montant) ────────────────────────────────
  UPDATE wallets
     SET solde_fcfa = solde_fcfa + v_net,
         updated_at = now()
   WHERE id = v_tr_wallet_id;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_tr_wallet_id, 'recette', v_net, 'validee', v_reference);

  -- ── Mise à jour de la course ─────────────────────────────────────────────
  UPDATE courses
     SET statut          = 'terminee',
         statut_paiement = 'paye',
         updated_at      = now()
   WHERE id = p_ride_id;

  -- ── Enregistrement dans paiements ───────────────────────────────────────
  INSERT INTO paiements(
    course_id, montant_fcfa,
    commission_fcfa, net_transporteur,
    methode, statut, ref_transaction, libere_at
  )
  VALUES (
    p_ride_id, v_montant,
    v_commission, v_net,
    'wallet', 'libere', v_reference, now()
  )
  ON CONFLICT DO NOTHING;

  -- ── Parrainage : taux fixe 10% ───────────────────────────────────────────
  v_pct_parrainage := 0.10;

  -- Parrain du CLIENT
  SELECT parrain_id INTO v_parrain_client
    FROM users WHERE id = p_client_id;

  IF v_parrain_client IS NOT NULL THEN
    v_comm_parrain := GREATEST(1, ROUND(v_commission::numeric * v_pct_parrainage));

    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_client, 0)
      ON CONFLICT (user_id) DO NOTHING;

    SELECT id INTO v_wallet_parrain
      FROM wallets WHERE user_id = v_parrain_client;

    UPDATE wallets
       SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = now()
     WHERE id = v_wallet_parrain;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'recette', v_comm_parrain, 'validee', v_reference);

    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parrain_client, p_client_id, p_ride_id, v_comm_parrain);
  END IF;

  -- Parrain du TRANSPORTEUR (si différent du parrain client)
  SELECT parrain_id INTO v_parrain_tr
    FROM users WHERE id = p_tr_id;

  IF v_parrain_tr IS NOT NULL
     AND v_parrain_tr IS DISTINCT FROM v_parrain_client THEN

    v_comm_parrain := GREATEST(1, ROUND(v_commission::numeric * v_pct_parrainage));

    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_tr, 0)
      ON CONFLICT (user_id) DO NOTHING;

    SELECT id INTO v_wallet_parrain
      FROM wallets WHERE user_id = v_parrain_tr;

    UPDATE wallets
       SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = now()
     WHERE id = v_wallet_parrain;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'recette', v_comm_parrain, 'validee', v_reference);

    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parrain_tr, p_tr_id, p_ride_id, v_comm_parrain);
  END IF;

  RETURN jsonb_build_object(
    'reference',        v_reference,
    'montant',          v_montant,
    'net_transporteur', v_net,
    'commission',       v_commission
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_ride_payment(uuid, uuid, uuid) TO authenticated;


-- ── 2. REMPLACER payerAvecWallet par une version atomique ───────────────────
-- Ancienne : INSERT validee PUIS debiter → incohérence si débit échoue
-- Nouvelle : tout en une seule transaction atomique
CREATE OR REPLACE FUNCTION payer_avec_wallet_atomique(
  p_wallet_id uuid,
  p_montant   int,
  p_reference text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_solde int;
  v_uid   uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'non_authentifie';
  END IF;
  IF p_montant <= 0 THEN
    RAISE EXCEPTION 'montant_invalide';
  END IF;

  -- Vérifier solde ET débiter en une seule opération atomique
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - p_montant,
         updated_at = now()
   WHERE id        = p_wallet_id
     AND user_id   = v_uid
     AND solde_fcfa >= p_montant;

  IF NOT FOUND THEN
    -- Distinguer "wallet introuvable" de "solde insuffisant"
    SELECT solde_fcfa INTO v_solde
      FROM wallets
     WHERE id = p_wallet_id AND user_id = v_uid;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'wallet_introuvable';
    ELSE
      RAISE EXCEPTION 'fonds_insuffisants — solde : % XAF, requis : % XAF',
        v_solde, p_montant;
    END IF;
  END IF;

  -- Enregistrer la transaction UNIQUEMENT si le débit a réussi
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (p_wallet_id, 'paiement', p_montant, 'validee', p_reference);
END;
$$;

GRANT EXECUTE ON FUNCTION payer_avec_wallet_atomique(uuid, int, text) TO authenticated;


-- ── 3. CONTRAINTE CHECK sur wallets.solde_fcfa ──────────────────────────────
-- Garde-fou final : le solde ne peut jamais devenir négatif
-- (même en cas de bug dans une future fonction)
ALTER TABLE wallets
  DROP CONSTRAINT IF EXISTS wallets_solde_positif;

ALTER TABLE wallets
  ADD CONSTRAINT wallets_solde_positif
  CHECK (solde_fcfa >= 0);
