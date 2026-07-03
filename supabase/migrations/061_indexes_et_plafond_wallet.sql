-- Migration 061 — Index de performance + plafond montant wallet
-- Date : 2026-05-29

-- ── 1. Index de performance ───────────────────────────────────────────────────
-- Ces colonnes sont filtrées à chaque requête RLS et en liste admin.
-- Sans index, PostgreSQL fait un sequential scan sur chaque appel.

CREATE INDEX IF NOT EXISTS idx_courses_statut
  ON courses(statut);

CREATE INDEX IF NOT EXISTS idx_courses_client_id
  ON courses(client_id);

CREATE INDEX IF NOT EXISTS idx_courses_transporteur_id
  ON courses(transporteur_id);

CREATE INDEX IF NOT EXISTS idx_courses_created_at
  ON courses(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_role
  ON users(role);

CREATE INDEX IF NOT EXISTS idx_users_statut_connexion
  ON users(statut_connexion);

CREATE INDEX IF NOT EXISTS idx_paiements_moneroo_id
  ON paiements(moneroo_payment_id);

CREATE INDEX IF NOT EXISTS idx_transactions_wallet_statut
  ON transactions_wallet(statut);

CREATE INDEX IF NOT EXISTS idx_positions_gps_user_course
  ON positions_gps(user_id, course_id, created_at DESC);

-- ── 2. Plafond montant sur payer_course_wallet ────────────────────────────────
-- Le RPC vérifie p_montant > 0 mais pas de borne supérieure.
-- Plafond : 5 000 000 XAF (largement au-dessus du prix max d'une course CAARCO).

CREATE OR REPLACE FUNCTION payer_course_wallet(
  p_destinataire_id uuid,
  p_montant         int,
  p_reference       text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_payeur_id    uuid := auth.uid();
  v_wallet_payeur uuid;
  v_solde        int;
BEGIN
  IF v_payeur_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;

  IF p_montant <= 0 THEN
    RAISE EXCEPTION 'Montant invalide : doit être > 0';
  END IF;

  -- Plafond anti-abus : 5 000 000 XAF max par transaction
  IF p_montant > 5000000 THEN
    RAISE EXCEPTION 'Montant maximum dépassé : 5 000 000 XAF';
  END IF;

  -- Ne pas se payer soi-même
  IF v_payeur_id = p_destinataire_id THEN
    RAISE EXCEPTION 'Impossible de se payer soi-même';
  END IF;

  SELECT id, solde_fcfa INTO v_wallet_payeur, v_solde
    FROM wallets
   WHERE user_id = v_payeur_id
   LIMIT 1;

  IF v_wallet_payeur IS NULL THEN
    RAISE EXCEPTION 'Portefeuille introuvable — rechargez d''abord votre wallet';
  END IF;

  IF v_solde < p_montant THEN
    RAISE EXCEPTION 'Solde insuffisant (disponible : % XAF)', v_solde;
  END IF;

  -- Débit payeur + Crédit receveur (atomique)
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - p_montant, updated_at = now()
   WHERE id = v_wallet_payeur;

  UPDATE wallets
     SET solde_fcfa = solde_fcfa + p_montant, updated_at = now()
   WHERE user_id = p_destinataire_id;

  -- Journal des transactions
  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wallet_payeur, 'debit', p_montant, p_reference, 'complete');

  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, reference, statut)
    SELECT id, 'credit', p_montant, p_reference, 'complete'
      FROM wallets WHERE user_id = p_destinataire_id;

END;
$$;
