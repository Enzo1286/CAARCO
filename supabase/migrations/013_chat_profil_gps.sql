-- Migration 013 : messages directs (DM), RLS, Realtime

-- ── 1. messages.course_id nullable (chat avant course) ───────────────────────
ALTER TABLE messages ALTER COLUMN course_id DROP NOT NULL;

-- ── 2. destinataire_id pour les DMs ─────────────────────────────────────────
ALTER TABLE messages ADD COLUMN IF NOT EXISTS destinataire_id uuid REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_messages_dm
  ON messages(expediteur_id, destinataire_id)
  WHERE course_id IS NULL;

-- ── 3. RLS messages — couvrir courses ET DMs ─────────────────────────────────
DROP POLICY IF EXISTS "messages_lecture" ON messages;
DROP POLICY IF EXISTS "messages_insert"  ON messages;

CREATE POLICY "messages_lecture" ON messages
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND (
      expediteur_id    = auth.uid()
      OR destinataire_id = auth.uid()
      OR (course_id IS NOT NULL AND course_id IN (
            SELECT id FROM courses
            WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
         ))
    )
  );

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND expediteur_id = auth.uid()
  );

-- ── 4. Realtime (ignore si déjà publié) ─────────────────────────────────────
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE wallets;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
