-- Migration 031 : Trigger de synchronisation users.type_vehicule ← vehicules.categorie
-- Problème : users.type_vehicule n'était pas mis à jour automatiquement quand
-- un véhicule est créé ou validé par l'admin → profil du TR retourne null
-- → filtre categorie_vehicule non appliqué côté TableauBordScreen

CREATE OR REPLACE FUNCTION sync_user_type_vehicule()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET row_security = off
AS $$
BEGIN
  -- Sync uniquement si le véhicule est validé et que la catégorie est définie
  IF NEW.valide = true AND NEW.categorie IS NOT NULL THEN
    UPDATE users
    SET type_vehicule = NEW.categorie,
        updated_at    = now()
    WHERE id = NEW.transporteur_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_type_vehicule ON vehicules;
CREATE TRIGGER trg_sync_type_vehicule
  AFTER INSERT OR UPDATE ON vehicules
  FOR EACH ROW EXECUTE FUNCTION sync_user_type_vehicule();

-- Backfill pour les TRs existants dont type_vehicule est encore null
UPDATE users u
SET type_vehicule = v.categorie,
    updated_at    = now()
FROM vehicules v
WHERE v.transporteur_id = u.id
  AND v.valide = true
  AND v.categorie IS NOT NULL
  AND u.type_vehicule IS NULL;
