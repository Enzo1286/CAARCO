-- Migration 012 : catégories véhicule + transporteurs proximité

-- ── 1. Colonne categorie sur vehicules ────────────────────────────────────────
ALTER TABLE vehicules
  ADD COLUMN IF NOT EXISTS categorie text
  CHECK (categorie IN ('moto','voiture','tricycle_camionnette','camion'));

UPDATE vehicules SET categorie = 'moto'                 WHERE type = 'moto';
UPDATE vehicules SET categorie = 'voiture'              WHERE type = 'voiture';
UPDATE vehicules SET categorie = 'tricycle_camionnette' WHERE type IN ('tricycle','camionnette');
UPDATE vehicules SET categorie = 'camion'               WHERE type LIKE 'camion%';

-- ── 2. Colonne categorie_vehicule sur courses ─────────────────────────────────
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS categorie_vehicule text
  CHECK (categorie_vehicule IN ('moto','voiture','tricycle_camionnette','camion'));

UPDATE courses SET categorie_vehicule = 'moto'                 WHERE type_vehicule = 'moto';
UPDATE courses SET categorie_vehicule = 'voiture'              WHERE type_vehicule = 'voiture';
UPDATE courses SET categorie_vehicule = 'tricycle_camionnette' WHERE type_vehicule IN ('tricycle','camionnette');
UPDATE courses SET categorie_vehicule = 'camion'               WHERE type_vehicule LIKE 'camion%';

-- ── 3. Fonction haversine (distance en km entre deux coordonnées GPS) ─────────
CREATE OR REPLACE FUNCTION distance_km(
  lat1 float8, lng1 float8,
  lat2 float8, lng2 float8
)
RETURNS float8
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT 6371 * acos(
    LEAST(1.0,
      cos(radians(lat1)) * cos(radians(lat2)) *
      cos(radians(lng2) - radians(lng1)) +
      sin(radians(lat1)) * sin(radians(lat2))
    )
  )
$$;

-- ── 4. RPC transporteurs_proximite ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION transporteurs_proximite(
  client_lat  float8,
  client_lng  float8,
  rayon_km    float8 DEFAULT 15
)
RETURNS TABLE (
  id            uuid,
  nom           text,
  photo_url     text,
  latitude      float8,
  longitude     float8,
  type_vehicule text,
  categorie     text,
  note_moyenne  float8,
  nombre_courses int
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    u.id,
    u.nom,
    u.photo_url,
    u.latitude,
    u.longitude,
    COALESCE(v.type, 'voiture')                AS type_vehicule,
    COALESCE(v.categorie, 'voiture')           AS categorie,
    COALESCE(u.note_moyenne, 5.0)              AS note_moyenne,
    COALESCE(u.nombre_courses, 0)              AS nombre_courses
  FROM users u
  LEFT JOIN vehicules v
    ON v.transporteur_id = u.id AND v.valide = true
  WHERE u.role             = 'transporteur'
    AND u.statut_connexion = 'en_ligne'
    AND u.latitude  IS NOT NULL
    AND u.longitude IS NOT NULL
    AND distance_km(client_lat, client_lng, u.latitude, u.longitude) <= rayon_km
$$;

GRANT EXECUTE ON FUNCTION transporteurs_proximite(float8, float8, float8) TO authenticated, anon;

-- ── 5. Realtime sur la table users ───────────────────────────────────────────
-- Permet au client de recevoir les mises à jour de position des transporteurs
ALTER PUBLICATION supabase_realtime ADD TABLE users;
