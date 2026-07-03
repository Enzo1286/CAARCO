-- Migration 057 : Fonctions métier du système de motivation CAARCO
-- Jalons client · Streak · Commission KYC · Leaderboard · Bonus volume · Prime qualité

-- ═══════════════════════════════════════════════════════════════════════
-- 1. COMMISSION TAUX TR
--    Retourne 0.10 si le TR a été approuvé KYC il y a < 7 jours, sinon 0.15
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION commission_taux_tr(p_tr_id UUID)
RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    WHEN kyc_approuve_le IS NOT NULL
     AND kyc_approuve_le > NOW() - INTERVAL '7 days'
    THEN 0.10
    ELSE 0.15
  END
  FROM users WHERE id = p_tr_id;
$$;

-- ═══════════════════════════════════════════════════════════════════════
-- 2. MISE À JOUR liberer_sequestre_course
--    Intègre la commission dynamique (10% si KYC récent, sinon 15%)
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_paiement_id    UUID;
  v_montant        INT;
  v_transporteur   UUID;
  v_wallet_tr      UUID;
  v_taux_commission NUMERIC;
  v_commission     INT;
  v_net            INT;
BEGIN
  SELECT id, montant_fcfa INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id AND statut IN ('sequestre', 'initie')
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_mobile_payment');
  END IF;

  SELECT transporteur_id INTO v_transporteur FROM courses WHERE id = p_course_id;

  IF v_transporteur IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- Commission dynamique : 10% si KYC approuvé < 7 jours, sinon 15%
  v_taux_commission := COALESCE(commission_taux_tr(v_transporteur), 0.15);
  v_commission      := ROUND(v_montant * v_taux_commission);
  v_net             := v_montant - v_commission;

  INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_transporteur, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_tr FROM wallets WHERE user_id = v_transporteur;

  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW()
   WHERE id = v_wallet_tr;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  UPDATE paiements SET statut = 'libere', libere_at = NOW() WHERE id = v_paiement_id;

  UPDATE courses SET statut_paiement = 'libere', updated_at = NOW() WHERE id = p_course_id;

  RETURN jsonb_build_object(
    'success', true,
    'net_transporteur', v_net,
    'commission', v_commission,
    'taux_commission', v_taux_commission,
    'montant_total', v_montant
  );
END;
$$;

GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated, service_role;

-- ═══════════════════════════════════════════════════════════════════════
-- 3. JALONS CLIENT
--    Enregistre la surprise à chaque palier (10/20/30/50/100 courses).
--    Le crédit wallet ne se fait qu'à la révélation (reveler_jalon).
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION verifier_jalons_client(p_client_id UUID, p_prix_fcfa INTEGER)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_nb_courses      INTEGER;
  v_jalon           INTEGER;
  v_type            TEXT;
  v_valeur          INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_nb_courses
    FROM courses WHERE client_id = p_client_id AND statut = 'terminee';

  CASE v_nb_courses
    WHEN 10  THEN v_jalon := 10;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.20)::INTEGER;
    WHEN 20  THEN v_jalon := 20;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.30)::INTEGER;
    WHEN 30  THEN v_jalon := 30;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.50)::INTEGER;
    WHEN 50  THEN v_jalon := 50;  v_type := 'wallet_credit'; v_valeur := LEAST(p_prix_fcfa, 5000);
    WHEN 100 THEN v_jalon := 100; v_type := 'vip';           v_valeur := 10000;
    ELSE RETURN;
  END CASE;

  INSERT INTO jalons_client (client_id, jalon, recompense_type, recompense_valeur)
    VALUES (p_client_id, v_jalon, v_type, v_valeur)
    ON CONFLICT (client_id, jalon) DO NOTHING;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════
-- 4. RÉVÉLER UN JALON
--    Appelé quand le client tape "Révéler" → crédit wallet + statut revele
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION reveler_jalon(p_jalon_id UUID, p_client_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_j       jalons_client;
  v_wid     UUID;
BEGIN
  SELECT * INTO v_j FROM jalons_client
   WHERE id = p_jalon_id AND client_id = p_client_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'JALON_INVALIDE';
  END IF;

  UPDATE jalons_client SET statut = 'revele', revele_at = NOW() WHERE id = p_jalon_id;

  -- Créditer le wallet
  IF v_j.recompense_type = 'wallet_credit' AND v_j.recompense_valeur > 0 THEN
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (p_client_id, 0)
      ON CONFLICT (user_id) DO NOTHING;

    SELECT id INTO v_wid FROM wallets WHERE user_id = p_client_id;

    UPDATE wallets SET solde_fcfa = solde_fcfa + v_j.recompense_valeur, updated_at = NOW()
     WHERE id = v_wid;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'jalon_client', v_j.recompense_valeur, 'validee',
              'jalon_' || v_j.jalon::text || '_' || p_client_id::text);
  END IF;

  -- Statut VIP (100 courses)
  IF v_j.recompense_type = 'vip' THEN
    UPDATE users SET statut_vip = true WHERE id = p_client_id;

    -- Créditer aussi les 10 000 XAF offerts aux VIP
    IF v_j.recompense_valeur > 0 THEN
      INSERT INTO wallets(user_id, solde_fcfa) VALUES (p_client_id, 0)
        ON CONFLICT (user_id) DO NOTHING;
      SELECT id INTO v_wid FROM wallets WHERE user_id = p_client_id;
      UPDATE wallets SET solde_fcfa = solde_fcfa + v_j.recompense_valeur, updated_at = NOW()
       WHERE id = v_wid;
      INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
        VALUES (v_wid, 'jalon_client', v_j.recompense_valeur, 'validee', 'jalon_vip_' || p_client_id::text);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'jalon',  v_j.jalon,
    'type',   v_j.recompense_type,
    'valeur', v_j.recompense_valeur
  );
END;
$$;

GRANT EXECUTE ON FUNCTION reveler_jalon(UUID, UUID) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════
-- 5. STREAK HEBDOMADAIRE CLIENT
--    3 courses dans la semaine en cours → 100 XAF (une seule fois/semaine)
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION verifier_streak_client(p_client_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_nb  INTEGER;
  v_wid UUID;
BEGIN
  -- Compter exactement 3 courses cette semaine ISO (déclenchement précis)
  SELECT COUNT(*) INTO v_nb
    FROM courses
   WHERE client_id = p_client_id
     AND statut    = 'terminee'
     AND COALESCE(completed_at, updated_at) >= date_trunc('week', NOW());

  IF v_nb <> 3 THEN RETURN; END IF;

  -- Vérifier qu'on n'a pas déjà crédité cette semaine
  IF EXISTS (
    SELECT 1 FROM transactions_wallet tw
      JOIN wallets w ON w.id = tw.wallet_id
     WHERE w.user_id = p_client_id
       AND tw.type   = 'streak_client'
       AND tw.created_at >= date_trunc('week', NOW())
  ) THEN RETURN; END IF;

  INSERT INTO wallets(user_id, solde_fcfa) VALUES (p_client_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wid FROM wallets WHERE user_id = p_client_id;

  UPDATE wallets SET solde_fcfa = solde_fcfa + 100, updated_at = NOW()
   WHERE id = v_wid;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'streak_client', 100, 'validee',
            'streak_' || to_char(NOW(), 'IYYY_IW'));
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════
-- 6. TRIGGER — après course terminée → jalons + streak
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION trigger_after_course_terminee()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.statut = 'terminee' AND COALESCE(OLD.statut, '') <> 'terminee' THEN
    -- Marquer completed_at si absent
    IF NEW.completed_at IS NULL THEN
      UPDATE courses SET completed_at = NOW() WHERE id = NEW.id;
    END IF;
    -- Jalons + streak client
    IF NEW.client_id IS NOT NULL THEN
      PERFORM verifier_jalons_client(NEW.client_id, COALESCE(NEW.prix_fcfa, 1000));
      PERFORM verifier_streak_client(NEW.client_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_course_terminee ON courses;
CREATE TRIGGER after_course_terminee
  AFTER UPDATE ON courses
  FOR EACH ROW
  EXECUTE FUNCTION trigger_after_course_terminee();

-- ═══════════════════════════════════════════════════════════════════════
-- 7. CLASSEMENT MENSUEL TR (exécuté chaque jour à minuit)
--    Score = nb_courses + (note_moy - 3) × 5 → favorise la qualité
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE users SET top_tr_mois = false, rang_tr_mois = NULL
   WHERE role = 'transporteur';

  WITH scores AS (
    SELECT
      c.transporteur_id,
      COUNT(DISTINCT c.id)             AS nb_courses,
      COALESCE(AVG(n.score), 5.0)      AS note_moy,
      COUNT(DISTINCT c.id) + (COALESCE(AVG(n.score), 5.0) - 3) * 5 AS score_total
    FROM courses c
    LEFT JOIN notations n ON n.course_id = c.id AND n.noter_id = c.client_id
    WHERE c.statut = 'terminee'
      AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = date_trunc('month', NOW())
    GROUP BY c.transporteur_id
  ),
  rangs AS (
    SELECT transporteur_id,
           ROW_NUMBER() OVER (ORDER BY score_total DESC, nb_courses DESC) AS rang
    FROM scores
  )
  UPDATE users u
     SET rang_tr_mois = r.rang,
         top_tr_mois  = (r.rang <= 10)
    FROM rangs r
   WHERE u.id = r.transporteur_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════
-- 8. BONUS VOLUME MENSUEL (exécuté le 1er de chaque mois)
--    Crédite la différence de commission pour les TR actifs du mois précédent
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION calculer_bonus_volume_mensuel()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_rec        RECORD;
  v_taux_bonus NUMERIC;
  v_bonus      INTEGER;
  v_wid        UUID;
  v_mois_prec  DATE := date_trunc('month', NOW() - INTERVAL '1 month');
  v_label      TEXT;
BEGIN
  FOR v_rec IN
    SELECT transporteur_id,
           COUNT(*)::INTEGER                    AS nb_courses,
           SUM(ROUND(prix_fcfa * 0.15))::INTEGER AS total_commissions
      FROM courses
     WHERE statut = 'terminee'
       AND date_trunc('month', COALESCE(completed_at, updated_at)) = v_mois_prec
     GROUP BY transporteur_id
     HAVING COUNT(*) >= 10
  LOOP
    v_taux_bonus := CASE
      WHEN v_rec.nb_courses >= 50 THEN 0.07
      WHEN v_rec.nb_courses >= 25 THEN 0.04
      ELSE 0.02
    END;

    v_bonus := ROUND(v_rec.total_commissions * v_taux_bonus)::INTEGER;
    IF v_bonus <= 0 THEN CONTINUE; END IF;

    v_label := CASE
      WHEN v_rec.nb_courses >= 50 THEN format('%s courses → bonus 7%%', v_rec.nb_courses)
      WHEN v_rec.nb_courses >= 25 THEN format('%s courses → bonus 4%%', v_rec.nb_courses)
      ELSE                              format('%s courses → bonus 2%%', v_rec.nb_courses)
    END;

    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_rec.transporteur_id, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM wallets WHERE user_id = v_rec.transporteur_id;

    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW()
     WHERE id = v_wid;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'bonus_volume', v_bonus, 'validee',
              format('bvol_%s_%s', v_rec.transporteur_id, to_char(v_mois_prec, 'YYYY_MM')));
  END LOOP;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════
-- 9. PRIME QUALITÉ MENSUELLE (exécuté le 1er de chaque mois)
--    Note ≥ 4.5 → +2 000 XAF | Taux acceptation > 80% → +1 500 XAF | Les deux → +5 000 XAF
--    Éligible : ≥ 5 courses terminées le mois précédent
-- ═══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION calculer_prime_qualite_mensuel()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_rec       RECORD;
  v_note_ok   BOOLEAN;
  v_taux_ok   BOOLEAN;
  v_bonus     INTEGER;
  v_wid       UUID;
  v_mois_prec DATE := date_trunc('month', NOW() - INTERVAL '1 month');
  v_desc      TEXT;
BEGIN
  FOR v_rec IN
    SELECT
      u.id                                                                    AS tr_id,
      COALESCE(AVG(n.score), 0)                                              AS note_moy,
      COUNT(DISTINCT c.id) FILTER (WHERE c.statut = 'terminee')             AS courses_ok,
      COUNT(DISTINCT ca.id)                                                  AS cands_total,
      COUNT(DISTINCT ca.id) FILTER (WHERE ca.statut IN ('propose','acceptee')) AS cands_ok
    FROM users u
    LEFT JOIN courses c ON c.transporteur_id = u.id
      AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois_prec
    LEFT JOIN notations n ON n.course_id = c.id AND n.noter_id = c.client_id
    LEFT JOIN candidatures ca ON ca.transporteur_id = u.id
      AND date_trunc('month', ca.created_at) = v_mois_prec
    WHERE u.role = 'transporteur'
    GROUP BY u.id
    HAVING COUNT(DISTINCT c.id) FILTER (WHERE c.statut = 'terminee') >= 5
  LOOP
    v_note_ok := v_rec.note_moy >= 4.5;
    v_taux_ok := v_rec.cands_total > 0
      AND (v_rec.cands_ok::NUMERIC / v_rec.cands_total) > 0.80;

    v_bonus := CASE
      WHEN v_note_ok AND v_taux_ok THEN 5000
      WHEN v_note_ok               THEN 2000
      WHEN v_taux_ok               THEN 1500
      ELSE 0
    END;
    IF v_bonus = 0 THEN CONTINUE; END IF;

    v_desc := CASE
      WHEN v_note_ok AND v_taux_ok THEN 'Note ≥ 4.5 + Taux acceptation > 80%'
      WHEN v_note_ok               THEN 'Note moyenne ≥ 4.5'
      ELSE                              'Taux d''acceptation > 80%'
    END;

    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_rec.tr_id, 0)
      ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM wallets WHERE user_id = v_rec.tr_id;

    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW()
     WHERE id = v_wid;

    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'prime_qualite', v_bonus, 'validee',
              format('pqual_%s_%s', v_rec.tr_id, to_char(v_mois_prec, 'YYYY_MM')));
  END LOOP;
END;
$$;
