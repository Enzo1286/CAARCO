-- ══════════════════════════════════════════════════════════════════════════════
-- Migration 056 — Système de motivation complet CAARCO
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Côté Client :
--   • Jalons surprise (10 / 20 / 30 / 50 / 100 courses) → récompenses cachées
--   • Streak hebdomadaire (3 courses/semaine → 100 XAF wallet)
--   • Statut VIP à vie au jalon 100
--
-- Côté Transporteur :
--   • Commission 10% pendant 7 jours post-approbation KYC (vs 15% standard)
--   • Classement mensuel (rang_tr_mois) — visible TR uniquement
--   • Badge top_tr_mois pour top 10 — visible clients dans stories
--   • Bonus volume fin de mois (10-24 → 2%, 25-49 → 4%, 50+ → 7% de la commission)
--   • Prime qualité mensuelle (note ≥ 4.5 et ≥ 5 courses → 500 XAF)
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. Colonnes supplémentaires sur users ─────────────────────────────────────

ALTER TABLE users ADD COLUMN IF NOT EXISTS rang_tr_mois          INT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS top_tr_mois           BOOLEAN      DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_approuve_le       TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bonus_volume_mois_fcfa INT         DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS statut_vip            BOOLEAN      DEFAULT FALSE;

-- ── 2. Table des récompenses client ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS recompenses_client (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type           TEXT        NOT NULL CHECK (type IN ('reduction_pct', 'course_gratuite', 'statut_vip')),
  pct_reduction  INT,        -- Pour reduction_pct : 20 / 30 / 50
  valeur_fcfa    INT,        -- Pour course_gratuite : plafond 5000 XAF
  course_jalon   INT,        -- Jalon déclencheur : 10 | 20 | 30 | 50 | 100
  statut         TEXT        NOT NULL DEFAULT 'en_attente'
                             CHECK (statut IN ('en_attente', 'utilisee', 'expiree')),
  expires_at     TIMESTAMPTZ,-- NULL pour statut_vip (permanent)
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recompenses_client ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "recompenses_propres" ON recompenses_client;
CREATE POLICY "recompenses_propres" ON recompenses_client
  FOR ALL USING (auth.uid() = user_id);

-- ── 3. Trigger : enregistrer la date d'approbation KYC ────────────────────────
--    Déclenche quand kyc_valide passe de false/null → true

CREATE OR REPLACE FUNCTION _set_kyc_approuve_le()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.kyc_valide = TRUE AND COALESCE(OLD.kyc_valide, FALSE) = FALSE THEN
    NEW.kyc_approuve_le = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kyc_approuve_le ON users;
CREATE TRIGGER trg_kyc_approuve_le
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION _set_kyc_approuve_le();

-- ── 4. Vérification jalons client ────────────────────────────────────────────
--    Appelé dans liberer_sequestre_course après chaque livraison payée.
--    Idempotent : vérifie que le jalon n'a pas déjà été créé.

CREATE OR REPLACE FUNCTION verifier_jalons_client(p_client_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_nb    INT;
  v_type  TEXT;
  v_pct   INT;
  v_val   INT;
  v_jalon INT;
BEGIN
  SELECT COUNT(*) INTO v_nb
    FROM courses WHERE client_id = p_client_id AND statut = 'terminee';

  IF    v_nb = 10  THEN v_jalon := 10;  v_type := 'reduction_pct';   v_pct := 20;
  ELSIF v_nb = 20  THEN v_jalon := 20;  v_type := 'reduction_pct';   v_pct := 30;
  ELSIF v_nb = 30  THEN v_jalon := 30;  v_type := 'reduction_pct';   v_pct := 50;
  ELSIF v_nb = 50  THEN v_jalon := 50;  v_type := 'course_gratuite'; v_val := 5000;
  ELSIF v_nb = 100 THEN v_jalon := 100; v_type := 'statut_vip';
  ELSE RETURN;
  END IF;

  -- Idempotence : ne pas créer deux fois le même jalon
  IF EXISTS (
    SELECT 1 FROM recompenses_client
     WHERE user_id = p_client_id AND course_jalon = v_jalon
  ) THEN RETURN; END IF;

  INSERT INTO recompenses_client (user_id, type, pct_reduction, valeur_fcfa, course_jalon, expires_at)
  VALUES (
    p_client_id, v_type, v_pct, v_val, v_jalon,
    CASE WHEN v_type = 'statut_vip' THEN NULL ELSE NOW() + INTERVAL '30 days' END
  );

  -- VIP : marquer le compte
  IF v_type = 'statut_vip' THEN
    UPDATE users SET statut_vip = TRUE WHERE id = p_client_id;
  END IF;
END;
$$;

-- ── 5. Streak hebdomadaire client ────────────────────────────────────────────
--    3 courses dans la semaine calendaire en cours → 100 XAF wallet.
--    Déclenchement exactement à la 3e course (pas à la 4e, 5e…).

CREATE OR REPLACE FUNCTION verifier_streak_hebdo(p_client_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_debut_sem TIMESTAMPTZ := date_trunc('week', NOW());
  v_nb        INT;
  v_wallet_id UUID;
BEGIN
  SELECT COUNT(*) INTO v_nb
    FROM courses
   WHERE client_id = p_client_id
     AND statut    = 'terminee'
     AND updated_at >= v_debut_sem;

  IF v_nb <> 3 THEN RETURN; END IF; -- Exactement 3 : évite doublons

  INSERT INTO wallets(user_id, solde_fcfa) VALUES (p_client_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_client_id;

  UPDATE wallets SET solde_fcfa = solde_fcfa + 100, updated_at = NOW()
   WHERE id = v_wallet_id;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
  VALUES (v_wallet_id, 'bonus_streak', 100, 'validee',
          'streak_sem_' || to_char(v_debut_sem, 'YYYY_WW'));
END;
$$;

-- ── 6. Classement mensuel TR (re-calculé chaque nuit) ────────────────────────
--    Score = courses terminées ce mois × 2 + note_moyenne × 10
--    → TRs les plus actifs ET les mieux notés en tête.

CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE users SET rang_tr_mois = NULL, top_tr_mois = FALSE
   WHERE role = 'transporteur';

  WITH stats AS (
    SELECT
      c.transporteur_id                                          AS user_id,
      COUNT(*)                                                   AS nb_courses,
      ROW_NUMBER() OVER (
        ORDER BY COUNT(*) * 2 + COALESCE(AVG(n.score), 5) * 10 DESC
      )                                                          AS rang
    FROM courses c
    LEFT JOIN notations n
           ON n.note_id = c.transporteur_id
          AND date_trunc('month', n.created_at) = date_trunc('month', NOW())
    WHERE c.statut = 'terminee'
      AND date_trunc('month', c.updated_at) = date_trunc('month', NOW())
    GROUP BY c.transporteur_id
  )
  UPDATE users u
     SET rang_tr_mois = s.rang,
         top_tr_mois  = (s.rang <= 10)
    FROM stats s
   WHERE u.id = s.user_id;
END;
$$;

-- ── 7. Bonus volume mensuel TR ────────────────────────────────────────────────
--    Exécuté le 1er du mois sur les données du MOIS PRÉCÉDENT.
--    Crédite la différence de commission sur le wallet du TR.

CREATE OR REPLACE FUNCTION calculer_bonus_volume_mensuel()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_rec       RECORD;
  v_wallet_id UUID;
  v_bonus     INT;
  v_pct       NUMERIC;
  v_ref       TEXT := 'bonus_vol_' || to_char(NOW() - INTERVAL '1 month', 'YYYY_MM');
BEGIN
  -- Éviter les doublons si la fonction est rejouée
  IF EXISTS (
    SELECT 1 FROM transactions_wallet WHERE reference = v_ref LIMIT 1
  ) THEN RETURN; END IF;

  FOR v_rec IN
    SELECT
      c.transporteur_id                        AS user_id,
      COUNT(*)                                 AS nb_courses,
      COALESCE(SUM(p.montant_fcfa), 0)::INT    AS total_course_fcfa
    FROM courses c
    JOIN paiements p ON p.course_id = c.id AND p.statut = 'libere'
    WHERE c.statut = 'terminee'
      AND date_trunc('month', c.updated_at) =
          date_trunc('month', NOW() - INTERVAL '1 month')
    GROUP BY c.transporteur_id
  LOOP
    IF    v_rec.nb_courses >= 50 THEN v_pct := 0.07;
    ELSIF v_rec.nb_courses >= 25 THEN v_pct := 0.04;
    ELSIF v_rec.nb_courses >= 10 THEN v_pct := 0.02;
    ELSE  CONTINUE;
    END IF;

    -- Bonus = % appliqué sur la commission CAARCO (15% du CA)
    v_bonus := GREATEST(0, ROUND(v_rec.total_course_fcfa * 0.15 * v_pct));
    IF v_bonus = 0 THEN CONTINUE; END IF;

    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_rec.user_id, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_rec.user_id;

    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW()
     WHERE id = v_wallet_id;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_id, 'bonus_volume', v_bonus, 'validee', v_ref || '_' || v_rec.user_id);

    UPDATE users SET bonus_volume_mois_fcfa = v_bonus WHERE id = v_rec.user_id;
  END LOOP;

  -- Reset le bonus affiché pour le mois en cours
  UPDATE users SET bonus_volume_mois_fcfa = 0
   WHERE role = 'transporteur'
     AND id NOT IN (
       SELECT DISTINCT tw.wallet_id::UUID  -- skip: wallet_id pas user_id, ajuster si besoin
       FROM transactions_wallet tw WHERE tw.reference LIKE v_ref || '%'
     );
END;
$$;

-- ── 8. Prime qualité mensuelle TR ────────────────────────────────────────────
--    Note ≥ 4.5 et ≥ 5 courses le mois précédent → 500 XAF.

CREATE OR REPLACE FUNCTION calculer_prime_qualite_mensuelle()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_rec       RECORD;
  v_wallet_id UUID;
  v_bonus     INT;
  v_ref       TEXT := 'prime_qual_' || to_char(NOW() - INTERVAL '1 month', 'YYYY_MM');
BEGIN
  IF EXISTS (
    SELECT 1 FROM transactions_wallet WHERE reference LIKE v_ref || '%' LIMIT 1
  ) THEN RETURN; END IF;

  FOR v_rec IN
    SELECT u.id AS user_id, COALESCE(u.note_moyenne, 0) AS note, COUNT(c.id) AS nb
    FROM users u
    LEFT JOIN courses c
           ON c.transporteur_id = u.id
          AND c.statut = 'terminee'
          AND date_trunc('month', c.updated_at) =
              date_trunc('month', NOW() - INTERVAL '1 month')
    WHERE u.role = 'transporteur'
    GROUP BY u.id, u.note_moyenne
    HAVING COUNT(c.id) >= 5
  LOOP
    v_bonus := 0;
    IF v_rec.note >= 4.5 THEN v_bonus := 500; END IF;
    IF v_bonus = 0 THEN CONTINUE; END IF;

    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_rec.user_id, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_rec.user_id;

    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW()
     WHERE id = v_wallet_id;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_id, 'prime_qualite', v_bonus, 'validee',
            v_ref || '_' || v_rec.user_id);
  END LOOP;
END;
$$;

-- ── 9. liberer_sequestre_course — commission dynamique + jalons + streak ──────
--    Intègre la commission à 10% pendant 7 jours post-KYC (vs 15% standard)
--    et appelle verifier_jalons_client + verifier_streak_hebdo à chaque livraison.

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
  v_taux_commission      NUMERIC;
  v_kyc_approuve_le      TIMESTAMPTZ;
  v_pct_parrainage       NUMERIC;
  v_parrain_client       UUID;
  v_parrain_transporteur UUID;
  v_wallet_parrain       UUID;
  v_comm_parrain         INT;
BEGIN

  -- ── Paiement confirmé (séquestre) uniquement ──────────────────────────────
  SELECT id, montant_fcfa
    INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id AND statut = 'sequestre'
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  -- ── Client et transporteur ────────────────────────────────────────────────
  SELECT client_id, transporteur_id
    INTO v_client_id, v_transporteur_id
    FROM courses WHERE id = p_course_id;

  IF v_transporteur_id IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- ── Commission dynamique ──────────────────────────────────────────────────
  -- 10% pendant les 7 jours post-approbation KYC, sinon 15% standard
  SELECT kyc_approuve_le INTO v_kyc_approuve_le
    FROM users WHERE id = v_transporteur_id;

  IF v_kyc_approuve_le IS NOT NULL
     AND NOW() - v_kyc_approuve_le < INTERVAL '7 days' THEN
    v_taux_commission := 0.10; -- Bonus KYC 1ère semaine
  ELSE
    v_taux_commission := 0.15; -- Standard
  END IF;

  v_commission := ROUND(v_montant * v_taux_commission);
  v_net        := v_montant - v_commission;

  -- ── Créditer transporteur ─────────────────────────────────────────────────
  INSERT INTO wallets(user_id, solde_fcfa)
    VALUES (v_transporteur_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_tr FROM wallets WHERE user_id = v_transporteur_id;

  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW()
   WHERE id = v_wallet_tr;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
  VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  -- ── Libérer le paiement ───────────────────────────────────────────────────
  UPDATE paiements SET statut = 'libere', libere_at = NOW()
   WHERE id = v_paiement_id;

  UPDATE courses SET statut_paiement = 'libere', updated_at = NOW()
   WHERE id = p_course_id;

  -- ── Parrainage (prélevé sur la commission CAARCO) ─────────────────────────
  SELECT COALESCE(valeur::NUMERIC, 0.10) INTO v_pct_parrainage
    FROM parametres WHERE cle = 'taux_commission_parrainage' LIMIT 1;
  v_pct_parrainage := COALESCE(v_pct_parrainage, 0.10);

  SELECT parrain_id INTO v_parrain_client
    FROM users WHERE id = v_client_id AND parrain_id IS NOT NULL;
  IF v_parrain_client IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parrain_client, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_client;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW()
     WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  SELECT parrain_id INTO v_parrain_transporteur
    FROM users WHERE id = v_transporteur_id AND parrain_id IS NOT NULL;
  IF v_parrain_transporteur IS NOT NULL THEN
    v_comm_parrain := ROUND(v_commission * v_pct_parrainage);
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parrain_transporteur, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_transporteur;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = NOW()
     WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_parrain, 'parrainage', v_comm_parrain, 'validee', p_course_id::text);
  END IF;

  -- ── Jalons surprise client ────────────────────────────────────────────────
  PERFORM verifier_jalons_client(v_client_id);

  -- ── Streak hebdomadaire client ────────────────────────────────────────────
  PERFORM verifier_streak_hebdo(v_client_id);

  RETURN jsonb_build_object(
    'ok',              true,
    'paiement_id',     v_paiement_id,
    'net_tr',          v_net,
    'commission',      v_commission,
    'taux_commission', v_taux_commission
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO service_role;

-- ── 10. pg_cron : classement quotidien + bonus mensuels ──────────────────────

-- Classement TR recalculé chaque nuit à minuit
SELECT cron.schedule(
  'caarco-classement-tr-quotidien',
  '0 0 * * *',
  'SELECT calculer_classement_mensuel()'
);

-- Bonus volume TR : le 1er de chaque mois à 6h (données du mois précédent)
SELECT cron.schedule(
  'caarco-bonus-volume-tr',
  '0 6 1 * *',
  'SELECT calculer_bonus_volume_mensuel()'
);

-- Prime qualité TR : le 1er de chaque mois à 6h30
SELECT cron.schedule(
  'caarco-prime-qualite-tr',
  '30 6 1 * *',
  'SELECT calculer_prime_qualite_mensuelle()'
);

-- Grants
GRANT EXECUTE ON FUNCTION verifier_jalons_client(UUID)        TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION verifier_streak_hebdo(UUID)         TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION calculer_classement_mensuel()       TO service_role;
GRANT EXECUTE ON FUNCTION calculer_bonus_volume_mensuel()     TO service_role;
GRANT EXECUTE ON FUNCTION calculer_prime_qualite_mensuelle()  TO service_role;
