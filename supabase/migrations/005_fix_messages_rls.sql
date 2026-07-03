-- ============================================================
-- CAARCO migration 005 — correctif RLS table messages
-- ============================================================
-- Contexte : migration 003 référençait messages avant sa création (004).
-- Ce fichier nettoie et recrée toutes les policies proprement.
-- ============================================================

-- 1. S'assurer que RLS est bien activé
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les policies existantes (noms variables selon l'ordre d'exécution)
DROP POLICY IF EXISTS "messages_lecture"  ON messages;
DROP POLICY IF EXISTS "messages_insert"   ON messages;
DROP POLICY IF EXISTS "messages_select"   ON messages;
DROP POLICY IF EXISTS "messages_envoi"    ON messages;

-- 3. Recréer les policies proprement

-- SELECT : doit être participant de la course (client OU transporteur)
CREATE POLICY "messages_select" ON messages
  FOR SELECT USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = messages.course_id
        AND (courses.client_id = auth.uid() OR courses.transporteur_id = auth.uid())
    )
  );

-- INSERT : l'expéditeur doit être l'utilisateur connecté
CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND expediteur_id = auth.uid()
  );

-- 4. S'assurer que la table est dans la publication Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 5. S'assurer que contenu est nullable (messages image sans texte)
ALTER TABLE messages ALTER COLUMN contenu DROP NOT NULL;
