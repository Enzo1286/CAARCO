-- Migration 058 : Leaderboard mensuel TR + bonus volume + bonus qualité + cron
-- Calcul automatique le 1er de chaque mois à 6h (pg_cron déjà activé en 015).

-- ── 1. Table classement mensuel ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classement_mensuel_tr (
  user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mois         DATE        NOT NULL,  -- 1er du mois (date_trunc month)
  rang         INTEGER     NOT NULL,
  nb_courses   INTEGER     NOT NULL DEFAULT 0,
  note_moyenne DECIMAL(3,2)          DEFAULT 0,
  is_top10     BOOLEAN     NOT NULL DEFAULT false,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, mois)
);

-- Colonne sur users pour accès rapide côté client (badge "Top TR du mois")
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_top_tr_mois BOOLEAN DEFAULT false;

-- ── 2. Configurations bonus (éditables par admin via ConfigTarifsScreen) ──────
INSERT INTO configurations_systeme (cle, valeur) VALUES
  ('bonus_volume_tier1_pct',   '2'),
  ('bonus_volume_tier2_pct',   '4'),
  ('bonus_volume_tier3_pct',   '7'),
  ('bonus_qualite_note_xaf',   '2000'),
  ('bonus_qualite_accept_xaf', '2000'),
  ('streak_client_xaf',        '100'),
  ('kyc_commission_duree_j',   '7'),
  ('kyc_commission_taux',      '0.10')
ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur;

-- ── 3. Fonction : calculer classement mensuel des TR ─────────────────────────
CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_mois DATE := date_trunc('month', NOW())::DATE;
BEGIN
  -- Réinitialiser le badge Top TR sur tous les utilisateurs
  UPDATE users SET is_top_tr_mois = false WHERE is_top_tr_mois = true;

  -- Recalculer le classement du mois courant
  INSERT INTO classement_mensuel_tr (user_id, mois, rang, nb_courses, note_moyenne, is_top10, updated_at)
  SELECT
    u.id                                  AS user_id,
    v_mois                                AS mois,
    ROW_NUMBER() OVER (
      ORDER BY COUNT(c.id) DESC, COALESCE(u.note_moyenne, 0) DESC
    )::INTEGER                            AS rang,
    COUNT(c.id)::INTEGER                  AS nb_courses,
    COALESCE(u.note_moyenne, 0)           AS note_moyenne,
    false                                 AS is_top10,
    NOW()                                 AS updated_at
  FROM users u
  LEFT JOIN courses c
    ON c.transporteur_id = u.id
    AND c.statut         = 'terminee'
    AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois
  WHERE u.role = 'transporteur'
  GROUP BY u.id
  HAVING COUNT(c.id) > 0
  ON CONFLICT (user_id, mois) DO UPDATE
    SET rang         = EXCLUDED.rang,
        nb_courses   = EXCLUDED.nb_courses,
        note_moyenne = EXCLUDED.note_moyenne,
        is_top10     = false,
        updated_at   = NOW();

  -- Marquer top 10
  UPDATE classement_mensuel_tr
     SET is_top10 = true
   WHERE mois = v_mois AND rang <= 10;

  -- Sync badge sur users
  UPDATE users u
     SET is_top_tr_mois = true
  FROM classement_mensuel_tr c
  WHERE c.user_id = u.id
    AND c.mois    = v_mois
    AND c.is_top10 = true;
END;
$$;

-- ── 4. Fonction : calculer et créditer bonus mensuel TR ───────────────────────
CREATE OR REPLACE FUNCTION calculer_bonus_mensuel_tr()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_mois_prec           DATE    := (date_trunc('month', NOW()) - INTERVAL '1 month')::DATE;
  v_tier1_pct           INTEGER;
  v_tier2_pct           INTEGER;
  v_tier3_pct           INTEGER;
  v_bonus_note_xaf      INTEGER;
  v_bonus_accept_xaf    INTEGER;
  v_tr                  RECORD;
  v_nb_courses          INTEGER;
  v_commissions_payees  INTEGER;
  v_note_mois           NUMERIC;
  v_taux_acceptation    NUMERIC;
  v_bonus_volume        INTEGER;
  v_bonus_qualite       INTEGER;
  v_bonus_total         INTEGER;
  v_wallet_id           UUID;
BEGIN
  -- Lire les configs
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier1_pct'),2)  INTO v_tier1_pct;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier2_pct'),4)  INTO v_tier2_pct;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier3_pct'),7)  INTO v_tier3_pct;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_qualite_note_xaf'),2000) INTO v_bonus_note_xaf;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_qualite_accept_xaf'),2000) INTO v_bonus_accept_xaf;

  -- Itérer sur tous les TR ayant fait au least 1 course le mois précédent
  FOR v_tr IN
    SELECT u.id AS user_id
    FROM users u
    WHERE u.role = 'transporteur'
      AND EXISTS (
        SELECT 1 FROM courses c
        WHERE c.transporteur_id = u.id
          AND c.statut          = 'terminee'
          AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois_prec
      )
  LOOP
    -- Volume : nombre de courses terminées le mois dernier
    SELECT COUNT(*)::INTEGER INTO v_nb_courses
      FROM courses
     WHERE transporteur_id = v_tr.user_id
       AND statut           = 'terminee'
       AND date_trunc('month', COALESCE(completed_at, updated_at)) = v_mois_prec;

    -- Commissions payées le mois dernier (pour calcul volume bonus)
    SELECT COALESCE(SUM(tw.montant_fcfa), 0)::INTEGER INTO v_commissions_payees
      FROM transactions_wallet tw
      JOIN wallets w ON w.id = tw.wallet_id
     WHERE w.user_id = v_tr.user_id
       AND tw.type   = 'recette'
       AND date_trunc('month', tw.created_at) = v_mois_prec;

    -- Bonus volume
    v_bonus_volume := CASE
      WHEN v_nb_courses >= 50 THEN ROUND(v_commissions_payees * v_tier3_pct::NUMERIC / 100)
      WHEN v_nb_courses >= 25 THEN ROUND(v_commissions_payees * v_tier2_pct::NUMERIC / 100)
      WHEN v_nb_courses >= 10 THEN ROUND(v_commissions_payees * v_tier1_pct::NUMERIC / 100)
      ELSE 0
    END;

    -- Note moyenne sur le mois précédent
    SELECT COALESCE(AVG(a.note_globale), 0) INTO v_note_mois
      FROM avis a
      JOIN courses c ON c.id = a.course_id
     WHERE c.transporteur_id = v_tr.user_id
       AND date_trunc('month', a.created_at) = v_mois_prec;

    -- Taux d'acceptation = candidatures sélectionnées / soumises ce mois
    SELECT CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE COUNT(*) FILTER (WHERE statut = 'accepte')::NUMERIC / COUNT(*)
    END INTO v_taux_acceptation
    FROM candidatures
    WHERE transporteur_id = v_tr.user_id
      AND date_trunc('month', created_at) = v_mois_prec;

    -- Bonus qualité
    v_bonus_qualite := 0;
    IF v_note_mois     >= 4.5 THEN v_bonus_qualite := v_bonus_qualite + v_bonus_note_xaf;   END IF;
    IF v_taux_acceptation > 0.80 THEN v_bonus_qualite := v_bonus_qualite + v_bonus_accept_xaf; END IF;

    v_bonus_total := v_bonus_volume + v_bonus_qualite;

    -- Créditer wallet si bonus > 0
    IF v_bonus_total > 0 THEN
      INSERT INTO wallets (user_id, solde_fcfa)
        VALUES (v_tr.user_id, 0) ON CONFLICT (user_id) DO NOTHING;
      SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_tr.user_id;
      UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus_total, updated_at = NOW()
       WHERE id = v_wallet_id;
      INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
        VALUES (v_wallet_id, 'bonus_fidelite', v_bonus_total, 'validee',
                'bonus_' || TO_CHAR(v_mois_prec, 'YYYY_MM'));
    END IF;
  END LOOP;
END;
$$;

-- ── 5. Cron mensuel : 1er du mois à 6h ───────────────────────────────────────
DO $$
BEGIN
  BEGIN PERFORM cron.unschedule('bonus-mensuel-tr'); EXCEPTION WHEN others THEN NULL; END;
  BEGIN
    PERFORM cron.schedule(
      'bonus-mensuel-tr',
      '0 6 1 * *',
      $$SELECT calculer_classement_mensuel(); SELECT calculer_bonus_mensuel_tr();$$
    );
  EXCEPTION WHEN others THEN NULL; END;
END;
$$;

GRANT EXECUTE ON FUNCTION calculer_classement_mensuel()  TO service_role;
GRANT EXECUTE ON FUNCTION calculer_bonus_mensuel_tr()    TO service_role;
