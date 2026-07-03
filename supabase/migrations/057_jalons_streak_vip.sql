-- Migration 057 : Jalons surprise client + streak hebdomadaire + statut VIP
-- + Remplacement complet de liberer_sequestre_course avec toutes les nouvelles logiques :
--   • Commission 10% pendant 7j post-KYC (au lieu de 15%)
--   • Attribution jalons surprise à chaque palier (10/20/30/50/100 courses)
--   • Crédit streak hebdomadaire (100 XAF si 3e course de la semaine)
--   • Jalons actifs : remboursement partiel crédité au wallet client

-- ── 1. Table jalons_client ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jalons_client (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  jalon      INTEGER     NOT NULL,      -- 10, 20, 30, 50, 100
  type       TEXT        NOT NULL,      -- 'reduction_pct' | 'credit_wallet' | 'vip'
  valeur     INTEGER,                   -- pourcentage ou XAF selon type
  utilise    BOOLEAN     NOT NULL DEFAULT false,
  expire_le  TIMESTAMPTZ,               -- NULL pour type='vip' (permanent)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, jalon)               -- un seul jalon par palier
);

ALTER TABLE jalons_client ENABLE ROW LEVEL SECURITY;

CREATE POLICY "jalons_own" ON jalons_client
  FOR ALL USING (auth.uid() = user_id);

-- ── 2. Colonne VIP sur users ──────────────────────────────────────────────────
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_vip      BOOLEAN     DEFAULT false,
  ADD COLUMN IF NOT EXISTS vip_depuis  TIMESTAMPTZ;

-- ── 3. Fonction : attribuer jalons après une course ───────────────────────────
CREATE OR REPLACE FUNCTION attribuer_jalon_client(
  p_client_id  UUID,
  p_nb_courses INTEGER
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_jalon INTEGER;
  v_type  TEXT;
  v_val   INTEGER;
  v_exp   TIMESTAMPTZ;
BEGIN
  -- Chercher le palier franchi (10, 20, 30, 50, 100)
  v_jalon := CASE
    WHEN p_nb_courses = 10  THEN 10
    WHEN p_nb_courses = 20  THEN 20
    WHEN p_nb_courses = 30  THEN 30
    WHEN p_nb_courses = 50  THEN 50
    WHEN p_nb_courses = 100 THEN 100
    ELSE NULL
  END;

  IF v_jalon IS NULL THEN RETURN; END IF;

  -- Définir la récompense
  CASE v_jalon
    WHEN 10  THEN v_type := 'reduction_pct'; v_val := 20;    v_exp := NOW() + INTERVAL '30 days';
    WHEN 20  THEN v_type := 'reduction_pct'; v_val := 30;    v_exp := NOW() + INTERVAL '30 days';
    WHEN 30  THEN v_type := 'reduction_pct'; v_val := 50;    v_exp := NOW() + INTERVAL '30 days';
    WHEN 50  THEN v_type := 'credit_wallet'; v_val := 5000;  v_exp := NOW() + INTERVAL '30 days';
    WHEN 100 THEN v_type := 'vip';           v_val := NULL;  v_exp := NULL;
    ELSE RETURN;
  END CASE;

  -- Insérer le jalon (ignorer si déjà attribué)
  INSERT INTO jalons_client (user_id, jalon, type, valeur, expire_le)
    VALUES (p_client_id, v_jalon, v_type, v_val, v_exp)
    ON CONFLICT (user_id, jalon) DO NOTHING;

  -- VIP : mettre à jour la colonne users
  IF v_jalon = 100 THEN
    UPDATE users
       SET is_vip = true, vip_depuis = NOW()
     WHERE id = p_client_id AND is_vip IS NOT TRUE;
  END IF;
END;
$$;

-- ── 4. Fonction : vérifier streak hebdomadaire (3 courses → 100 XAF) ─────────
CREATE OR REPLACE FUNCTION verifier_streak_client(p_client_id UUID)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_nb_semaine INTEGER;
  v_montant    INTEGER;
  v_wallet_id  UUID;
BEGIN
  SELECT COALESCE(
    (SELECT valeur::INTEGER FROM configurations_systeme WHERE cle = 'streak_client_xaf' LIMIT 1),
    100
  ) INTO v_montant;

  SELECT COUNT(*) INTO v_nb_semaine
    FROM courses
   WHERE client_id = p_client_id
     AND statut    = 'terminee'
     AND date_trunc('week', COALESCE(completed_at, updated_at)) =
         date_trunc('week', NOW());

  -- Déclencher uniquement à la 3e course exacte de la semaine
  IF v_nb_semaine = 3 THEN
    INSERT INTO wallets (user_id, solde_fcfa)
      VALUES (p_client_id, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_client_id;
    UPDATE wallets
       SET solde_fcfa = solde_fcfa + v_montant, updated_at = NOW()
     WHERE id = v_wallet_id;
    INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_id, 'streak_hebdo', v_montant, 'validee', 'streak_' || p_client_id::text);
  END IF;
END;
$$;

-- ── 5. Fonction : appliquer un jalon actif (crédit wallet client) ────────────
-- Appelée dans liberer_sequestre_course si le client a un jalon non utilisé.
CREATE OR REPLACE FUNCTION appliquer_jalon_client(
  p_client_id  UUID,
  p_montant    INTEGER,        -- prix_fcfa de la course
  p_course_id  UUID
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_jalon      RECORD;
  v_credit     INTEGER;
  v_wallet_id  UUID;
BEGIN
  -- Chercher le premier jalon actif non expiré (excluant VIP qui n'a pas de valeur financière)
  SELECT * INTO v_jalon
    FROM jalons_client
   WHERE user_id  = p_client_id
     AND utilise  = false
     AND type    != 'vip'
     AND (expire_le IS NULL OR expire_le > NOW())
   ORDER BY created_at ASC
   LIMIT 1;

  IF NOT FOUND THEN RETURN; END IF;

  -- Calculer le crédit
  IF v_jalon.type = 'reduction_pct' THEN
    v_credit := ROUND(p_montant * v_jalon.valeur::NUMERIC / 100);
  ELSIF v_jalon.type = 'credit_wallet' THEN
    v_credit := v_jalon.valeur;
  ELSE
    RETURN;
  END IF;

  -- Créditer le wallet client
  INSERT INTO wallets (user_id, solde_fcfa)
    VALUES (p_client_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_client_id;
  UPDATE wallets
     SET solde_fcfa = solde_fcfa + v_credit, updated_at = NOW()
   WHERE id = v_wallet_id;
  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_id, 'jalon_fidelite', v_credit, 'validee', p_course_id::text);

  -- Marquer le jalon comme utilisé
  UPDATE jalons_client SET utilise = true WHERE id = v_jalon.id;
END;
$$;

-- ── 6. liberer_sequestre_course — version complète avec toutes les logiques ───
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
  v_commission_taux      NUMERIC;
  v_pct_parrainage       NUMERIC;
  v_parrain_client       UUID;
  v_parrain_transporteur UUID;
  v_wallet_parrain       UUID;
  v_comm_parrain         INT;
  v_kyc_approuve_le      TIMESTAMPTZ;
  v_kyc_duree_j          INTEGER;
  v_nb_courses           INTEGER;
BEGIN

  -- ── Récupérer UNIQUEMENT les paiements confirmés par Moneroo (sequestre) ────
  SELECT id, montant_fcfa
    INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id
     AND statut    = 'sequestre'
   ORDER BY created_at DESC
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  -- ── Récupérer client et transporteur ────────────────────────────────────────
  SELECT client_id, transporteur_id
    INTO v_client_id, v_transporteur_id
    FROM courses WHERE id = p_course_id;

  IF v_transporteur_id IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- ── Taux commission : 10% pendant 7j post-KYC, sinon 15% ───────────────────
  SELECT COALESCE(
    (SELECT valeur::INTEGER FROM configurations_systeme WHERE cle = 'kyc_commission_duree_j' LIMIT 1),
    7
  ) INTO v_kyc_duree_j;

  SELECT approuve_le INTO v_kyc_approuve_le
    FROM transporteurs_kyc
   WHERE user_id    = v_transporteur_id
     AND statut_kyc = 'approuve'
   LIMIT 1;

  IF v_kyc_approuve_le IS NOT NULL
     AND v_kyc_approuve_le > NOW() - (v_kyc_duree_j || ' days')::INTERVAL THEN
    -- TR approuvé récemment → commission réduite
    SELECT COALESCE(
      (SELECT valeur::NUMERIC FROM configurations_systeme WHERE cle = 'kyc_commission_taux' LIMIT 1),
      0.10
    ) INTO v_commission_taux;
  ELSE
    v_commission_taux := 0.15;
  END IF;

  v_commission := ROUND(v_montant * v_commission_taux);
  v_net        := v_montant - v_commission;

  -- ── Crédit transporteur ─────────────────────────────────────────────────────
  INSERT INTO wallets (user_id, solde_fcfa)
    VALUES (v_transporteur_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_tr FROM wallets WHERE user_id = v_transporteur_id;
  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW()
   WHERE id = v_wallet_tr;
  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  -- ── Libérer le paiement ──────────────────────────────────────────────────────
  UPDATE paiements SET statut = 'libere', libere_at = NOW()
   WHERE id = v_paiement_id;
  UPDATE courses SET statut_paiement = 'libere', updated_at = NOW()
   WHERE id = p_course_id;

  -- ── Parrainage (prélevé sur commission CAARCO) ───────────────────────────────
  SELECT COALESCE(
    (SELECT valeur::NUMERIC FROM parametres WHERE cle = 'taux_commission_parrainage' LIMIT 1),
    0.10
  ) INTO v_pct_parrainage;

  SELECT parrain_id INTO v_parrain_client
    FROM users WHERE id = v_client_id AND parrain_id IS NOT NULL;
  IF v_parrain_client IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets (user_id, solde_fcfa) VALUES (v_parrain_client, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_client;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW() WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  SELECT parrain_id INTO v_parrain_transporteur
    FROM users WHERE id = v_transporteur_id AND parrain_id IS NOT NULL;
  IF v_parrain_transporteur IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets (user_id, solde_fcfa) VALUES (v_parrain_transporteur, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_transporteur;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW() WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  -- ── Jalons surprise client ───────────────────────────────────────────────────
  SELECT nombre_courses INTO v_nb_courses FROM users WHERE id = v_client_id;
  PERFORM attribuer_jalon_client(v_client_id, COALESCE(v_nb_courses, 0));

  -- ── Appliquer jalon actif (remboursement partiel) ────────────────────────────
  PERFORM appliquer_jalon_client(v_client_id, v_montant, p_course_id);

  -- ── Streak hebdomadaire client ───────────────────────────────────────────────
  PERFORM verifier_streak_client(v_client_id);

  RETURN jsonb_build_object(
    'ok',               true,
    'paiement_id',      v_paiement_id,
    'net_tr',           v_net,
    'commission',       v_commission,
    'commission_taux',  v_commission_taux,
    'nb_courses_client', v_nb_courses
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO service_role;
