-- Migration 067 — Classement TR en temps réel
-- Problèmes corrigés :
--   1. updated_at → completed_at (champ stable, ne change qu'à la conclusion)
--   2. Suppression du filtre kyc_valide (redondant : migration 055 empêche
--      les non-KYC de prendre des courses, donc tout TR ayant terminee = KYC OK)
--   3. nombre_courses mis à jour dès la conclusion (pas à la soumission de l'avis)
--   4. Trigger en temps réel → classement recalculé après chaque course terminée
--      Le cron quotidien reste en place comme filet de sécurité

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 1 — Correction de calculer_classement_mensuel
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Reset tous les TRs du mois
  UPDATE users
  SET rang_tr_mois = NULL,
      top_tr_mois  = FALSE
  WHERE role = 'transporteur';

  -- 2. Recalculer sur les courses terminées CE mois-ci (completed_at, pas updated_at)
  WITH stats AS (
    SELECT
      c.transporteur_id                                                  AS uid,
      COUNT(*)                                                           AS nb,
      ROW_NUMBER() OVER (
        ORDER BY COUNT(*) * 2 + COALESCE(u.note_moyenne, 5.0) * 10 DESC
      )                                                                  AS rang
    FROM courses c
    JOIN users u
      ON u.id = c.transporteur_id
     AND u.role = 'transporteur'
    WHERE c.statut = 'terminee'
      AND c.completed_at IS NOT NULL
      AND date_trunc('month', c.completed_at) = date_trunc('month', NOW())
    GROUP BY c.transporteur_id, u.note_moyenne
  )
  UPDATE users u
     SET rang_tr_mois  = s.rang,
         top_tr_mois   = (s.rang <= 10),
         nombre_courses = (
           -- Remettre à jour nombre_courses en même temps (total cumulé, pas que ce mois)
           SELECT COUNT(*)
           FROM courses
           WHERE transporteur_id = u.id
             AND statut = 'terminee'
         )
    FROM stats s
   WHERE u.id = s.uid;
END;
$$;

-- Accessible par service_role (cron) ET par le trigger (authenticated n'est pas nécessaire
-- puisque le trigger tourne en SECURITY DEFINER)
GRANT EXECUTE ON FUNCTION calculer_classement_mensuel() TO service_role;
REVOKE EXECUTE ON FUNCTION calculer_classement_mensuel() FROM authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 2 — Fonction trigger : met à jour nombre_courses + relance le classement
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION maj_classement_apres_course()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Déclencher uniquement quand le statut passe à 'terminee'
  IF NEW.statut = 'terminee'
     AND (OLD.statut IS DISTINCT FROM 'terminee')
     AND NEW.transporteur_id IS NOT NULL
  THEN
    -- Mettre à jour nombre_courses immédiatement (n'attend pas l'avis)
    UPDATE users
    SET nombre_courses = (
      SELECT COUNT(*)
      FROM courses
      WHERE transporteur_id = NEW.transporteur_id
        AND statut = 'terminee'
    )
    WHERE id = NEW.transporteur_id;

    -- Recalculer le classement complet en temps réel
    PERFORM calculer_classement_mensuel();
  END IF;

  RETURN NEW;
END;
$$;

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 3 — Attacher le trigger sur la table courses
-- ══════════════════════════════════════════════════════════════════════════════
DROP TRIGGER IF EXISTS tr_classement_apres_course ON courses;

CREATE TRIGGER tr_classement_apres_course
  AFTER UPDATE OF statut ON courses
  FOR EACH ROW
  EXECUTE FUNCTION maj_classement_apres_course();

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 4 — Recalcul immédiat avec les données existantes
-- ══════════════════════════════════════════════════════════════════════════════
SELECT calculer_classement_mensuel();
