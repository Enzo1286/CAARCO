-- ============================================================
-- Migration 035 — Code parrainage automatique + stats RPC
-- ============================================================
-- Implémente l'idée de Cedric :
--   • Chaque utilisateur reçoit un code unique et permanent
--   • Généré automatiquement à l'inscription via trigger
--   • Généré pour les utilisateurs existants sans code
--   • Contrainte UNIQUE garantit l'unicité
--   • get_stats_parrainage() retourne les gains du parrain connecté
-- ============================================================


-- ── 1. GENERATEUR DE CODE ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generer_code_parrainage()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_code text;
  v_existe boolean;
  v_chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- sans 0/O/1/I (ambigus)
  i int;
BEGIN
  LOOP
    -- Générer 6 caractères aléatoires
    v_code := '';
    FOR i IN 1..6 LOOP
      v_code := v_code || substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);
    END LOOP;

    -- Vérifier l'unicité
    SELECT EXISTS (
      SELECT 1 FROM users WHERE code_parrainage = v_code
    ) INTO v_existe;

    EXIT WHEN NOT v_existe;
  END LOOP;
  RETURN v_code;
END;
$$;


-- ── 2. TRIGGER — auto-générer le code à l'inscription ───────────────────────
CREATE OR REPLACE FUNCTION trigger_code_parrainage()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.code_parrainage IS NULL OR NEW.code_parrainage = '' THEN
    NEW.code_parrainage := generer_code_parrainage();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS auto_code_parrainage ON users;
CREATE TRIGGER auto_code_parrainage
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION trigger_code_parrainage();


-- ── 3. GÉNÉRER LES CODES MANQUANTS POUR LES UTILISATEURS EXISTANTS ──────────
DO $$
DECLARE
  v_user record;
BEGIN
  FOR v_user IN SELECT id FROM users WHERE code_parrainage IS NULL LOOP
    UPDATE users
       SET code_parrainage = generer_code_parrainage()
     WHERE id = v_user.id;
  END LOOP;
END;
$$;


-- ── 4. CONTRAINTE UNIQUE + NON NUL ───────────────────────────────────────────
ALTER TABLE users
  ALTER COLUMN code_parrainage SET NOT NULL;

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_code_parrainage_unique;

ALTER TABLE users
  ADD CONSTRAINT users_code_parrainage_unique UNIQUE (code_parrainage);


-- ── 5. RPC get_stats_parrainage ──────────────────────────────────────────────
-- Retourne les gains de parrainage de l'utilisateur connecté
CREATE OR REPLACE FUNCTION get_stats_parrainage()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid            uuid := auth.uid();
  v_total          int  := 0;
  v_nb_filleuls    int  := 0;
  v_filleuls_json  jsonb := '[]';
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'non_authentifie';
  END IF;

  -- Total commissions
  SELECT COALESCE(SUM(montant_fcfa), 0)
    INTO v_total
    FROM commissions_parrainage
   WHERE parrain_id = v_uid;

  -- Nombre de filleuls distincts
  SELECT COUNT(DISTINCT filleul_id)
    INTO v_nb_filleuls
    FROM commissions_parrainage
   WHERE parrain_id = v_uid;

  -- Détail par filleul (nom anonymisé : "A***")
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'nom_anonymise', UPPER(LEFT(u.nom, 1)) || repeat('*', GREATEST(0, LENGTH(u.nom) - 1)),
        'gains_fcfa',    agg.total
      )
      ORDER BY agg.total DESC
    ),
    '[]'
  )
  INTO v_filleuls_json
  FROM (
    SELECT filleul_id, SUM(montant_fcfa) AS total
      FROM commissions_parrainage
     WHERE parrain_id = v_uid
     GROUP BY filleul_id
  ) agg
  JOIN users u ON u.id = agg.filleul_id;

  RETURN jsonb_build_object(
    'total_commissions', v_total,
    'nombre_filleuls',   v_nb_filleuls,
    'filleuls',          v_filleuls_json
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_stats_parrainage() TO authenticated;
GRANT EXECUTE ON FUNCTION generer_code_parrainage() TO authenticated;
