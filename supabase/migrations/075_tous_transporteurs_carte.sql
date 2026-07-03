-- Migration 075 — Visibilité des positions TR sur la carte
-- Tous les TRs voient les positions de leurs confrères en temps réel,
-- y compris ceux hors ligne (dernière position connue).

CREATE OR REPLACE FUNCTION tous_transporteurs_carte()
RETURNS TABLE (
  id               uuid,
  nom              text,
  type_vehicule    text,
  latitude         float8,
  longitude        float8,
  statut_connexion text,
  kyc_valide       boolean,
  note_moyenne     float8
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.nom,
    COALESCE(u.type_vehicule, 'voiture')           AS type_vehicule,
    u.latitude,
    u.longitude,
    COALESCE(u.statut_connexion, 'hors_ligne')     AS statut_connexion,
    COALESCE(u.kyc_valide, false)                  AS kyc_valide,
    COALESCE(u.note_moyenne, 5.0)                  AS note_moyenne
  FROM users u
  WHERE u.role      = 'transporteur'
    AND u.latitude  IS NOT NULL
    AND u.longitude IS NOT NULL
    AND u.id != auth.uid()
$$;

GRANT EXECUTE ON FUNCTION tous_transporteurs_carte() TO authenticated;
