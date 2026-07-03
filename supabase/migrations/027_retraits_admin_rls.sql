-- Migration 027 : RLS admin pour la table retraits
-- L'admin doit pouvoir lire et traiter toutes les demandes de retrait

-- Admin : lire toutes les demandes de retrait
CREATE POLICY "retraits_admin_select"
  ON retraits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin : mettre à jour le statut (traite / refuse) et la note
CREATE POLICY "retraits_admin_update"
  ON retraits FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
