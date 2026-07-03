-- Migration 010 : fix définitif du trigger expediteur_id
-- Peut s'exécuter même si migration 008 n'a pas encore été appliquée

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS messages_avant_insert ON messages;

-- Recréer la fonction avec COALESCE robuste
CREATE OR REPLACE FUNCTION messages_avant_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- JS wins if provided; auth.uid() is the fallback
  NEW.expediteur_id := COALESCE(NEW.expediteur_id, auth.uid());
  IF NEW.expediteur_id IS NULL THEN
    RAISE EXCEPTION 'expediteur_id null : utilisateur non authentifié (code 001)';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger
CREATE TRIGGER messages_avant_insert
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION messages_avant_insert();
