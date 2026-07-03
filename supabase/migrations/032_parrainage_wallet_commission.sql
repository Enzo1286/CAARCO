-- ============================================================
-- Migration 032 — Système de parrainage : commission wallet
-- ============================================================
-- Ce que fait cette migration :
--   1. Table configurations_systeme (clé/valeur admin)
--   2. Table commissions_parrainage  (historique des versements)
--   3. Étendre le CHECK type de transactions_wallet
--   4. Mettre à jour liberer_sequestre_course (greffe parrainage)
--   5. RPC get_stats_parrainage (noms anonymisés, SECURITY DEFINER)
-- ============================================================


-- ── 1. TABLE configurations_systeme ─────────────────────────────────────────
-- Table clé/valeur générale pour les paramètres modifiables par l'admin.
CREATE TABLE IF NOT EXISTS configurations_systeme (
  cle         TEXT PRIMARY KEY,
  valeur      TEXT NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_by  UUID REFERENCES users(id)
);

-- Valeur par défaut : 10% de la part CAARCO versés au parrain
INSERT INTO configurations_systeme (cle, valeur, description) VALUES
  (
    'commission_parrainage_pct',
    '0.10',
    'Part de la commission CAARCO (15%) reversée au parrain à chaque course terminée. Ex: 0.10 = 10% × 15% du prix = 1.5% du total.'
  )
ON CONFLICT (cle) DO NOTHING;

-- RLS : lecture par tout utilisateur authentifié, écriture admin seulement
ALTER TABLE configurations_systeme ENABLE ROW LEVEL SECURITY;

CREATE POLICY "config_lecture_authenticated" ON configurations_systeme
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "config_admin_ecriture" ON configurations_systeme
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());


-- ── 2. TABLE commissions_parrainage ─────────────────────────────────────────
-- Enregistre chaque versement de commission au parrain.
-- Permet d'auditer l'historique et de calculer les stats.
CREATE TABLE IF NOT EXISTS commissions_parrainage (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parrain_id   UUID NOT NULL REFERENCES users(id),
  filleul_id   UUID NOT NULL REFERENCES users(id),
  course_id    UUID NOT NULL REFERENCES courses(id),
  montant_fcfa INT  NOT NULL CHECK (montant_fcfa > 0),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les requêtes fréquentes (stats parrain, audit)
CREATE INDEX IF NOT EXISTS idx_commissions_parrain   ON commissions_parrainage(parrain_id);
CREATE INDEX IF NOT EXISTS idx_commissions_filleul   ON commissions_parrainage(filleul_id);
CREATE INDEX IF NOT EXISTS idx_commissions_course    ON commissions_parrainage(course_id);

-- RLS : un parrain voit uniquement ses propres commissions
ALTER TABLE commissions_parrainage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "commissions_lecture_parrain" ON commissions_parrainage
  FOR SELECT USING (parrain_id = auth.uid());

CREATE POLICY "commissions_admin_select" ON commissions_parrainage
  FOR SELECT USING (is_admin());

-- Les INSERTs sont faits exclusivement par liberer_sequestre_course (SECURITY DEFINER)
-- Pas de politique INSERT pour les utilisateurs normaux.


-- ── 3. ÉTENDRE LE CHECK TYPE SUR transactions_wallet ────────────────────────
-- Migration 008 limitait à ('recharge','paiement','remboursement').
-- Migration 021 utilise déjà 'recette'. On ajoute 'parrainage' proprement.
ALTER TABLE transactions_wallet
  DROP CONSTRAINT IF EXISTS transactions_wallet_type_check;

ALTER TABLE transactions_wallet
  ADD CONSTRAINT transactions_wallet_type_check
  CHECK (type IN ('recharge', 'paiement', 'remboursement', 'recette', 'parrainage'));


-- ── 4. METTRE À JOUR liberer_sequestre_course ────────────────────────────────
-- On greffe la logique parrainage APRÈS le crédit du transporteur.
-- Le montant parrainage est prélevé sur la commission CAARCO (pas sur le net transporteur).
CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_paiement_id         UUID;
  v_montant             INT;
  v_client_id           UUID;
  v_transporteur_id     UUID;
  v_wallet_tr           UUID;
  v_net                 INT;
  v_commission          INT;   -- 15% du total = part CAARCO brute
  v_pct_parrainage      NUMERIC;
  v_parrain_client      UUID;
  v_parrain_transporteur UUID;
  v_wallet_parrain      UUID;
  v_comm_parrain        INT;
BEGIN

  -- ── Récupérer le paiement en séquestre ──────────────────────────────────
  SELECT id, montant_fcfa
    INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id
     AND statut IN ('sequestre', 'initie')
   ORDER BY created_at DESC
   LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_mobile_payment');
  END IF;

  -- ── Récupérer client et transporteur ────────────────────────────────────
  SELECT client_id, transporteur_id
    INTO v_client_id, v_transporteur_id
    FROM courses
   WHERE id = p_course_id;

  IF v_transporteur_id IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- ── Calcul commission CAARCO (15%) et net transporteur (85%) ────────────
  v_commission := ROUND(v_montant * 0.15);
  v_net        := v_montant - v_commission;

  -- ── Crédit transporteur (identique à l'ancienne logique) ────────────────
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

  -- ── Libérer le paiement ──────────────────────────────────────────────────
  UPDATE paiements
     SET statut    = 'libere',
         libere_at = NOW()
   WHERE id = v_paiement_id;

  UPDATE courses
     SET statut_paiement = 'libere',
         updated_at      = NOW()
   WHERE id = p_course_id;

  -- ── Lire le taux de commission parrainage ───────────────────────────────
  SELECT valeur::NUMERIC
    INTO v_pct_parrainage
    FROM configurations_systeme
   WHERE cle = 'commission_parrainage_pct';

  -- Valeur de sécurité si la config est absente
  v_pct_parrainage := COALESCE(v_pct_parrainage, 0.10);

  -- ── Parrain du CLIENT ────────────────────────────────────────────────────
  SELECT parrain_id INTO v_parrain_client
    FROM users WHERE id = v_client_id;

  IF v_parrain_client IS NOT NULL THEN
    -- commission = taux × part CAARCO, minimum 1 FCFA
    v_comm_parrain := GREATEST(1, ROUND(v_commission::NUMERIC * v_pct_parrainage));

    -- Créer le wallet du parrain si absent
    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_client, 0)
      ON CONFLICT (user_id) DO NOTHING;

    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_client;

    -- Créditer
    UPDATE wallets
       SET solde_fcfa = solde_fcfa + v_comm_parrain,
           updated_at = NOW()
     WHERE id = v_wallet_parrain;

    -- Historique wallet
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);

    -- Audit commissions_parrainage
    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parrain_client, v_client_id, p_course_id, v_comm_parrain);
  END IF;

  -- ── Parrain du TRANSPORTEUR ──────────────────────────────────────────────
  SELECT parrain_id INTO v_parrain_transporteur
    FROM users WHERE id = v_transporteur_id;

  -- Ne pas doublonner si le parrain du transporteur est le même que celui du client
  IF v_parrain_transporteur IS NOT NULL
     AND v_parrain_transporteur IS DISTINCT FROM v_parrain_client THEN

    v_comm_parrain := GREATEST(1, ROUND(v_commission::NUMERIC * v_pct_parrainage));

    INSERT INTO wallets(user_id, solde_fcfa)
      VALUES (v_parrain_transporteur, 0)
      ON CONFLICT (user_id) DO NOTHING;

    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_transporteur;

    UPDATE wallets
       SET solde_fcfa = solde_fcfa + v_comm_parrain,
           updated_at = NOW()
     WHERE id = v_wallet_parrain;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);

    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parrain_transporteur, v_transporteur_id, p_course_id, v_comm_parrain);
  END IF;

  RETURN jsonb_build_object(
    'success',          true,
    'net_transporteur', v_net,
    'commission',       v_commission,
    'montant_total',    v_montant
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO service_role;


-- ── 5. RPC get_stats_parrainage ─────────────────────────────────────────────
-- Retourne les stats de parrainage de l'utilisateur connecté :
--   - total_commissions : somme des FCFA gagnés grâce au parrainage
--   - nombre_filleuls   : nombre de filleuls distincts ayant généré une commission
--   - filleuls          : liste [{nom_anonymise, gains_fcfa}]
-- Les noms sont anonymisés en SQL : "Jean D." (prénom + initiale)
CREATE OR REPLACE FUNCTION get_stats_parrainage()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_commissions', COALESCE(SUM(cp.montant_fcfa), 0),
    'nombre_filleuls',   COUNT(DISTINCT cp.filleul_id),
    'filleuls', (
      SELECT COALESCE(jsonb_agg(row_data ORDER BY gains_fcfa DESC), '[]'::jsonb)
      FROM (
        SELECT
          -- Anonymisation : "Prénom I."
          CASE
            WHEN SPLIT_PART(u.nom, ' ', 2) = ''
            THEN u.nom
            ELSE SPLIT_PART(u.nom, ' ', 1)
                 || ' '
                 || UPPER(LEFT(SPLIT_PART(u.nom, ' ', 2), 1))
                 || '.'
          END                      AS nom_anonymise,
          SUM(cp2.montant_fcfa)    AS gains_fcfa
        FROM commissions_parrainage cp2
        JOIN users u ON u.id = cp2.filleul_id
        WHERE cp2.parrain_id = v_uid
        GROUP BY u.id, u.nom
      ) AS row_data
    )
  )
  INTO v_result
  FROM commissions_parrainage cp
  WHERE cp.parrain_id = v_uid;

  RETURN COALESCE(
    v_result,
    jsonb_build_object('total_commissions', 0, 'nombre_filleuls', 0, 'filleuls', '[]'::jsonb)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_stats_parrainage() TO authenticated;
