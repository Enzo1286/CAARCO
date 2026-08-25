# 🚀 HANDOFF BACKEND SUPABASE — SÉPARATION DES 5 VÉHICULES & TARIFS (SESSION 37)
**Date :** 22 Août 2026  
**Auteur :** Antigravity (Frontend Lead)  
**Destinataire :** Claude (Backend / Supabase Lead)  

---

## 🎯 OBJET
Le frontend a officiellement séparé **Tricycle** et **Camionnette** en 2 catégories distinctes avec leurs modèles 3D, sélecteurs, seuils et tarification dédiée :
1. 🛵 **Moto (125cc)** : 150 XAF/km | Frais fixes: 500 XAF | 20 kg | 0.1 m³
2. 🚗 **Voiture (Berline)** : 350 XAF/km | Frais fixes: 500 XAF | 100 kg | 0.5 m³
3. 🛺 **Tricycle (Cargo / Triporteur)** : **550 XAF/km** | Frais fixes: 1 500 XAF | 350 kg | 1.8 m³
4. 🛻 **Camionnette (Pick-up / Suzuki Carry)** : **600 XAF/km** | Frais fixes: 2 500 XAF | 800 kg | 4.0 m³
5. 🚛 **Camion (Grand Déménagement)** : **1 000 XAF/km** | Frais fixes: 10 000 XAF | 5 000 kg | 20.0 m³

Le frontend (`AccueilScreen`, `TrajetScreen`, `AttenteScreen`, `ConfigTarifsScreen`, `prix.js`, `i18n`) est **100% à jour**.  
Ce document fournit le script SQL de migration complet et les consignes pour aligner Supabase.

---

## 📜 1. SCRIPT DE MIGRATION SQL SUPABASE (À EXÉCUTER DANS LE SQL EDITOR)

```sql
-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 096 : SÉPARATION TRICYCLE (550 XAF/KM) & CAMIONNETTE (600 XAF/KM)
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Élargissement des contraintes CHECK sur les types de véhicules
-- ─────────────────────────────────────────────────────────────────────────────

-- Table users
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_type_vehicule_check;
ALTER TABLE public.users ADD CONSTRAINT users_type_vehicule_check
  CHECK (type_vehicule IN ('moto', 'voiture', 'tricycle', 'camionnette', 'camion', 'tricycle_camionnette'));

-- Table vehicules
ALTER TABLE public.vehicules DROP CONSTRAINT IF EXISTS vehicules_categorie_check;
ALTER TABLE public.vehicules ADD CONSTRAINT vehicules_categorie_check
  CHECK (categorie IN ('moto', 'voiture', 'tricycle', 'camionnette', 'camion', 'tricycle_camionnette'));

-- Table courses
ALTER TABLE public.courses DROP CONSTRAINT IF EXISTS courses_type_vehicule_check;
ALTER TABLE public.courses DROP CONSTRAINT IF EXISTS courses_categorie_vehicule_check;

ALTER TABLE public.courses ADD CONSTRAINT courses_type_vehicule_check
  CHECK (type_vehicule IN ('moto', 'voiture', 'tricycle', 'camionnette', 'camion', 'tricycle_camionnette'));

ALTER TABLE public.courses ADD CONSTRAINT courses_categorie_vehicule_check
  CHECK (categorie_vehicule IN ('moto', 'voiture', 'tricycle', 'camionnette', 'camion', 'tricycle_camionnette'));


-- 2. Mise à jour de la table parametres_tarifs avec les 5 véhicules
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.parametres_tarifs (vehicule, tarif_km, frais_fixes, poids_max_kg, volume_max_m3, updated_at)
VALUES
  ('moto',                 150,   500,    20,  0.10, NOW()),
  ('voiture',              350,   500,   100,  0.50, NOW()),
  ('tricycle',             550,  1500,   350,  1.80, NOW()),
  ('camionnette',          600,  2500,   800,  4.00, NOW()),
  ('camion',              1000, 10000,  5000, 20.00, NOW()),
  ('tricycle_camionnette', 550,  2000,   500,  3.00, NOW()) -- fallback rétro-compatibilité
ON CONFLICT (vehicule) DO UPDATE SET
  tarif_km      = EXCLUDED.tarif_km,
  frais_fixes   = EXCLUDED.frais_fixes,
  poids_max_kg  = EXCLUDED.poids_max_kg,
  volume_max_m3 = EXCLUDED.volume_max_m3,
  updated_at    = NOW();


-- 3. Mise à jour de la fonction RPC public.calculer_prix
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.calculer_prix(
  p_distance_km   NUMERIC,
  p_type_vehicule TEXT,
  p_poids_kg      NUMERIC DEFAULT 0,
  p_volume_m3     NUMERIC DEFAULT 0,
  p_est_nuit      BOOLEAN DEFAULT FALSE
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER
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

  -- Lecture des tarifs configurés en base
  SELECT tarif_km, frais_fixes, poids_max_kg, volume_max_m3
  INTO   v_tarif_km, v_frais_fixes, v_seuil_poids, v_seuil_volume
  FROM   public.parametres_tarifs
  WHERE  vehicule = p_type_vehicule;

  -- Fallbacks stricts si non trouvés
  IF NOT FOUND THEN
    CASE p_type_vehicule
      WHEN 'moto' THEN
        v_tarif_km := 150; v_frais_fixes := 500;   v_seuil_poids := 20;   v_seuil_volume := 0.1;
      WHEN 'voiture' THEN
        v_tarif_km := 350; v_frais_fixes := 500;   v_seuil_poids := 100;  v_seuil_volume := 0.5;
      WHEN 'tricycle' THEN
        v_tarif_km := 550; v_frais_fixes := 1500;  v_seuil_poids := 350;  v_seuil_volume := 1.8;
      WHEN 'camionnette' THEN
        v_tarif_km := 600; v_frais_fixes := 2500;  v_seuil_poids := 800;  v_seuil_volume := 4.0;
      WHEN 'camion' THEN
        v_tarif_km := 1000; v_frais_fixes := 10000; v_seuil_poids := 5000; v_seuil_volume := 20.0;
      ELSE
        v_tarif_km := 350; v_frais_fixes := 500;   v_seuil_poids := 100;  v_seuil_volume := 0.5;
    END CASE;
  END IF;

  -- Majoration nuit (22h -> 5h)
  SELECT COALESCE(
    (SELECT valeur::NUMERIC FROM public.configurations_systeme WHERE cle = 'majoration_nuit_pct' LIMIT 1),
    0.20
  ) INTO v_maj_nuit;

  v_base        := v_frais_fixes + (v_dist * v_tarif_km);
  v_supp_poids  := GREATEST(0, p_poids_kg  - COALESCE(v_seuil_poids, 100))  * 50;
  v_supp_volume := GREATEST(0, p_volume_m3 - COALESCE(v_seuil_volume, 0.5)) * 500;
  v_sous_total  := v_base + v_supp_poids + v_supp_volume;

  IF p_est_nuit THEN
    v_sous_total := v_sous_total * (1 + v_maj_nuit);
  END IF;

  -- Arrondi centaine supérieure (XAF entiers)
  v_prix := CEIL(v_sous_total / 100.0) * 100;

  RETURN jsonb_build_object(
    'total',        v_prix,
    'prix_fcfa',    v_prix,
    'base',         CEIL(v_base)::INTEGER,
    'supp_poids',   CEIL(v_supp_poids)::INTEGER,
    'supp_volume',  CEIL(v_supp_volume)::INTEGER,
    'distance_km',  v_dist,
    'is_nuit',      p_est_nuit,
    'maj_nuit_pct', CASE WHEN p_est_nuit THEN v_maj_nuit ELSE 0 END
  );
END;
$$;


-- 4. Élargissement de la matrice de compatibilité des candidatures
-- ─────────────────────────────────────────────────────────────────────────────
-- Règle :
-- Un TR 'moto'        -> candidate aux courses 'moto'
-- Un TR 'voiture'     -> candidate aux courses 'voiture', 'moto'
-- Un TR 'tricycle'    -> candidate aux courses 'tricycle', 'moto'
-- Un TR 'camionnette' -> candidate aux courses 'camionnette', 'tricycle', 'voiture', 'moto'
-- Un TR 'camion'      -> candidate aux courses 'camion', 'camionnette', 'tricycle'
```

---

## ⚡ 2. EDGE FUNCTIONS À VÉRIFIER
1. **`tarifer-course-programmee`** : Vérifier qu'elle appelle bien la RPC `calculer_prix` avec les nouveaux paramètres de véhicule (`tricycle` et `camionnette`).
2. **`match-transporter`** : S'assurer que le filtrage par type de véhicule prend en compte `tricycle` et `camionnette`.

---

## ✅ ÉTAT DE VALIDATION FRONTEND
- `npm test` : **8/8 tests passés avec succès**.
- Rendu visuel validé (icônes et modèles 3D détourés transparents, boutons compacts, carrousel horizontal 5 items, écran d'attente animé en continu).
