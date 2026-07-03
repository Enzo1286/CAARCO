-- Migration 009 : colonnes GPS sur la table users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS latitude          float8,
  ADD COLUMN IF NOT EXISTS longitude         float8,
  ADD COLUMN IF NOT EXISTS derniere_position timestamptz;

-- Politique existante : les utilisateurs peuvent mettre à jour leur propre position
-- Couverte par la politique "users_update_soi" de la migration 006
-- Si elle n'existe pas encore, la créer :
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'users' AND policyname = 'users_update_soi'
  ) THEN
    CREATE POLICY "users_update_soi" ON users
      FOR UPDATE USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;
