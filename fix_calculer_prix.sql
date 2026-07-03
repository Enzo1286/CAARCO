DROP FUNCTION IF EXISTS public.calculer_prix(numeric, text, numeric, numeric, boolean);

CREATE OR REPLACE FUNCTION public.calculer_prix(
  p_distance_km  NUMERIC,
  p_type_vehicule TEXT,
  p_poids_kg     NUMERIC DEFAULT 0,
  p_volume_m3    NUMERIC DEFAULT 0,
  p_est_nuit     BOOLEAN DEFAULT FALSE
) RETURNS jsonb
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_tarif_km     INTEGER;
  v_frais_fixes  INTEGER;
  v_seuil_poids  INTEGER;
  v_seuil_volume NUMERIC;
  v_maj_nuit     NUMERIC;
  v_dist         NUMERIC;
  v_base         NUMERIC;
  v_supp_poids   NUMERIC;
  v_supp_volume  NUMERIC;
  v_sous_total   NUMERIC;
  v_prix         INTEGER;
BEGIN
  v_dist := GREATEST(p_distance_km, 0.5);

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

  IF NOT FOUND THEN
    CASE p_type_vehicule
      WHEN 'moto' THEN
        v_tarif_km := 150; v_frais_fixes := 500;
      WHEN 'voiture' THEN
        v_tarif_km := 250; v_frais_fixes := 1000;
      WHEN 'camionnette' THEN
        v_tarif_km := 400; v_frais_fixes := 1500;
      WHEN 'tricycle' THEN
        v_tarif_km := 400; v_frais_fixes := 1000;
      WHEN 'tricycle_camionnette' THEN
        v_tarif_km := 400; v_frais_fixes := 1500;
      WHEN 'camion' THEN
        v_tarif_km := 1000; v_frais_fixes := 10000;
      ELSE
        v_tarif_km := 250; v_frais_fixes := 1000;
    END CASE;
  END IF;

  SELECT COALESCE(
    (SELECT valeur::NUMERIC FROM configurations_systeme WHERE cle = 'majoration_nuit_pct' LIMIT 1),
    0.20
  ) INTO v_maj_nuit;

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
  v_sous_total  := v_base + v_supp_poids + v_supp_volume;

  IF p_est_nuit THEN
    v_sous_total := v_sous_total * (1 + v_maj_nuit);
  END IF;

  v_prix := CEIL(v_sous_total / 100.0) * 100;

  RETURN jsonb_build_object(
    'total',       v_prix,
    'prix_fcfa',   v_prix,
    'base',        CEIL(v_base)::INTEGER,
    'supp_poids',  CEIL(v_supp_poids)::INTEGER,
    'supp_volume', CEIL(v_supp_volume)::INTEGER,
    'distance_km', v_dist,
    'is_nuit',     p_est_nuit,
    'maj_nuit_pct', CASE WHEN p_est_nuit THEN v_maj_nuit ELSE 0 END
  );
END;
$$;
