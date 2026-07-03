-- Migration 028 : policy admin SELECT sur users
-- Permet à l'admin de voir tous les utilisateurs (jointures dans retraits, etc.)

CREATE POLICY "users_admin_select"
  ON users FOR SELECT
  USING (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
