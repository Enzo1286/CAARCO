-- Migration 046 : ajouter 'lien_carte' aux types autorisés dans messages

ALTER TABLE messages DROP CONSTRAINT messages_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_type_check
  CHECK (type = ANY (ARRAY['texte'::text, 'image'::text, 'lien_carte'::text]));
