-- ============================================================
-- CAARCO migration 006 — trigger expediteur_id messages + RLS users
-- ============================================================

-- ── 1. Trigger : forcer expediteur_id = auth.uid() avant chaque INSERT ──────
--    Élimine tout risque de mismatch entre la valeur JS et auth.uid() côté DB
CREATE OR REPLACE FUNCTION messages_avant_insert()
RETURNS TRIGGER AS $$
BEGIN
  NEW.expediteur_id := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_messages_expediteur ON messages;
CREATE TRIGGER trg_messages_expediteur
  BEFORE INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION messages_avant_insert();

-- ── 2. Simplifier la policy INSERT (le trigger garantit expediteur_id correct) ──
DROP POLICY IF EXISTS "messages_insert"  ON messages;
DROP POLICY IF EXISTS "messages_lecture" ON messages;
DROP POLICY IF EXISTS "messages_select"  ON messages;
DROP POLICY IF EXISTS "messages_envoi"   ON messages;

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- SELECT : expéditeur voit ses propres messages ; participants voient tous les messages du cours
CREATE POLICY "messages_select" ON messages
  FOR SELECT USING (
    auth.uid() IS NOT NULL
    AND (
      expediteur_id = auth.uid()
      OR course_id IN (
        SELECT id FROM courses
        WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
      )
    )
  );

-- ── 3. RLS sur users ──────────────────────────────────────────────────────────
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- SELECT : tout utilisateur authentifié peut lire les profils (transporteurs, clients)
DROP POLICY IF EXISTS "users_lecture"    ON users;
DROP POLICY IF EXISTS "users_select"     ON users;
CREATE POLICY "users_lecture" ON users
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- INSERT : à l'inscription, l'utilisateur crée sa propre ligne
DROP POLICY IF EXISTS "users_insert"     ON users;
CREATE POLICY "users_insert" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- UPDATE : chaque utilisateur modifie uniquement sa propre ligne
DROP POLICY IF EXISTS "users_update_soi" ON users;
CREATE POLICY "users_update_soi" ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
