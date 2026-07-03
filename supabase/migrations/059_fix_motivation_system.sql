-- ══════════════════════════════════════════════════════════════════════════════
-- Migration 059 — Correction système motivation (bugs critiques)
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Bug 1 : liberer_sequestre_course référence la table "parametres" qui n'existe pas
--         → remplacé par configurations_systeme.commission_parrainage_pct
--         → verifier_jalons_client appelé avec le montant de la course (2 args)
--
-- Bug 2 : verifier_jalons_client utilise des noms de colonnes inexistants
--         sur recompenses_client (user_id, type, pct_reduction, valeur_fcfa,
--         course_jalon) → aligné sur le schéma réel (client_id, recompense_type,
--         recompense_valeur, jalon)
--
-- Bug 3 : reveler_jalon RPC inexistant (motivation.js appelle rpc('reveler_jalon'))
--         → créé comme alias vers la logique de reveler_recompense
--
-- Bug 4 : candidater_course référence courses.completed_at (colonne inexistante)
--         et candidatures.updated_at (colonne inexistante)
--
-- Bug 5 : 0 cron job actif → classement TR jamais recalculé
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. verifier_jalons_client — colonnes corrigées ────────────────────────────
--    Signature étendue : reçoit p_prix_fcfa pour calculer la valeur dynamique.
--    Valeur par défaut 1000 pour compatibilité si appelé sans 2e argument.

CREATE OR REPLACE FUNCTION verifier_jalons_client(
  p_client_id UUID,
  p_prix_fcfa  INTEGER DEFAULT 1000
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nb     INTEGER;
  v_jalon  INTEGER;
  v_type   TEXT;
  v_valeur INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_nb
    FROM courses
   WHERE client_id = p_client_id AND statut = 'terminee';

  CASE v_nb
    WHEN 10  THEN v_jalon := 10;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.20)::INTEGER;
    WHEN 20  THEN v_jalon := 20;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.30)::INTEGER;
    WHEN 30  THEN v_jalon := 30;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.50)::INTEGER;
    WHEN 50  THEN v_jalon := 50;  v_type := 'wallet_credit'; v_valeur := LEAST(p_prix_fcfa, 5000);
    WHEN 100 THEN v_jalon := 100; v_type := 'vip';           v_valeur := 10000;
    ELSE RETURN;
  END CASE;

  -- Idempotent : un seul jalon par palier
  INSERT INTO recompenses_client (client_id, jalon, recompense_type, recompense_valeur, statut)
    VALUES (p_client_id, v_jalon, v_type, v_valeur, 'en_attente')
    ON CONFLICT DO NOTHING;

  IF v_type = 'vip' THEN
    UPDATE users SET statut_vip = TRUE WHERE id = p_client_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION verifier_jalons_client(UUID, INTEGER) TO authenticated, service_role;

-- ── 2. reveler_jalon — alias RPC attendu par motivation.js ────────────────────
--    Signature identique à l'appel : rpc('reveler_jalon', { p_jalon_id, p_client_id })
--    Marque recompenses_client.statut = 'revele' et retourne type + valeur.

CREATE OR REPLACE FUNCTION reveler_jalon(
  p_jalon_id  UUID,
  p_client_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row recompenses_client;
BEGIN
  SELECT * INTO v_row
    FROM recompenses_client
   WHERE id = p_jalon_id
     AND client_id = p_client_id
     AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'RECOMPENSE_INTROUVABLE'
      USING HINT = 'Ce jalon est introuvable ou déjà révélé.';
  END IF;

  UPDATE recompenses_client
     SET statut = 'revele', revele_le = NOW()
   WHERE id = p_jalon_id;

  RETURN jsonb_build_object(
    'id',     v_row.id,
    'jalon',  v_row.jalon,
    'type',   v_row.recompense_type,
    'valeur', v_row.recompense_valeur
  );
END;
$$;

GRANT EXECUTE ON FUNCTION reveler_jalon(UUID, UUID) TO authenticated;

-- ── 3. liberer_sequestre_course — corrigé ─────────────────────────────────────
--    • FROM parametres → FROM configurations_systeme (cle = 'commission_parrainage_pct')
--    • verifier_jalons_client appelé avec le montant de la course

CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pid   UUID;   v_montant   INT;
  v_cl_id UUID;   v_tr_id     UUID;
  v_wid   UUID;   v_net       INT;
  v_comm  INT;    v_taux      NUMERIC;
  v_kyc_dt       TIMESTAMPTZ;
  v_pct_parr     NUMERIC;
  v_parr_cl UUID; v_parr_tr UUID;
  v_wparr UUID;   v_cp INT;
BEGIN
  -- ── Paiement en séquestre ───────────────────────────────────────────────────
  SELECT id, montant_fcfa INTO v_pid, v_montant
    FROM paiements
   WHERE course_id = p_course_id AND statut = 'sequestre'
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  -- ── Parties ────────────────────────────────────────────────────────────────
  SELECT client_id, transporteur_id INTO v_cl_id, v_tr_id
    FROM courses WHERE id = p_course_id;

  IF v_tr_id IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- ── Commission dynamique (10% pendant 7j post-KYC, sinon 15%) ──────────────
  SELECT kyc_approuve_le INTO v_kyc_dt FROM users WHERE id = v_tr_id;
  IF v_kyc_dt IS NOT NULL AND NOW() - v_kyc_dt < INTERVAL '7 days' THEN
    v_taux := 0.10;
  ELSE
    v_taux := 0.15;
  END IF;

  v_comm := ROUND(v_montant * v_taux);
  v_net  := v_montant - v_comm;

  -- ── Créditer le transporteur ───────────────────────────────────────────────
  INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_tr_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wid FROM wallets WHERE user_id = v_tr_id;
  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW() WHERE id = v_wid;
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'recette', v_net, 'validee', p_course_id::text);

  -- ── Libérer le paiement ────────────────────────────────────────────────────
  UPDATE paiements SET statut = 'libere', libere_at = NOW() WHERE id = v_pid;
  UPDATE courses SET statut_paiement = 'libere', updated_at = NOW() WHERE id = p_course_id;

  -- ── Parrainage (prélevé sur la commission CAARCO) ──────────────────────────
  SELECT valeur::NUMERIC INTO v_pct_parr
    FROM configurations_systeme WHERE cle = 'commission_parrainage_pct';
  v_pct_parr := COALESCE(v_pct_parr, 0.05);

  SELECT parrain_id INTO v_parr_cl
    FROM users WHERE id = v_cl_id AND parrain_id IS NOT NULL;
  IF v_parr_cl IS NOT NULL THEN
    v_cp := ROUND(v_comm * v_pct_parr);
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parr_cl, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wparr FROM wallets WHERE user_id = v_parr_cl;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_cp, updated_at = NOW() WHERE id = v_wparr;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wparr, 'parrainage', v_cp, 'validee', p_course_id::text);
  END IF;

  SELECT parrain_id INTO v_parr_tr
    FROM users WHERE id = v_tr_id AND parrain_id IS NOT NULL;
  IF v_parr_tr IS NOT NULL THEN
    v_cp := ROUND(v_comm * v_pct_parr);
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parr_tr, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wparr FROM wallets WHERE user_id = v_parr_tr;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_cp, updated_at = NOW() WHERE id = v_wparr;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wparr, 'parrainage', v_cp, 'validee', p_course_id::text);
  END IF;

  -- ── Jalons surprise client (basés sur le montant de la course) ─────────────
  PERFORM verifier_jalons_client(v_cl_id, v_montant);

  -- ── Streak hebdomadaire client ─────────────────────────────────────────────
  PERFORM verifier_streak_hebdo(v_cl_id);

  RETURN jsonb_build_object(
    'ok',     true,
    'net_tr', v_net,
    'commission', v_comm,
    'taux',   v_taux
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated, service_role;

-- ── 4. candidater_course — completed_at + updated_at corrigés ─────────────────
--    • COALESCE(completed_at, updated_at) → updated_at seulement (completed_at n'existe pas)
--    • ON CONFLICT DO UPDATE SET updated_at = NOW() → supprimé (colonne inexistante)

CREATE OR REPLACE FUNCTION candidater_course(p_course_id UUID, p_transporteur_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_methode      TEXT;
  v_prix         INTEGER;
  v_commission   INTEGER;
  v_solde        INTEGER;
  v_kyc_valide   BOOLEAN;
  v_courses_mois INTEGER;
  v_candidature  JSONB;
BEGIN
  -- ── 1. Course disponible ───────────────────────────────────────────────────
  SELECT methode_paiement, prix_fcfa
    INTO v_methode, v_prix
    FROM courses
   WHERE id = p_course_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE'
      USING HINT = 'Cette course n''est plus disponible.';
  END IF;

  -- ── 2. Limite mensuelle pour TR non vérifiés ──────────────────────────────
  SELECT COALESCE(kyc_valide, false) INTO v_kyc_valide
    FROM users WHERE id = p_transporteur_id;

  IF NOT v_kyc_valide THEN
    SELECT COUNT(*)::INTEGER INTO v_courses_mois
      FROM courses
     WHERE transporteur_id = p_transporteur_id
       AND statut = 'terminee'
       AND date_trunc('month', updated_at) = date_trunc('month', NOW());

    IF v_courses_mois >= 2 THEN
      RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE'
        USING HINT = 'Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC pour continuer sans restriction.';
    END IF;
  END IF;

  -- ── 3. Vérification solde wallet (courses en espèces) ─────────────────────
  IF v_methode = 'especes' THEN
    v_commission := ROUND(v_prix::numeric * 0.15)::INTEGER;
    SELECT COALESCE(solde_fcfa, 0) INTO v_solde
      FROM wallets WHERE user_id = p_transporteur_id;
    IF v_solde < v_commission THEN
      RAISE EXCEPTION 'SOLDE_INSUFFISANT'
        USING HINT = format(
          'Solde wallet (%s XAF) insuffisant pour la commission de %s XAF.',
          v_solde, v_commission
        );
    END IF;
  END IF;

  -- ── 4. Insérer / mettre à jour la candidature ──────────────────────────────
  INSERT INTO candidatures (course_id, transporteur_id, statut)
  VALUES (p_course_id, p_transporteur_id, 'propose')
  ON CONFLICT (course_id, transporteur_id)
    DO UPDATE SET statut = 'propose'
  RETURNING to_jsonb(candidatures.*) INTO v_candidature;

  RETURN v_candidature;
END;
$$;

GRANT EXECUTE ON FUNCTION candidater_course(UUID, UUID) TO authenticated;

-- ── 5. Supprimer l'ancienne surcharge 1-arg de verifier_jalons_client ─────────
DROP FUNCTION IF EXISTS verifier_jalons_client(UUID);

-- ── 6. Trigger verifier_jalon_client — types alignés sur wallet_credit/vip ───
CREATE OR REPLACE FUNCTION verifier_jalon_client()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_nb INTEGER; v_type TEXT; v_valeur INTEGER;
BEGIN
  IF NEW.statut = 'terminee' AND OLD.statut IS DISTINCT FROM 'terminee'
     AND NEW.client_id IS NOT NULL
  THEN
    SELECT COUNT(*) INTO v_nb FROM courses
     WHERE client_id = NEW.client_id AND statut = 'terminee';
    CASE v_nb
      WHEN 10  THEN v_type := 'wallet_credit'; v_valeur := ROUND(NEW.prix_fcfa * 0.20)::INTEGER;
      WHEN 20  THEN v_type := 'wallet_credit'; v_valeur := ROUND(NEW.prix_fcfa * 0.30)::INTEGER;
      WHEN 30  THEN v_type := 'wallet_credit'; v_valeur := ROUND(NEW.prix_fcfa * 0.50)::INTEGER;
      WHEN 50  THEN v_type := 'wallet_credit'; v_valeur := LEAST(NEW.prix_fcfa, 5000);
      WHEN 100 THEN v_type := 'vip';           v_valeur := 10000;
      ELSE RETURN NEW;
    END CASE;
    INSERT INTO recompenses_client (client_id, jalon, recompense_type, recompense_valeur, statut)
      VALUES (NEW.client_id, v_nb, v_type, v_valeur, 'en_attente')
      ON CONFLICT DO NOTHING;
    IF v_type = 'vip' THEN
      UPDATE users SET statut_vip = TRUE, est_vip = TRUE WHERE id = NEW.client_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ── 7. Crons pg_cron ──────────────────────────────────────────────────────────
--    Utilise ON CONFLICT DO UPDATE pour éviter les doublons si rejouée.

INSERT INTO cron.job (schedule, command, jobname, database, username)
SELECT '0 0 * * *',
       'SELECT calculer_classement_mensuel()',
       'caarco-classement-tr-quotidien',
       current_database(),
       current_user
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-classement-tr-quotidien');

INSERT INTO cron.job (schedule, command, jobname, database, username)
SELECT '0 6 1 * *',
       'SELECT calculer_bonus_volume_mensuel()',
       'caarco-bonus-volume-mensuel',
       current_database(),
       current_user
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-bonus-volume-mensuel');

INSERT INTO cron.job (schedule, command, jobname, database, username)
SELECT '30 6 1 * *',
       'SELECT calculer_prime_qualite_mensuelle()',
       'caarco-prime-qualite-mensuel',
       current_database(),
       current_user
WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-prime-qualite-mensuel');
