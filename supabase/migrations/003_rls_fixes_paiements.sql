-- ============================================================
-- CAARCO migration 003 — RLS fixes + table paiements
-- ============================================================

-- 1. Autoriser les users à modifier leur propre ligne (profil)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_update_soi'
  ) THEN
    CREATE POLICY "users_update_soi" ON users
      FOR UPDATE USING (id = auth.uid());
  END IF;
END $$;

-- 2. RLS sur messages (s'assurer qu'elle existe)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- SELECT : participant à la course (client ou transporteur)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'messages_lecture'
  ) THEN
    CREATE POLICY "messages_lecture" ON messages
      FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        course_id IN (
          SELECT id FROM courses
          WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
        )
      );
  END IF;
END $$;

-- INSERT : tout utilisateur authentifié peut envoyer (l'app vérifie le rôle côté client)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'messages_insert'
  ) THEN
    CREATE POLICY "messages_insert" ON messages
      FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND expediteur_id = auth.uid()
      );
  END IF;
END $$;

-- 3. Table paiements
CREATE TABLE IF NOT EXISTS paiements (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id     UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  client_id     UUID NOT NULL REFERENCES users(id),
  montant_fcfa  INTEGER NOT NULL,
  methode       TEXT NOT NULL CHECK (methode IN ('orange_money', 'mtn_momo', 'especes')),
  numero_mobile TEXT,
  statut        TEXT NOT NULL DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'valide', 'echec')),
  reference     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE paiements ENABLE ROW LEVEL SECURITY;

-- Chaque client voit ses propres paiements
CREATE POLICY "paiements_lecture" ON paiements
  FOR SELECT USING (client_id = auth.uid());

-- Le client peut créer un paiement pour sa course
CREATE POLICY "paiements_insert" ON paiements
  FOR INSERT WITH CHECK (
    client_id = auth.uid() AND
    course_id IN (SELECT id FROM courses WHERE client_id = auth.uid())
  );

-- Le client peut mettre à jour son paiement (ex: retry)
CREATE POLICY "paiements_update" ON paiements
  FOR UPDATE USING (client_id = auth.uid());

-- Trigger: mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_paiement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_paiement_ts ON paiements;
CREATE TRIGGER trg_paiement_ts
  BEFORE UPDATE ON paiements
  FOR EACH ROW EXECUTE FUNCTION update_paiement_timestamp();

-- 4. Colonne statut_paiement sur courses
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS statut_paiement TEXT DEFAULT 'non_paye';

-- 5. Rendre messages.contenu nullable (pour les messages de type image)
ALTER TABLE messages ALTER COLUMN contenu DROP NOT NULL;

-- 6. Donner accès Realtime sur la table paiements (si Supabase Realtime activé)
-- (Supabase Realtime lit les RLS policies automatiquement)
