-- ============================================================
-- CAARCO migration 004 — table messages, profil étendu, statut connexion
-- ============================================================

-- 1. Table messages (si elle n'existe pas déjà)
CREATE TABLE IF NOT EXISTS messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id     UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  expediteur_id UUID NOT NULL REFERENCES users(id),
  contenu       TEXT,
  type          TEXT NOT NULL DEFAULT 'texte' CHECK (type IN ('texte', 'image')),
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_course_id ON messages(course_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Activer Realtime sur messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 2. RLS sur messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_lecture"  ON messages;
DROP POLICY IF EXISTS "messages_insert"   ON messages;

-- SELECT : participants de la course
CREATE POLICY "messages_lecture" ON messages
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND
    course_id IN (
      SELECT id FROM courses
      WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
    )
  );

-- INSERT : utilisateur authentifié qui est bien l'expéditeur
CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND
    expediteur_id = auth.uid()
  );

-- 3. Nouvelles colonnes sur users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS pseudo           TEXT,
  ADD COLUMN IF NOT EXISTS langue           TEXT DEFAULT 'fr',
  ADD COLUMN IF NOT EXISTS statut_connexion TEXT DEFAULT 'hors_ligne',
  ADD COLUMN IF NOT EXISTS photo_url        TEXT;

-- 4. RLS users : s'assurer que l'utilisateur peut UPDATE sa propre ligne
DROP POLICY IF EXISTS "users_update_soi" ON users;
CREATE POLICY "users_update_soi" ON users
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- 5. Bucket avatars (instructions pour dashboard Supabase)
-- À créer manuellement dans le dashboard :
--   Storage > New bucket > Nom: "avatars" > Public: OUI
-- Ou via SQL (Supabase Storage API) :
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Policy lecture publique sur avatars
DROP POLICY IF EXISTS "avatars_lecture_publique" ON storage.objects;
CREATE POLICY "avatars_lecture_publique" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- Policy upload pour utilisateurs authentifiés (leur propre dossier)
DROP POLICY IF EXISTS "avatars_upload" ON storage.objects;
CREATE POLICY "avatars_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid() IS NOT NULL AND
    (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Policy mise à jour de son propre avatar
DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
CREATE POLICY "avatars_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::TEXT
  );
