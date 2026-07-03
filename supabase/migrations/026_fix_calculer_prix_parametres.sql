-- Migration 026 : unifier calculer_prix pour lire depuis parametres_tarifs
-- Supprime la version float8 créée en 025 et met à jour la version numeric
-- pour qu'elle lise les tarifs depuis parametres_tarifs.

-- Supprimer la version float8 (créée par 025, incompatible avec le client)
DROP FUNCTION IF EXISTS calculer_prix(float8, text, float8, float8);

-- Remplacer la version numeric (celle que l'app utilise) pour lire depuis la table
CREATE OR REPLACE FUNCTION calculer_prix(
  p_distance_km   numeric,
  p_type_vehicule text,
  p_poids_kg      numeric DEFAULT 0,
  p_volume_m3     numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_tarif_km     INTEGER;
  v_frais_fixes  INTEGER;
  v_seuil_poids  INTEGER;
  v_seuil_volume NUMERIC;
  v_dist         NUMERIC;
  v_base         NUMERIC;
  v_supp_poids   NUMERIC;
  v_supp_volume  NUMERIC;
  v_prix         INTEGER;
BEGIN
  v_dist := GREATEST(p_distance_km, 0.5);

  -- Lire le tarif_km depuis parametres_tarifs (admin peut le modifier)
  SELECT tarif_km, frais_fixes
  INTO   v_tarif_km, v_frais_fixes
  FROM   parametres_tarifs
  WHERE  vehicule = CASE p_type_vehicule
    WHEN 'moto'                 THEN 'moto'
    WHEN 'voiture'              THEN 'voiture'
    WHEN 'camionnette'          THEN 'tricycle_camionnette'
    WHEN 'tricycle'             THEN 'tricycle_camionnette'
    WHEN 'tricycle_camionnette' THEN 'tricycle_camionnette'
    WHEN 'camion'               THEN 'camion'
    ELSE 'voiture'
  END;

  -- Fallback hardcodé si la table est vide
  IF NOT FOUND THEN
    CASE p_type_vehicule
      WHEN 'moto' THEN
        v_tarif_km := 150; v_frais_fixes := 500;
      WHEN 'voiture' THEN
        v_tarif_km := 250; v_frais_fixes := 500;
      WHEN 'camionnette' THEN
        v_tarif_km := 400; v_frais_fixes := 500;
      WHEN 'tricycle' THEN
        v_tarif_km := 400; v_frais_fixes := 500;
      WHEN 'tricycle_camionnette' THEN
        v_tarif_km := 400; v_frais_fixes := 500;
      WHEN 'camion' THEN
        v_tarif_km := 700; v_frais_fixes := 500;
      ELSE
        RAISE EXCEPTION 'Type de véhicule invalide: %', p_type_vehicule;
    END CASE;
  END IF;

  -- Seuils de poids/volume (invariants métier, pas modifiables en V1)
  CASE p_type_vehicule
    WHEN 'moto' THEN
      v_seuil_poids := 20; v_seuil_volume := 0.1;
    WHEN 'voiture' THEN
      v_seuil_poids := 100; v_seuil_volume := 0.5;
    WHEN 'camionnette' THEN
      v_seuil_poids := 500; v_seuil_volume := 3.0;
    WHEN 'tricycle' THEN
      v_seuil_poids := 500; v_seuil_volume := 3.0;
    WHEN 'tricycle_camionnette' THEN
      v_seuil_poids := 500; v_seuil_volume := 3.0;
    WHEN 'camion' THEN
      v_seuil_poids := 5000; v_seuil_volume := 20.0;
    ELSE
      v_seuil_poids := 100; v_seuil_volume := 0.5;
  END CASE;

  v_base        := v_frais_fixes + v_dist * v_tarif_km;
  v_supp_poids  := GREATEST(0, p_poids_kg  - v_seuil_poids)  * 50;
  v_supp_volume := GREATEST(0, p_volume_m3 - v_seuil_volume) * 500;
  v_prix        := CEIL((v_base + v_supp_poids + v_supp_volume) / 100.0) * 100;

  RETURN jsonb_build_object(
    'total',       v_prix,
    'prix_fcfa',   v_prix,
    'base',        CEIL(v_base)::INTEGER,
    'supp_poids',  CEIL(v_supp_poids)::INTEGER,
    'supp_volume', CEIL(v_supp_volume)::INTEGER,
    'distance_km', v_dist
  );
END;
$$;

GRANT EXECUTE ON FUNCTION calculer_prix(numeric, text, numeric, numeric) TO authenticated, anon;
