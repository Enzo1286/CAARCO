-- Migration 017 : SECURITY DEFINER sur crediter_points_course
-- PROBLÈME : quand le TR marque une course 'terminee', le trigger tente
-- d'insérer dans transactions_points et de mettre à jour users.points pour
-- le CLIENT. Mais le TR n'a pas les droits RLS pour ça → la transaction
-- rollback entière → "Impossible de confirmer la livraison."
-- FIX : SECURITY DEFINER permet au trigger de s'exécuter en tant que owner
-- (postgres) et bypasse les RLS policies.

CREATE OR REPLACE FUNCTION crediter_points_course()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER                          -- ← bypass RLS
SET search_path = public
AS $$
DECLARE
  pts INTEGER;
BEGIN
  IF NEW.statut = 'terminee' AND OLD.statut <> 'terminee' THEN
    pts := GREATEST(1, FLOOR(COALESCE(NEW.prix_fcfa, 0) / 100));

    -- Crédit client
    INSERT INTO transactions_points(user_id, montant, motif, course_id)
    VALUES (NEW.client_id, pts, 'course', NEW.id);

    UPDATE users SET points = points + pts WHERE id = NEW.client_id;

    -- Crédit parrain si existant
    IF EXISTS (SELECT 1 FROM users WHERE id = NEW.client_id AND parrain_id IS NOT NULL) THEN
      INSERT INTO transactions_points(user_id, montant, motif, course_id)
      SELECT parrain_id, GREATEST(1, pts / 2), 'parrainage', NEW.id
      FROM users WHERE id = NEW.client_id;

      UPDATE users u
      SET points = u.points + GREATEST(1, pts / 2)
      FROM users c
      WHERE c.id = NEW.client_id AND u.id = c.parrain_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
