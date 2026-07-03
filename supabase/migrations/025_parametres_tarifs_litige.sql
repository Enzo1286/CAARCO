-- Migration 025 : parametres_tarifs + calculer_prix + signaler_litige

-- ── 1. Colonne litige_raison sur courses ──────────────────────────────────────
ALTER TABLE courses ADD COLUMN IF NOT EXISTS litige_raison TEXT;

-- ── 2. Table de configuration des tarifs ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS parametres_tarifs (
  vehicule    TEXT PRIMARY KEY
                CHECK (vehicule IN ('moto','voiture','tricycle_camionnette','camion')),
  tarif_km    INTEGER NOT NULL,
  frais_fixes INTEGER NOT NULL DEFAULT 500,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Valeurs par défaut
INSERT INTO parametres_tarifs (vehicule, tarif_km, frais_fixes) VALUES
  ('moto',                 150, 500),
  ('voiture',              250, 500),
  ('tricycle_camionnette', 400, 500),
  ('camion',               700, 500)
ON CONFLICT (vehicule) DO NOTHING;

-- RLS : lecture publique, écriture admin uniquement
ALTER TABLE parametres_tarifs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tarifs_lecture_publique" ON parametres_tarifs
  FOR SELECT USING (true);

CREATE POLICY "tarifs_admin_ecriture" ON parametres_tarifs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ── 3. Fonction calculer_prix (lit parametres_tarifs) ────────────────────────
CREATE OR REPLACE FUNCTION calculer_prix(
  p_distance_km   float8,
  p_type_vehicule text,
  p_poids_kg      float8 DEFAULT 0,
  p_volume_m3     float8 DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_tarif_km     INTEGER;
  v_frais_fixes  INTEGER;
  v_seuil_poids  FLOAT8;
  v_seuil_volume FLOAT8;
  v_supp_poids   INTEGER;
  v_supp_volume  INTEGER;
  v_base         INTEGER;
  v_prix_brut    INTEGER;
  v_prix_final   INTEGER;
BEGIN
  SELECT tarif_km, frais_fixes
  INTO   v_tarif_km, v_frais_fixes
  FROM   parametres_tarifs
  WHERE  vehicule = p_type_vehicule;

  IF NOT FOUND THEN
    v_tarif_km    := 250;
    v_frais_fixes := 500;
  END IF;

  v_seuil_poids := CASE p_type_vehicule
    WHEN 'moto'                 THEN 20.0
    WHEN 'voiture'              THEN 100.0
    WHEN 'tricycle_camionnette' THEN 500.0
    WHEN 'camion'               THEN 5000.0
    ELSE 100.0
  END;

  v_seuil_volume := CASE p_type_vehicule
    WHEN 'moto'                 THEN 0.1
    WHEN 'voiture'              THEN 0.5
    WHEN 'tricycle_camionnette' THEN 3.0
    WHEN 'camion'               THEN 20.0
    ELSE 0.5
  END;

  v_base        := CEIL(v_frais_fixes + p_distance_km * v_tarif_km);
  v_supp_poids  := GREATEST(0, CEIL((p_poids_kg  - v_seuil_poids)  * 50));
  v_supp_volume := GREATEST(0, CEIL((p_volume_m3 - v_seuil_volume) * 500));
  v_prix_brut   := v_base + v_supp_poids + v_supp_volume;
  v_prix_final  := CEIL(v_prix_brut / 100.0) * 100;

  RETURN jsonb_build_object(
    'prix_fcfa',   v_prix_final,
    'base',        v_base,
    'supp_poids',  v_supp_poids,
    'supp_volume', v_supp_volume,
    'distance_km', ROUND(p_distance_km::numeric, 2)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION calculer_prix(float8, text, float8, float8) TO authenticated, anon;

-- ── 4. RPC signaler_litige (sécurisé — seul le client de la course) ──────────
CREATE OR REPLACE FUNCTION signaler_litige(
  p_course_id UUID,
  p_raison    TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE courses
  SET    statut        = 'litige',
         litige_raison = p_raison,
         updated_at    = NOW()
  WHERE  id        = p_course_id
    AND  client_id = auth.uid()
    AND  statut IN ('livree', 'terminee', 'en_cours', 'en_route');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course introuvable ou statut invalide pour signaler un litige';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION signaler_litige(UUID, TEXT) TO authenticated;
