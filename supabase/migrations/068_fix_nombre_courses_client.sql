-- Migration 068 — Fix nombre_courses client
-- Problème :
--   liberer_sequestre_course (ligne jalons) lit users.nombre_courses pour le client
--   avant que ce compteur soit mis à jour → toujours 0 → jamais de jalon
--
-- Cause : nombre_courses n'est mis à jour que dans recalc_note_user()
--   qui se déclenche à la soumission d'un AVIS, pas à la conclusion de la course.
--
-- Fix :
--   1. Le trigger tr_classement_apres_course (067) est étendu pour mettre à jour
--      nombre_courses du CLIENT en plus du transporteur, AVANT que
--      liberer_sequestre_course ne soit appelé (même transaction = synchrone).
--   2. Resynchronisation immédiate de tous les compteurs existants.

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 1 — Mettre à jour le trigger pour inclure le client
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION maj_classement_apres_course()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.statut = 'terminee'
     AND (OLD.statut IS DISTINCT FROM 'terminee')
  THEN
    -- Mettre à jour nombre_courses du transporteur
    IF NEW.transporteur_id IS NOT NULL THEN
      UPDATE users
      SET nombre_courses = (
        SELECT COUNT(*)
        FROM courses
        WHERE transporteur_id = NEW.transporteur_id
          AND statut = 'terminee'
      )
      WHERE id = NEW.transporteur_id;
    END IF;

    -- Mettre à jour nombre_courses du CLIENT
    -- (critique : liberer_sequestre_course lit ce champ pour les jalons)
    IF NEW.client_id IS NOT NULL THEN
      UPDATE users
      SET nombre_courses = (
        SELECT COUNT(*)
        FROM courses
        WHERE client_id = NEW.client_id
          AND statut = 'terminee'
      )
      WHERE id = NEW.client_id;
    END IF;

    -- Recalculer le classement TR en temps réel
    PERFORM calculer_classement_mensuel();
  END IF;

  RETURN NEW;
END;
$$;

-- Recréer le trigger (la fonction est déjà attachée, DROP/CREATE pour sécurité)
DROP TRIGGER IF EXISTS tr_classement_apres_course ON courses;
CREATE TRIGGER tr_classement_apres_course
  AFTER UPDATE OF statut ON courses
  FOR EACH ROW
  EXECUTE FUNCTION maj_classement_apres_course();

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 2 — Resynchroniser nombre_courses pour TOUS les utilisateurs existants
--           (clients et transporteurs dont le compteur était faussé)
-- ══════════════════════════════════════════════════════════════════════════════

-- Pour les clients : compter les courses où ils sont l'expéditeur
UPDATE users u
SET nombre_courses = (
  SELECT COUNT(*)
  FROM courses c
  WHERE c.client_id = u.id
    AND c.statut = 'terminee'
)
WHERE u.role = 'client';

-- Pour les transporteurs : compter les courses qu'ils ont livrées
UPDATE users u
SET nombre_courses = (
  SELECT COUNT(*)
  FROM courses c
  WHERE c.transporteur_id = u.id
    AND c.statut = 'terminee'
)
WHERE u.role = 'transporteur';

-- ══════════════════════════════════════════════════════════════════════════════
-- ÉTAPE 3 — Attribuer les jalons manqués pour les clients dont le compteur
--           vient d'être corrigé (jalons 10, 20, 30, 50, 100)
-- ══════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT id, nombre_courses
    FROM users
    WHERE role = 'client'
      AND nombre_courses > 0
  LOOP
    -- Attribuer tous les jalons franchis (pas seulement le dernier)
    IF rec.nombre_courses >= 10  THEN PERFORM attribuer_jalon_client(rec.id, 10);  END IF;
    IF rec.nombre_courses >= 20  THEN PERFORM attribuer_jalon_client(rec.id, 20);  END IF;
    IF rec.nombre_courses >= 30  THEN PERFORM attribuer_jalon_client(rec.id, 30);  END IF;
    IF rec.nombre_courses >= 50  THEN PERFORM attribuer_jalon_client(rec.id, 50);  END IF;
    IF rec.nombre_courses >= 100 THEN PERFORM attribuer_jalon_client(rec.id, 100); END IF;
  END LOOP;
END;
$$;

-- Recalculer le classement TR avec les compteurs corrigés
SELECT calculer_classement_mensuel();
