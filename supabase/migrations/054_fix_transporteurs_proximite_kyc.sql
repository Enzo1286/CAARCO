-- Migration 054 : transporteurs_proximite — ajout kyc_valide + SECURITY DEFINER
-- Raison : la RPC créée en 012 ne retournait pas kyc_valide (colonne ajoutée en 049).
-- Sans SECURITY DEFINER la RPC était bloquée par le RLS "users_own_data" côté clients.

CREATE OR REPLACE FUNCTION transporteurs_proximite(
  client_lat  float8,
  client_lng  float8,
  rayon_km    float8 DEFAULT 15
)
RETURNS TABLE (
  id              uuid,
  nom             text,
  photo_url       text,
  latitude        float8,
  longitude       float8,
  type_vehicule   text,
  categorie       text,
  note_moyenne    float8,
  nombre_courses  int,
  kyc_valide      boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.nom,
    u.photo_url,
    u.latitude,
    u.longitude,
    COALESCE(u.type_vehicule, 'voiture')            AS type_vehicule,
    COALESCE(u.categorie_vehicule, u.type_vehicule, 'voiture') AS categorie,
    COALESCE(u.note_moyenne, 5.0)                   AS note_moyenne,
    COALESCE(u.nombre_courses, 0)                   AS nombre_courses,
    COALESCE(u.kyc_valide, false)                   AS kyc_valide
  FROM users u
  WHERE u.role             = 'transporteur'
    AND u.statut_connexion = 'en_ligne'
    AND u.latitude  IS NOT NULL
    AND u.longitude IS NOT NULL
    AND distance_km(client_lat, client_lng, u.latitude, u.longitude) <= rayon_km
$$;

GRANT EXECUTE ON FUNCTION transporteurs_proximite(float8, float8, float8) TO authenticated, anon;
