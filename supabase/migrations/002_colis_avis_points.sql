-- ============================================================
-- CAARCO migration 002 — colis details, avis, points, parrainage
-- ============================================================

-- 1. Nouvelles colonnes sur courses
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS poids_kg        NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS nb_colis        INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS dimension_l     NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS dimension_l2    NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS dimension_h     NUMERIC(5,1),
  ADD COLUMN IF NOT EXISTS categorie       TEXT,
  ADD COLUMN IF NOT EXISTS photos_colis    TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS mode_tarif      TEXT DEFAULT 'forfait',
  ADD COLUMN IF NOT EXISTS otp_livraison   CHAR(4);

-- 2. Nouvelles colonnes sur users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS points           INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS code_parrainage  TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS parrain_id       UUID REFERENCES users(id);

-- Générer un code parrainage unique pour les utilisateurs existants
UPDATE users
SET code_parrainage = UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', ''), 1, 6))
WHERE code_parrainage IS NULL;

-- 3. Table avis
CREATE TABLE IF NOT EXISTS avis (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id       UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  auteur_id       UUID NOT NULL REFERENCES users(id),
  cible_id        UUID NOT NULL REFERENCES users(id),
  note_globale    NUMERIC(2,1) NOT NULL CHECK (note_globale BETWEEN 1 AND 5),
  ponctualite     INTEGER CHECK (ponctualite BETWEEN 1 AND 5),
  soin_colis      INTEGER CHECK (soin_colis BETWEEN 1 AND 5),
  communication   INTEGER CHECK (communication BETWEEN 1 AND 5),
  proprete        INTEGER CHECK (proprete BETWEEN 1 AND 5),
  commentaire     TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, auteur_id)
);

-- 4. Table transactions_points
CREATE TABLE IF NOT EXISTS transactions_points (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  montant     INTEGER NOT NULL,  -- positif = crédit, négatif = débit
  motif       TEXT NOT NULL,     -- 'course', 'parrainage', 'echange'
  course_id   UUID REFERENCES courses(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Trigger : recalculer note_moyenne et nombre_courses sur users
CREATE OR REPLACE FUNCTION recalc_note_user()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET
    note_moyenne   = (SELECT COALESCE(AVG(note_globale), 5.0) FROM avis WHERE cible_id = NEW.cible_id),
    nombre_courses = (SELECT COUNT(*) FROM courses
                      WHERE (transporteur_id = NEW.cible_id OR client_id = NEW.cible_id)
                        AND statut = 'terminee')
  WHERE id = NEW.cible_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recalc_note ON avis;
CREATE TRIGGER trg_recalc_note
  AFTER INSERT OR UPDATE ON avis
  FOR EACH ROW EXECUTE FUNCTION recalc_note_user();

-- 6. Trigger : générer OTP à la création d'une course
CREATE OR REPLACE FUNCTION generer_otp_course()
RETURNS TRIGGER AS $$
BEGIN
  NEW.otp_livraison := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_otp_course ON courses;
CREATE TRIGGER trg_otp_course
  BEFORE INSERT ON courses
  FOR EACH ROW EXECUTE FUNCTION generer_otp_course();

-- 7. Trigger : générer code_parrainage à l'inscription
CREATE OR REPLACE FUNCTION generer_code_parrainage()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code_parrainage IS NULL THEN
    NEW.code_parrainage := UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', ''), 1, 6));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_code_parrainage ON users;
CREATE TRIGGER trg_code_parrainage
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION generer_code_parrainage();

-- 8. Trigger : créditer points après course terminée
CREATE OR REPLACE FUNCTION crediter_points_course()
RETURNS TRIGGER AS $$
DECLARE
  pts INTEGER;
BEGIN
  IF NEW.statut = 'terminee' AND OLD.statut <> 'terminee' THEN
    -- Client gagne 1 point par 100 XAF arrondi
    pts := GREATEST(1, FLOOR(COALESCE(NEW.prix_fcfa, 0) / 100));
    -- Crédit client
    INSERT INTO transactions_points(user_id, montant, motif, course_id)
    VALUES (NEW.client_id, pts, 'course', NEW.id);
    UPDATE users SET points = points + pts WHERE id = NEW.client_id;
    -- Crédit parrain si existant (50% des points du filleul, 1 fois par course)
    IF EXISTS (SELECT 1 FROM users WHERE id = NEW.client_id AND parrain_id IS NOT NULL) THEN
      INSERT INTO transactions_points(user_id, montant, motif, course_id)
      SELECT parrain_id, GREATEST(1, pts / 2), 'parrainage', NEW.id
      FROM users WHERE id = NEW.client_id;
      UPDATE users u
      SET points = u.points + GREATEST(1, pts / 2)
      FROM users c
      WHERE c.id = NEW.client_id AND u.id = c.parrain_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_points_course ON courses;
CREATE TRIGGER trg_points_course
  AFTER UPDATE OF statut ON courses
  FOR EACH ROW EXECUTE FUNCTION crediter_points_course();

-- 9. RLS policies
ALTER TABLE avis ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_points ENABLE ROW LEVEL SECURITY;

-- Tout utilisateur authentifié peut lire les avis (pour afficher les notes)
CREATE POLICY "avis_lecture" ON avis
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Auteur peut créer/modifier son avis
CREATE POLICY "avis_creation" ON avis
  FOR INSERT WITH CHECK (auteur_id = auth.uid());

CREATE POLICY "avis_modif" ON avis
  FOR UPDATE USING (auteur_id = auth.uid());

-- Chaque user voit ses propres transactions
CREATE POLICY "transactions_lecture" ON transactions_points
  FOR SELECT USING (user_id = auth.uid());
