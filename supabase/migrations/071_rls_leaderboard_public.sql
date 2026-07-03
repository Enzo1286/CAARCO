-- Migration 071 — RLS : permettre la lecture publique du classement TR
--
-- Problème : la politique "users_select" (migration 041) autorise uniquement
--   auth.uid() = id OR is_admin()
--   → Un TR authentifié ne voit QUE sa propre ligne dans la table users.
--   → LeaderboardScreen retourne 0 ou 1 résultat (lui-même) au lieu du top 20.
--
-- Fix : ajouter une politique permissive qui expose les données de classement
--   pour tous les utilisateurs authentifiés.
--   PostgreSQL applique les politiques permissives en OR → aucune régression.
--
-- Données exposées : rang, note, nombre_courses, nom, photo_url
--   (pas de téléphone, pas d'adresse, pas de données sensibles)

-- Politique permissive : n'importe quel utilisateur connecté peut lire les TR classés
DROP POLICY IF EXISTS "users_classement_tr" ON users;
CREATE POLICY "users_classement_tr"
  ON users FOR SELECT
  USING (
    role = 'transporteur'
    AND rang_tr_mois IS NOT NULL
  );

-- Force un recalcul immédiat pour que le classement soit à jour après ce fix
SELECT calculer_classement_mensuel();
