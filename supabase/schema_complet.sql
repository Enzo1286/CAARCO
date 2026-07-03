-- ══════════════════════════════════════════════════════════════════════════════
-- CAARCO — SCHÉMA SUPABASE COMPLET (version consolidée)
-- Généré le 2026-05-30 — Idempotent (peut être rejoué sur projet vide)
-- Couvre les 61 migrations appliquées (002 → 061)
-- ══════════════════════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════════════════════
-- 0. EXTENSIONS
-- ══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS pg_cron;      -- Supabase : activer dans Database > Extensions


-- ══════════════════════════════════════════════════════════════════════════════
-- 1. FONCTION is_admin() — définie en premier (utilisée dans les RLS)
-- ══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
SET row_security = off
AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin');
$$;
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;


-- ══════════════════════════════════════════════════════════════════════════════
-- 2. TABLES
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 2.1 users ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id                     UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nom                    TEXT        NOT NULL,
  telephone              TEXT        NOT NULL UNIQUE,
  role                   TEXT        NOT NULL CHECK (role IN ('client', 'transporteur', 'admin')),
  statut                 TEXT        NOT NULL DEFAULT 'actif'
                                     CHECK (statut IN ('actif','suspendu','banni','kyc_en_attente')),
  note_moyenne           DECIMAL(3,2) DEFAULT 5.00,
  nombre_courses         INTEGER     DEFAULT 0,
  points                 INTEGER     DEFAULT 0,
  code_parrainage        TEXT        UNIQUE,
  parrain_id             UUID        REFERENCES public.users(id),
  pseudo                 TEXT,
  langue                 TEXT        DEFAULT 'fr',
  statut_connexion       TEXT        DEFAULT 'hors_ligne',
  photo_url              TEXT,
  latitude               FLOAT8,
  longitude              FLOAT8,
  derniere_position      TIMESTAMPTZ,
  expo_push_token        TEXT,
  type_vehicule          TEXT        CHECK (type_vehicule IN ('moto','voiture','tricycle_camionnette','camion')),
  kyc_valide             BOOLEAN     NOT NULL DEFAULT FALSE,
  kyc_approuve_le        TIMESTAMPTZ,
  top_tr_mois            BOOLEAN     DEFAULT FALSE,
  rang_tr_mois           INTEGER,
  is_top_tr_mois         BOOLEAN     DEFAULT FALSE,
  statut_vip             BOOLEAN     DEFAULT FALSE,
  est_vip                BOOLEAN     DEFAULT FALSE,
  bonus_volume_mois_fcfa INTEGER     DEFAULT 0,
  pack_actuel            TEXT        DEFAULT 'gratuit'
                                     CHECK (pack_actuel IN ('gratuit','standard','pro','elite')),
  pack_expire_at         TIMESTAMPTZ,
  created_at             TIMESTAMPTZ DEFAULT NOW(),
  updated_at             TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.2 vehicules ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vehicules (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id  UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type             TEXT        NOT NULL,
  categorie        TEXT        CHECK (categorie IN ('moto','voiture','tricycle_camionnette','camion')),
  immatriculation  TEXT,
  valide           BOOLEAN     DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.3 courses ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.courses (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id           UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  transporteur_id     UUID        REFERENCES public.users(id),
  statut              TEXT        NOT NULL DEFAULT 'en_attente'
                                  CHECK (statut IN (
                                    'en_attente','acceptee','en_cours',
                                    'terminee','annulee','expiree','livree','litige'
                                  )),
  type_vehicule       TEXT,
  categorie_vehicule  TEXT        CHECK (categorie_vehicule IN ('moto','voiture','tricycle_camionnette','camion')),
  depart_lat          FLOAT8      NOT NULL,
  depart_lng          FLOAT8      NOT NULL,
  arrivee_lat         FLOAT8      NOT NULL,
  arrivee_lng         FLOAT8      NOT NULL,
  depart_adresse      TEXT,
  arrivee_adresse     TEXT,
  distance_km         FLOAT8      NOT NULL,
  prix_fcfa           INTEGER     NOT NULL,
  poids_kg            NUMERIC(6,2),
  nb_colis            INTEGER     DEFAULT 1,
  dimension_l         NUMERIC(5,1),
  dimension_l2        NUMERIC(5,1),
  dimension_h         NUMERIC(5,1),
  categorie           TEXT,
  photos_colis        TEXT[]      DEFAULT '{}',
  mode_tarif          TEXT        DEFAULT 'forfait',
  otp_livraison       CHAR(4),
  statut_paiement     TEXT        DEFAULT 'non_paye',
  litige_raison       TEXT,
  expires_at          TIMESTAMPTZ,
  methode_paiement    TEXT        NOT NULL DEFAULT 'online'
                                  CHECK (methode_paiement IN ('online','wallet','especes')),
  code_promo          TEXT,
  completed_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.4 messages ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id       UUID        REFERENCES public.courses(id) ON DELETE CASCADE,
  expediteur_id   UUID        NOT NULL REFERENCES public.users(id),
  destinataire_id UUID        REFERENCES public.users(id),
  contenu         TEXT,
  type            TEXT        NOT NULL DEFAULT 'texte'
                              CHECK (type IN ('texte','image','lien','carte')),
  image_url       TEXT,
  lu              BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.5 paiements ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.paiements (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id            UUID        NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  client_id            UUID        NOT NULL REFERENCES public.users(id),
  montant_fcfa         INTEGER     NOT NULL,
  methode              TEXT        NOT NULL
                                   CHECK (methode IN ('orange_money','mtn_momo','wallet')),
  numero_mobile        TEXT,
  statut               TEXT        NOT NULL DEFAULT 'en_attente'
                                   CHECK (statut IN (
                                     'en_attente','initie','valide',
                                     'sequestre','libere','rembourse','echec'
                                   )),
  reference            TEXT,
  moneroo_payment_id   TEXT,
  moneroo_checkout_url TEXT,
  libere_at            TIMESTAMPTZ,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.6 wallets ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wallets (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  solde_fcfa INTEGER     NOT NULL DEFAULT 0 CHECK (solde_fcfa >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.7 transactions_wallet ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transactions_wallet (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id            UUID        NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  type                 TEXT        NOT NULL,
  montant_fcfa         INTEGER     NOT NULL CHECK (montant_fcfa > 0),
  methode              TEXT,
  statut               TEXT        DEFAULT 'en_attente',
  reference            TEXT,
  moneroo_payment_id   TEXT,
  moneroo_checkout_url TEXT,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.8 transactions_points ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transactions_points (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  montant    INTEGER     NOT NULL,
  motif      TEXT        NOT NULL,
  course_id  UUID        REFERENCES public.courses(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.9 avis ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.avis (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id     UUID        NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  auteur_id     UUID        NOT NULL REFERENCES public.users(id),
  cible_id      UUID        NOT NULL REFERENCES public.users(id),
  note_globale  NUMERIC(2,1) NOT NULL CHECK (note_globale BETWEEN 1 AND 5),
  ponctualite   INTEGER     CHECK (ponctualite BETWEEN 1 AND 5),
  soin_colis    INTEGER     CHECK (soin_colis BETWEEN 1 AND 5),
  communication INTEGER     CHECK (communication BETWEEN 1 AND 5),
  proprete      INTEGER     CHECK (proprete BETWEEN 1 AND 5),
  commentaire   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (course_id, auteur_id)
);

-- ── 2.10 retraits ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.retraits (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  montant_fcfa    INTEGER     NOT NULL CHECK (montant_fcfa >= 1000),
  methode         TEXT        NOT NULL CHECK (methode IN ('orange_money','mtn_momo')),
  numero_mobile   TEXT        NOT NULL,
  statut          TEXT        NOT NULL DEFAULT 'en_attente'
                              CHECK (statut IN ('en_attente','traite','refuse')),
  note_admin      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2.11 candidatures ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.candidatures (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id       UUID        NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  transporteur_id UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  statut          TEXT        NOT NULL DEFAULT 'propose'
                              CHECK (statut IN ('propose','accepte','refuse','annule','acceptee')),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (course_id, transporteur_id)
);

-- ── 2.12 transporteurs_kyc ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transporteurs_kyc (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  type_vehicule    TEXT        NOT NULL
                               CHECK (type_vehicule IN (
                                 'MOTO_TAXI','TRICYCLE','PICK_UP',
                                 'CAMION_LEGER','CAMION_LOURD','CAMIONNETTE'
                               )),
  immatriculation  TEXT,
  cni_url          TEXT,
  permis_url       TEXT,
  vehicule_url     TEXT[],
  statut_kyc       TEXT        DEFAULT 'en_attente'
                               CHECK (statut_kyc IN (
                                 'en_attente','approuve','rejete','infos_manquantes'
                               )),
  motif_rejet      TEXT,
  valide_par       UUID        REFERENCES public.users(id),
  valide_at        TIMESTAMPTZ,
  cni_delivrance   DATE,
  cni_expiration   DATE,
  permis_delivrance DATE,
  permis_expiration DATE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.13 positions_gps ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.positions_gps (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  course_id  UUID        REFERENCES public.courses(id),
  lat        FLOAT8      NOT NULL,
  lng        FLOAT8      NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.14 parametres_tarifs ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.parametres_tarifs (
  vehicule    TEXT        PRIMARY KEY
                          CHECK (vehicule IN ('moto','voiture','tricycle_camionnette','camion')),
  tarif_km    INTEGER     NOT NULL,
  frais_fixes INTEGER     NOT NULL DEFAULT 500,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.15 configurations_systeme ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.configurations_systeme (
  cle        TEXT        PRIMARY KEY,
  valeur     TEXT        NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID        REFERENCES public.users(id)
);

-- ── 2.16 commissions_parrainage ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.commissions_parrainage (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  parrain_id   UUID        NOT NULL REFERENCES public.users(id),
  filleul_id   UUID        NOT NULL REFERENCES public.users(id),
  course_id    UUID        NOT NULL REFERENCES public.courses(id),
  montant_fcfa INTEGER     NOT NULL CHECK (montant_fcfa > 0),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.17 abonnements_transporteurs ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.abonnements_transporteurs (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pack            TEXT        NOT NULL CHECK (pack IN ('standard','pro','elite')),
  periode         TEXT        NOT NULL CHECK (periode IN ('mensuel','annuel')),
  prix_fcfa       INTEGER     NOT NULL,
  statut          TEXT        NOT NULL DEFAULT 'actif'
                              CHECK (statut IN ('actif','expire','annule','en_attente')),
  debut_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fin_at          TIMESTAMPTZ NOT NULL,
  moneroo_id      TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2.18 recompenses_client (table active — client_id schema) ─────────────────
CREATE TABLE IF NOT EXISTS public.recompenses_client (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id        UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  jalon            INTEGER     NOT NULL,  -- 10 | 20 | 30 | 50 | 100
  recompense_type  TEXT        NOT NULL,  -- 'wallet_credit' | 'vip'
  recompense_valeur INTEGER,
  statut           TEXT        NOT NULL DEFAULT 'en_attente'
                               CHECK (statut IN ('en_attente','revele')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revele_le        TIMESTAMPTZ,
  UNIQUE (client_id, jalon)
);

-- ── 2.19 jalons_client (ancienne table — conservée vide, ne pas modifier) ─────
CREATE TABLE IF NOT EXISTS public.jalons_client (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id        UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  jalon            INTEGER     NOT NULL,
  recompense_type  TEXT        NOT NULL,
  recompense_valeur INTEGER,
  statut           TEXT        NOT NULL DEFAULT 'en_attente'
                               CHECK (statut IN ('en_attente','revele')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revele_at        TIMESTAMPTZ,
  UNIQUE (client_id, jalon)
);

-- ── 2.20 classement_mensuel_tr ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.classement_mensuel_tr (
  user_id      UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mois         DATE        NOT NULL,
  rang         INTEGER     NOT NULL,
  nb_courses   INTEGER     NOT NULL DEFAULT 0,
  note_moyenne DECIMAL(3,2) DEFAULT 0,
  is_top10     BOOLEAN     NOT NULL DEFAULT FALSE,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, mois)
);


-- ══════════════════════════════════════════════════════════════════════════════
-- 3. STORAGE BUCKETS
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars',       'avatars',       true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('bagages',       'bagages',       false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc_documents', 'kyc_documents', false)
ON CONFLICT (id) DO NOTHING;

-- Policies storage : avatars (publics)
DROP POLICY IF EXISTS "avatars_lecture_publique" ON storage.objects;
CREATE POLICY "avatars_lecture_publique" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_upload" ON storage.objects;
CREATE POLICY "avatars_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
CREATE POLICY "avatars_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Policies storage : bagages (privé — client de la course)
DROP POLICY IF EXISTS "bagages_upload" ON storage.objects;
CREATE POLICY "bagages_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'bagages'
    AND auth.uid() IS NOT NULL
  );

DROP POLICY IF EXISTS "bagages_lecture" ON storage.objects;
CREATE POLICY "bagages_lecture" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'bagages'
    AND auth.uid() IS NOT NULL
  );

-- Policies storage : kyc_documents (privé — TR concerné + admin)
DROP POLICY IF EXISTS "kyc_upload" ON storage.objects;
CREATE POLICY "kyc_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'kyc_documents'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

DROP POLICY IF EXISTS "kyc_lecture" ON storage.objects;
CREATE POLICY "kyc_lecture" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kyc_documents'
    AND (
      (storage.foldername(name))[1] = auth.uid()::TEXT
      OR is_admin()
    )
  );


-- ══════════════════════════════════════════════════════════════════════════════
-- 4. FONCTIONS & RPCs
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 4.1 Haversine (distance GPS en km) ────────────────────────────────────────
CREATE OR REPLACE FUNCTION distance_km(lat1 FLOAT8, lng1 FLOAT8, lat2 FLOAT8, lng2 FLOAT8)
RETURNS FLOAT8
LANGUAGE sql IMMUTABLE
AS $$
  SELECT 6371 * acos(
    LEAST(1.0,
      cos(radians(lat1)) * cos(radians(lat2)) *
      cos(radians(lng2) - radians(lng1)) +
      sin(radians(lat1)) * sin(radians(lat2))
    )
  )
$$;

-- ── 4.2 calculer_prix (lit parametres_tarifs) ─────────────────────────────────
CREATE OR REPLACE FUNCTION calculer_prix(
  p_distance_km   FLOAT8,
  p_type_vehicule TEXT,
  p_poids_kg      FLOAT8 DEFAULT 0,
  p_volume_m3     FLOAT8 DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_tarif_km    INTEGER;  v_frais_fixes INTEGER;
  v_seuil_poids FLOAT8;   v_seuil_vol   FLOAT8;
  v_supp_poids  INTEGER;  v_supp_vol    INTEGER;
  v_base        INTEGER;  v_prix_final  INTEGER;
  v_heure       INTEGER := EXTRACT(HOUR FROM NOW());
  v_nuit        BOOLEAN;
  v_majoration  NUMERIC;
  v_debut_nuit  INTEGER;  v_fin_nuit    INTEGER;
BEGIN
  SELECT tarif_km, frais_fixes
    INTO v_tarif_km, v_frais_fixes
    FROM public.parametres_tarifs
   WHERE vehicule = p_type_vehicule;

  IF NOT FOUND THEN v_tarif_km := 250; v_frais_fixes := 500; END IF;

  v_seuil_poids := CASE p_type_vehicule
    WHEN 'moto'                 THEN 20.0
    WHEN 'voiture'              THEN 100.0
    WHEN 'tricycle_camionnette' THEN 500.0
    WHEN 'camion'               THEN 5000.0
    ELSE 100.0 END;

  v_seuil_vol := CASE p_type_vehicule
    WHEN 'moto'                 THEN 0.1
    WHEN 'voiture'              THEN 0.5
    WHEN 'tricycle_camionnette' THEN 3.0
    WHEN 'camion'               THEN 20.0
    ELSE 0.5 END;

  v_base       := CEIL(v_frais_fixes + p_distance_km * v_tarif_km);
  v_supp_poids := GREATEST(0, CEIL((p_poids_kg  - v_seuil_poids) * 50));
  v_supp_vol   := GREATEST(0, CEIL((p_volume_m3 - v_seuil_vol)   * 500));

  -- Majoration nuit (paramétrable via configurations_systeme)
  SELECT COALESCE(valeur::NUMERIC, 0.20) INTO v_majoration
    FROM public.configurations_systeme WHERE cle = 'majoration_nuit_pct';
  SELECT COALESCE(valeur::INTEGER, 20) INTO v_debut_nuit
    FROM public.configurations_systeme WHERE cle = 'heure_debut_nuit';
  SELECT COALESCE(valeur::INTEGER, 5) INTO v_fin_nuit
    FROM public.configurations_systeme WHERE cle = 'heure_fin_nuit';

  v_nuit := (v_heure >= v_debut_nuit OR v_heure < v_fin_nuit);

  v_prix_final := CEIL((v_base + v_supp_poids + v_supp_vol) *
                  (CASE WHEN v_nuit THEN 1 + v_majoration ELSE 1 END) / 100.0) * 100;

  RETURN jsonb_build_object(
    'prix_fcfa',     v_prix_final,
    'base',          v_base,
    'supp_poids',    v_supp_poids,
    'supp_volume',   v_supp_vol,
    'distance_km',   ROUND(p_distance_km::NUMERIC, 2),
    'majoration_nuit', v_nuit
  );
END;
$$;
GRANT EXECUTE ON FUNCTION calculer_prix(FLOAT8, TEXT, FLOAT8, FLOAT8) TO authenticated, anon;

-- ── 4.3 transporteurs_proximite ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION transporteurs_proximite(
  client_lat FLOAT8,
  client_lng FLOAT8,
  rayon_km   FLOAT8 DEFAULT 15
)
RETURNS TABLE (
  id             UUID,   nom TEXT,  photo_url TEXT,
  latitude       FLOAT8, longitude FLOAT8,
  type_vehicule  TEXT,   categorie TEXT,
  note_moyenne   FLOAT8, nombre_courses INT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    u.id, u.nom, u.photo_url, u.latitude, u.longitude,
    COALESCE(v.type,      'voiture') AS type_vehicule,
    COALESCE(v.categorie, 'voiture') AS categorie,
    COALESCE(u.note_moyenne, 5.0)    AS note_moyenne,
    COALESCE(u.nombre_courses, 0)    AS nombre_courses
  FROM public.users u
  LEFT JOIN public.vehicules v
    ON v.transporteur_id = u.id AND v.valide = true
  WHERE u.role             = 'transporteur'
    AND u.statut_connexion = 'en_ligne'
    AND u.latitude  IS NOT NULL
    AND u.longitude IS NOT NULL
    AND distance_km(client_lat, client_lng, u.latitude, u.longitude) <= rayon_km
$$;
GRANT EXECUTE ON FUNCTION transporteurs_proximite(FLOAT8, FLOAT8, FLOAT8) TO authenticated, anon;

-- ── 4.4 liberer_sequestre_course (version finale 059) ─────────────────────────
-- Commission dynamique : 10% pendant 7j post-KYC, sinon 20%
-- Crédite TR + parrain client + parrain TR + jalons + streak
CREATE OR REPLACE FUNCTION liberer_sequestre_course(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_pid UUID;    v_montant INT;
  v_cl  UUID;    v_tr      UUID;
  v_wid UUID;    v_net     INT;
  v_comm INT;    v_taux    NUMERIC;
  v_kyc_dt TIMESTAMPTZ;
  v_pct_parr NUMERIC;
  v_parr_cl UUID; v_parr_tr UUID;
  v_wparr UUID;   v_cp INT;
BEGIN
  SELECT id, montant_fcfa INTO v_pid, v_montant
    FROM public.paiements
   WHERE course_id = p_course_id AND statut = 'sequestre'
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_confirmed_payment');
  END IF;

  SELECT client_id, transporteur_id INTO v_cl, v_tr
    FROM public.courses WHERE id = p_course_id;

  IF v_tr IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  -- Commission dynamique
  SELECT kyc_approuve_le INTO v_kyc_dt FROM public.users WHERE id = v_tr;
  v_taux := CASE
    WHEN v_kyc_dt IS NOT NULL AND NOW() - v_kyc_dt < INTERVAL '7 days' THEN 0.10
    ELSE 0.20
  END;
  v_comm := ROUND(v_montant * v_taux);
  v_net  := v_montant - v_comm;

  -- Créditer transporteur
  INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_tr, 0)
    ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wid FROM public.wallets WHERE user_id = v_tr;
  UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW() WHERE id = v_wid;
  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'recette', v_net, 'validee', p_course_id::text);

  -- Libérer le paiement
  UPDATE public.paiements SET statut = 'libere', libere_at = NOW() WHERE id = v_pid;
  UPDATE public.courses SET statut_paiement = 'libere', updated_at = NOW() WHERE id = p_course_id;

  -- Taux parrainage
  SELECT COALESCE(valeur::NUMERIC, 0.05) INTO v_pct_parr
    FROM public.configurations_systeme WHERE cle = 'commission_parrainage_pct';
  v_pct_parr := COALESCE(v_pct_parr, 0.05);

  -- Parrain du client
  SELECT parrain_id INTO v_parr_cl FROM public.users WHERE id = v_cl AND parrain_id IS NOT NULL;
  IF v_parr_cl IS NOT NULL THEN
    v_cp := ROUND(v_comm * v_pct_parr);
    INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_parr_cl, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wparr FROM public.wallets WHERE user_id = v_parr_cl;
    UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_cp, updated_at = NOW() WHERE id = v_wparr;
    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wparr, 'parrainage', v_cp, 'validee', p_course_id::text);
    INSERT INTO public.commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parr_cl, v_cl, p_course_id, v_cp);
  END IF;

  -- Parrain du transporteur
  SELECT parrain_id INTO v_parr_tr FROM public.users WHERE id = v_tr AND parrain_id IS NOT NULL;
  IF v_parr_tr IS NOT NULL AND v_parr_tr IS DISTINCT FROM v_parr_cl THEN
    v_cp := ROUND(v_comm * v_pct_parr);
    INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_parr_tr, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wparr FROM public.wallets WHERE user_id = v_parr_tr;
    UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_cp, updated_at = NOW() WHERE id = v_wparr;
    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wparr, 'parrainage', v_cp, 'validee', p_course_id::text);
    INSERT INTO public.commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa)
      VALUES (v_parr_tr, v_tr, p_course_id, v_cp);
  END IF;

  -- Jalons + streak client
  PERFORM verifier_jalons_client(v_cl, v_montant);
  PERFORM verifier_streak_hebdo(v_cl);

  RETURN jsonb_build_object(
    'ok',         true,
    'net_tr',     v_net,
    'commission', v_comm,
    'taux',       v_taux
  );
END;
$$;
GRANT EXECUTE ON FUNCTION liberer_sequestre_course(UUID) TO authenticated, service_role;

-- ── 4.5 candidater_course (version finale 059) ────────────────────────────────
CREATE OR REPLACE FUNCTION candidater_course(p_course_id UUID, p_transporteur_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET row_security = off
AS $$
DECLARE
  v_methode    TEXT;   v_prix      INTEGER;
  v_commission INTEGER; v_solde    INTEGER;
  v_kyc_valide BOOLEAN; v_mois_nb  INTEGER;
  v_candidature JSONB;
BEGIN
  SELECT methode_paiement, prix_fcfa INTO v_methode, v_prix
    FROM public.courses WHERE id = p_course_id AND statut = 'en_attente';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE' USING HINT = 'Cette course n''est plus disponible.';
  END IF;

  -- Limite KYC : 2 courses/mois pour les non-vérifiés
  SELECT COALESCE(kyc_valide, false) INTO v_kyc_valide
    FROM public.users WHERE id = p_transporteur_id;
  IF NOT v_kyc_valide THEN
    SELECT COUNT(*)::INTEGER INTO v_mois_nb
      FROM public.courses
     WHERE transporteur_id = p_transporteur_id AND statut = 'terminee'
       AND date_trunc('month', updated_at) = date_trunc('month', NOW());
    IF v_mois_nb >= 2 THEN
      RAISE EXCEPTION 'LIMITE_KYC_ATTEINTE'
        USING HINT = 'Limite de 2 courses/mois atteinte. Soumettez votre dossier KYC pour continuer.';
    END IF;
  END IF;

  -- Vérif solde pour cours espèces
  IF v_methode = 'especes' THEN
    v_commission := ROUND(v_prix::NUMERIC * 0.20)::INTEGER;
    SELECT COALESCE(solde_fcfa, 0) INTO v_solde
      FROM public.wallets WHERE user_id = p_transporteur_id;
    IF v_solde < v_commission THEN
      RAISE EXCEPTION 'SOLDE_INSUFFISANT'
        USING HINT = format('Solde wallet (%s XAF) insuffisant pour la commission de %s XAF.', v_solde, v_commission);
    END IF;
  END IF;

  INSERT INTO public.candidatures(course_id, transporteur_id, statut)
    VALUES (p_course_id, p_transporteur_id, 'propose')
    ON CONFLICT (course_id, transporteur_id) DO UPDATE SET statut = 'propose'
    RETURNING to_jsonb(candidatures.*) INTO v_candidature;

  RETURN v_candidature;
END;
$$;
GRANT EXECUTE ON FUNCTION candidater_course(UUID, UUID) TO authenticated;

-- ── 4.6 debiter_commission_especes ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION debiter_commission_especes(p_course_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_tr_id    UUID;   v_prix     INTEGER;
  v_methode  TEXT;   v_comm     INTEGER;
  v_wallet   UUID;   v_solde    INTEGER;
BEGIN
  SELECT transporteur_id, prix_fcfa, methode_paiement
    INTO v_tr_id, v_prix, v_methode
    FROM public.courses WHERE id = p_course_id;
  IF v_tr_id IS NULL THEN RAISE EXCEPTION 'Course introuvable : %', p_course_id; END IF;
  IF v_methode != 'especes' THEN RAISE EXCEPTION 'Course non espèces (methode: %)', v_methode; END IF;

  v_comm := ROUND(v_prix * 0.20);
  SELECT id, solde_fcfa INTO v_wallet, v_solde FROM public.wallets WHERE user_id = v_tr_id;
  IF v_wallet IS NULL THEN RAISE EXCEPTION 'Wallet introuvable pour le transporteur : %', v_tr_id; END IF;
  IF v_solde < v_comm THEN RAISE EXCEPTION 'Solde insuffisant (solde: % XAF, commission: % XAF)', v_solde, v_comm; END IF;

  UPDATE public.wallets SET solde_fcfa = solde_fcfa - v_comm WHERE id = v_wallet;
  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wallet, 'commission', v_comm, 'COM-' || UPPER(SUBSTRING(p_course_id::TEXT, 1, 8)), 'validee');
  RETURN v_comm;
END;
$$;
GRANT EXECUTE ON FUNCTION debiter_commission_especes(UUID) TO authenticated;

-- ── 4.7 payer_course_wallet (avec plafond 5 000 000 XAF) ─────────────────────
CREATE OR REPLACE FUNCTION payer_course_wallet(
  p_destinataire_id UUID,
  p_montant         INTEGER,
  p_reference       TEXT DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_payeur_id    UUID := auth.uid();
  v_wallet_payeur UUID; v_solde INT;
BEGIN
  IF v_payeur_id IS NULL THEN RAISE EXCEPTION 'Non authentifié'; END IF;
  IF p_montant <= 0 THEN RAISE EXCEPTION 'Montant invalide : doit être > 0'; END IF;
  IF p_montant > 5000000 THEN RAISE EXCEPTION 'Montant maximum dépassé : 5 000 000 XAF'; END IF;
  IF v_payeur_id = p_destinataire_id THEN RAISE EXCEPTION 'Impossible de se payer soi-même'; END IF;

  SELECT id, solde_fcfa INTO v_wallet_payeur, v_solde
    FROM public.wallets WHERE user_id = v_payeur_id LIMIT 1;
  IF v_wallet_payeur IS NULL THEN RAISE EXCEPTION 'Portefeuille introuvable — rechargez d''abord votre wallet'; END IF;
  IF v_solde < p_montant THEN RAISE EXCEPTION 'Solde insuffisant (disponible : % XAF)', v_solde; END IF;

  UPDATE public.wallets SET solde_fcfa = solde_fcfa - p_montant, updated_at = now() WHERE id = v_wallet_payeur;
  UPDATE public.wallets SET solde_fcfa = solde_fcfa + p_montant, updated_at = now() WHERE user_id = p_destinataire_id;

  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wallet_payeur, 'debit', p_montant, p_reference, 'validee');
  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    SELECT id, 'credit', p_montant, p_reference, 'validee' FROM public.wallets WHERE user_id = p_destinataire_id;
END;
$$;
GRANT EXECUTE ON FUNCTION payer_course_wallet(UUID, INTEGER, TEXT) TO authenticated;

-- ── 4.8 crediter_wallet (appelé par webhook Moneroo — service_role uniquement) ─
CREATE OR REPLACE FUNCTION crediter_wallet(p_wallet_id UUID, p_montant INTEGER)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.wallets SET solde_fcfa = solde_fcfa + p_montant, updated_at = NOW() WHERE id = p_wallet_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION crediter_wallet(UUID, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION crediter_wallet(UUID, INTEGER) TO service_role;

-- ── 4.9 signaler_litige ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION signaler_litige(p_course_id UUID, p_raison TEXT DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.courses
    SET statut = 'litige', litige_raison = p_raison, updated_at = NOW()
   WHERE id = p_course_id AND client_id = auth.uid()
     AND statut IN ('livree','terminee','en_cours');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course introuvable ou statut invalide pour signaler un litige';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION signaler_litige(UUID, TEXT) TO authenticated;

-- ── 4.10 traiter_retrait_admin ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION traiter_retrait_admin(
  p_retrait_id UUID, p_statut TEXT, p_note TEXT DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET row_security = off
AS $$
DECLARE
  v_retrait public.retraits%ROWTYPE;
  v_wallet  UUID;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Accès refusé — admin requis';
  END IF;
  IF p_statut NOT IN ('traite','refuse') THEN
    RAISE EXCEPTION 'Statut invalide : %', p_statut;
  END IF;
  SELECT * INTO v_retrait FROM public.retraits WHERE id = p_retrait_id AND statut = 'en_attente';
  IF NOT FOUND THEN RAISE EXCEPTION 'Retrait introuvable ou déjà traité'; END IF;

  UPDATE public.retraits SET statut = p_statut, note_admin = p_note, updated_at = now() WHERE id = p_retrait_id;

  IF p_statut = 'traite' THEN
    SELECT id INTO v_wallet FROM public.wallets WHERE user_id = v_retrait.transporteur_id;
    IF FOUND THEN
      UPDATE public.wallets SET solde_fcfa = GREATEST(0, solde_fcfa - v_retrait.montant_fcfa), updated_at = now() WHERE id = v_wallet;
    END IF;
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION traiter_retrait_admin(UUID, TEXT, TEXT) TO authenticated;

-- ── 4.11 expirer_courses_inactives ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION expirer_courses_inactives()
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE nb INTEGER;
BEGIN
  UPDATE public.courses SET statut = 'expiree', updated_at = now()
   WHERE statut = 'en_attente' AND expires_at < now();
  GET DIAGNOSTICS nb = ROW_COUNT;
  RETURN nb;
END;
$$;
GRANT EXECUTE ON FUNCTION expirer_courses_inactives() TO authenticated;

-- ── 4.12 expirer_abonnements ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION expirer_abonnements()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.abonnements_transporteurs SET statut = 'expire'
   WHERE statut = 'actif' AND fin_at < NOW();
  UPDATE public.users u SET pack_actuel = 'gratuit', pack_expire_at = NULL
   WHERE u.role = 'transporteur' AND u.pack_actuel != 'gratuit'
     AND NOT EXISTS (
       SELECT 1 FROM public.abonnements_transporteurs a
       WHERE a.transporteur_id = u.id AND a.statut = 'actif' AND a.fin_at > NOW()
     );
END;
$$;

-- ── 4.13 get_stats_parrainage ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_stats_parrainage()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_commissions', COALESCE(SUM(cp.montant_fcfa), 0),
    'nombre_filleuls',   COUNT(DISTINCT cp.filleul_id),
    'filleuls', (
      SELECT COALESCE(jsonb_agg(row_data ORDER BY gains_fcfa DESC), '[]'::jsonb)
      FROM (
        SELECT
          CASE WHEN SPLIT_PART(u.nom,' ',2)='' THEN u.nom
               ELSE SPLIT_PART(u.nom,' ',1)||' '||UPPER(LEFT(SPLIT_PART(u.nom,' ',2),1))||'.'
          END AS nom_anonymise,
          SUM(cp2.montant_fcfa) AS gains_fcfa
        FROM public.commissions_parrainage cp2
        JOIN public.users u ON u.id = cp2.filleul_id
        WHERE cp2.parrain_id = v_uid
        GROUP BY u.id, u.nom
      ) AS row_data
    )
  ) INTO v_result
  FROM public.commissions_parrainage cp
  WHERE cp.parrain_id = v_uid;

  RETURN COALESCE(v_result,
    jsonb_build_object('total_commissions',0,'nombre_filleuls',0,'filleuls','[]'::jsonb));
END;
$$;
GRANT EXECUTE ON FUNCTION get_stats_parrainage() TO authenticated;

-- ── 4.14 verifier_jalons_client (version finale 059) ─────────────────────────
CREATE OR REPLACE FUNCTION verifier_jalons_client(
  p_client_id UUID,
  p_prix_fcfa  INTEGER DEFAULT 1000
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_nb INTEGER; v_jalon INTEGER; v_type TEXT; v_valeur INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_nb
    FROM public.courses WHERE client_id = p_client_id AND statut = 'terminee';
  CASE v_nb
    WHEN 10  THEN v_jalon := 10;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.20)::INTEGER;
    WHEN 20  THEN v_jalon := 20;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.30)::INTEGER;
    WHEN 30  THEN v_jalon := 30;  v_type := 'wallet_credit'; v_valeur := ROUND(p_prix_fcfa * 0.50)::INTEGER;
    WHEN 50  THEN v_jalon := 50;  v_type := 'wallet_credit'; v_valeur := LEAST(p_prix_fcfa, 5000);
    WHEN 100 THEN v_jalon := 100; v_type := 'vip';           v_valeur := 10000;
    ELSE RETURN;
  END CASE;
  INSERT INTO public.recompenses_client(client_id, jalon, recompense_type, recompense_valeur, statut)
    VALUES (p_client_id, v_jalon, v_type, v_valeur, 'en_attente')
    ON CONFLICT DO NOTHING;
  IF v_type = 'vip' THEN
    UPDATE public.users SET statut_vip = TRUE, est_vip = TRUE WHERE id = p_client_id;
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION verifier_jalons_client(UUID, INTEGER) TO authenticated, service_role;

-- ── 4.15 reveler_jalon ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION reveler_jalon(p_jalon_id UUID, p_client_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_row  public.recompenses_client;
  v_wid  UUID;
BEGIN
  SELECT * INTO v_row FROM public.recompenses_client
   WHERE id = p_jalon_id AND client_id = p_client_id AND statut = 'en_attente';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'RECOMPENSE_INTROUVABLE' USING HINT = 'Ce jalon est introuvable ou déjà révélé.';
  END IF;

  UPDATE public.recompenses_client SET statut = 'revele', revele_le = NOW() WHERE id = p_jalon_id;

  IF v_row.recompense_type = 'wallet_credit' AND v_row.recompense_valeur > 0 THEN
    INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (p_client_id, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM public.wallets WHERE user_id = p_client_id;
    UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_row.recompense_valeur, updated_at = NOW() WHERE id = v_wid;
    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'jalon_client', v_row.recompense_valeur, 'validee',
              'jalon_' || v_row.jalon::text || '_' || p_client_id::text);
  END IF;

  IF v_row.recompense_type = 'vip' THEN
    UPDATE public.users SET statut_vip = TRUE, est_vip = TRUE WHERE id = p_client_id;
    IF v_row.recompense_valeur > 0 THEN
      INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (p_client_id, 0) ON CONFLICT (user_id) DO NOTHING;
      SELECT id INTO v_wid FROM public.wallets WHERE user_id = p_client_id;
      UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_row.recompense_valeur, updated_at = NOW() WHERE id = v_wid;
      INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
        VALUES (v_wid, 'jalon_client', v_row.recompense_valeur, 'validee', 'jalon_vip_' || p_client_id::text);
    END IF;
  END IF;

  RETURN jsonb_build_object('jalon', v_row.jalon, 'type', v_row.recompense_type, 'valeur', v_row.recompense_valeur);
END;
$$;
GRANT EXECUTE ON FUNCTION reveler_jalon(UUID, UUID) TO authenticated;

-- ── 4.16 verifier_streak_hebdo ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION verifier_streak_hebdo(p_client_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_debut_sem TIMESTAMPTZ := date_trunc('week', NOW());
  v_nb        INTEGER;
  v_wid       UUID;
BEGIN
  SELECT COUNT(*) INTO v_nb
    FROM public.courses
   WHERE client_id = p_client_id AND statut = 'terminee' AND updated_at >= v_debut_sem;
  IF v_nb <> 3 THEN RETURN; END IF;

  IF EXISTS (
    SELECT 1 FROM public.transactions_wallet tw
      JOIN public.wallets w ON w.id = tw.wallet_id
     WHERE w.user_id = p_client_id AND tw.type = 'bonus_streak'
       AND tw.created_at >= v_debut_sem
  ) THEN RETURN; END IF;

  INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (p_client_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wid FROM public.wallets WHERE user_id = p_client_id;
  UPDATE public.wallets SET solde_fcfa = solde_fcfa + 100, updated_at = NOW() WHERE id = v_wid;
  INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'bonus_streak', 100, 'validee', 'streak_sem_' || to_char(v_debut_sem, 'YYYY_WW'));
END;
$$;
GRANT EXECUTE ON FUNCTION verifier_streak_hebdo(UUID) TO authenticated, service_role;

-- ── 4.17 calculer_classement_mensuel (version finale 060) ────────────────────
CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_mois DATE := date_trunc('month', NOW())::DATE;
BEGIN
  UPDATE public.users SET rang_tr_mois = NULL, top_tr_mois = FALSE WHERE role = 'transporteur';
  UPDATE public.users SET is_top_tr_mois = FALSE WHERE is_top_tr_mois = TRUE;

  WITH stats AS (
    SELECT
      c.transporteur_id                                                                AS uid,
      COUNT(*)                                                                         AS nb,
      ROW_NUMBER() OVER (ORDER BY COUNT(*) * 2 + COALESCE(u.note_moyenne, 5.0) * 10 DESC) AS rang
    FROM public.courses c
    JOIN public.users u ON u.id = c.transporteur_id AND u.role = 'transporteur' AND u.kyc_valide = TRUE
    WHERE c.statut = 'terminee'
      AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois
    GROUP BY c.transporteur_id, u.note_moyenne
  )
  UPDATE public.users u SET rang_tr_mois = s.rang, top_tr_mois = (s.rang <= 10)
    FROM stats s WHERE u.id = s.uid;

  INSERT INTO public.classement_mensuel_tr(user_id, mois, rang, nb_courses, note_moyenne, is_top10, updated_at)
  SELECT u.id, v_mois,
    COALESCE(s.rang_tr_mois, 9999),
    COALESCE(nb.nb_courses, 0),
    COALESCE(u.note_moyenne, 0),
    COALESCE(u.top_tr_mois, false),
    NOW()
  FROM public.users u
  LEFT JOIN public.users s ON s.id = u.id
  LEFT JOIN (
    SELECT transporteur_id, COUNT(*)::INTEGER AS nb_courses
      FROM public.courses
     WHERE statut = 'terminee'
       AND date_trunc('month', COALESCE(completed_at, updated_at)) = v_mois
     GROUP BY transporteur_id
  ) nb ON nb.transporteur_id = u.id
  WHERE u.role = 'transporteur' AND COALESCE(nb.nb_courses, 0) > 0
  ON CONFLICT (user_id, mois) DO UPDATE
    SET rang         = EXCLUDED.rang,
        nb_courses   = EXCLUDED.nb_courses,
        note_moyenne = EXCLUDED.note_moyenne,
        is_top10     = EXCLUDED.is_top10,
        updated_at   = NOW();

  UPDATE public.users u SET is_top_tr_mois = TRUE
    FROM public.classement_mensuel_tr c
   WHERE c.user_id = u.id AND c.mois = v_mois AND c.is_top10 = TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION calculer_classement_mensuel() TO service_role;

-- ── 4.18 calculer_bonus_volume_mensuel ────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculer_bonus_volume_mensuel()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_rec       RECORD;   v_wid    UUID;
  v_bonus     INTEGER;  v_pct    NUMERIC;
  v_mois_prec DATE := (date_trunc('month', NOW()) - INTERVAL '1 month')::DATE;
  v_ref       TEXT := 'bvol_' || to_char(v_mois_prec, 'YYYY_MM');
BEGIN
  IF EXISTS (SELECT 1 FROM public.transactions_wallet WHERE reference LIKE v_ref || '%' LIMIT 1) THEN RETURN; END IF;

  FOR v_rec IN
    SELECT c.transporteur_id AS user_id, COUNT(*)::INTEGER AS nb_courses,
           COALESCE(SUM(p.montant_fcfa), 0)::INTEGER AS total_ca
      FROM public.courses c
      JOIN public.paiements p ON p.course_id = c.id AND p.statut = 'libere'
     WHERE c.statut = 'terminee'
       AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois_prec
     GROUP BY c.transporteur_id
  LOOP
    v_pct := CASE
      WHEN v_rec.nb_courses >= 50 THEN 0.07
      WHEN v_rec.nb_courses >= 25 THEN 0.04
      WHEN v_rec.nb_courses >= 10 THEN 0.02
      ELSE 0
    END;
    IF v_pct = 0 THEN CONTINUE; END IF;
    v_bonus := GREATEST(0, ROUND(v_rec.total_ca * 0.20 * v_pct));
    IF v_bonus = 0 THEN CONTINUE; END IF;

    INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_rec.user_id, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM public.wallets WHERE user_id = v_rec.user_id;
    UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW() WHERE id = v_wid;
    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'bonus_volume', v_bonus, 'validee', v_ref || '_' || v_rec.user_id);
  END LOOP;
END;
$$;
GRANT EXECUTE ON FUNCTION calculer_bonus_volume_mensuel() TO service_role;

-- ── 4.19 calculer_prime_qualite_mensuelle ─────────────────────────────────────
CREATE OR REPLACE FUNCTION calculer_prime_qualite_mensuelle()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_rec       RECORD;   v_wid    UUID;   v_bonus INTEGER;
  v_mois_prec DATE := (date_trunc('month', NOW()) - INTERVAL '1 month')::DATE;
  v_ref       TEXT := 'pqual_' || to_char(v_mois_prec, 'YYYY_MM');
BEGIN
  IF EXISTS (SELECT 1 FROM public.transactions_wallet WHERE reference LIKE v_ref || '%' LIMIT 1) THEN RETURN; END IF;

  FOR v_rec IN
    SELECT u.id AS user_id, COALESCE(u.note_moyenne, 0) AS note, COUNT(c.id)::INTEGER AS nb
      FROM public.users u
      LEFT JOIN public.courses c ON c.transporteur_id = u.id AND c.statut = 'terminee'
        AND date_trunc('month', COALESCE(c.completed_at, c.updated_at)) = v_mois_prec
     WHERE u.role = 'transporteur'
     GROUP BY u.id, u.note_moyenne
    HAVING COUNT(c.id) >= 5
  LOOP
    v_bonus := CASE WHEN v_rec.note >= 4.5 THEN 500 ELSE 0 END;
    IF v_bonus = 0 THEN CONTINUE; END IF;

    INSERT INTO public.wallets(user_id, solde_fcfa) VALUES (v_rec.user_id, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM public.wallets WHERE user_id = v_rec.user_id;
    UPDATE public.wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW() WHERE id = v_wid;
    INSERT INTO public.transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
      VALUES (v_wid, 'prime_qualite', v_bonus, 'validee', v_ref || '_' || v_rec.user_id);
  END LOOP;
END;
$$;
GRANT EXECUTE ON FUNCTION calculer_prime_qualite_mensuelle() TO service_role;

-- ── 4.20 Fonctions messages ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION compteur_messages_non_lus(p_user_id UUID)
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT COUNT(*)::int FROM public.messages
     WHERE destinataire_id = p_user_id AND lu = false AND course_id IS NULL), 0)
  + COALESCE(
    (SELECT COUNT(*)::int FROM public.messages m
     JOIN public.courses c ON c.id = m.course_id
     WHERE (c.client_id = p_user_id OR c.transporteur_id = p_user_id)
       AND m.expediteur_id != p_user_id AND m.lu = false), 0);
$$;
GRANT EXECUTE ON FUNCTION compteur_messages_non_lus(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION marquer_dm_lus(p_destinataire_id UUID, p_expediteur_id UUID)
RETURNS void LANGUAGE sql SECURITY DEFINER
AS $$
  UPDATE public.messages SET lu = true
  WHERE destinataire_id = p_destinataire_id AND expediteur_id = p_expediteur_id
    AND lu = false AND course_id IS NULL;
$$;
GRANT EXECUTE ON FUNCTION marquer_dm_lus(UUID, UUID) TO authenticated;

CREATE OR REPLACE FUNCTION marquer_course_lus(p_course_id UUID, p_user_id UUID)
RETURNS void LANGUAGE sql SECURITY DEFINER
AS $$
  UPDATE public.messages SET lu = true
  WHERE course_id = p_course_id AND expediteur_id != p_user_id AND lu = false;
$$;
GRANT EXECUTE ON FUNCTION marquer_course_lus(UUID, UUID) TO authenticated;

-- ── 4.21 tr_documents_expirant ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION tr_documents_expirant(jours INTEGER DEFAULT 30)
RETURNS TABLE(user_id UUID, nom TEXT, telephone TEXT, cni_expiration DATE, permis_expiration DATE)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT k.user_id, u.nom, u.telephone, k.cni_expiration, k.permis_expiration
    FROM public.transporteurs_kyc k
    JOIN public.users u ON u.id = k.user_id
   WHERE k.statut_kyc = 'approuve'
     AND ((k.cni_expiration    BETWEEN CURRENT_DATE AND CURRENT_DATE + jours)
       OR (k.permis_expiration BETWEEN CURRENT_DATE AND CURRENT_DATE + jours));
$$;


-- ══════════════════════════════════════════════════════════════════════════════
-- 5. TRIGGERS
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 5.1 Générer code_parrainage à l'inscription ───────────────────────────────
CREATE OR REPLACE FUNCTION generer_code_parrainage()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.code_parrainage IS NULL THEN
    NEW.code_parrainage := UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', ''), 1, 6));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_code_parrainage ON public.users;
CREATE TRIGGER trg_code_parrainage
  BEFORE INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION generer_code_parrainage();

-- ── 5.2 Générer OTP livraison à la création d'une course ─────────────────────
CREATE OR REPLACE FUNCTION generer_otp_course()
RETURNS TRIGGER AS $$
BEGIN
  NEW.otp_livraison := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_otp_course ON public.courses;
CREATE TRIGGER trg_otp_course
  BEFORE INSERT ON public.courses
  FOR EACH ROW EXECUTE FUNCTION generer_otp_course();

-- ── 5.3 Fixer expires_at à created_at + 1h ────────────────────────────────────
CREATE OR REPLACE FUNCTION set_course_expires_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.expires_at IS NULL THEN
    NEW.expires_at := NEW.created_at + INTERVAL '1 hour';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_course_expires_at ON public.courses;
CREATE TRIGGER trg_course_expires_at
  BEFORE INSERT ON public.courses
  FOR EACH ROW EXECUTE FUNCTION set_course_expires_at();

-- ── 5.4 Recalculer note_moyenne + nombre_courses après un avis ────────────────
CREATE OR REPLACE FUNCTION recalc_note_user()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET
    note_moyenne   = (SELECT COALESCE(AVG(note_globale), 5.0) FROM public.avis WHERE cible_id = NEW.cible_id),
    nombre_courses = (SELECT COUNT(*) FROM public.courses
                      WHERE (transporteur_id = NEW.cible_id OR client_id = NEW.cible_id)
                        AND statut = 'terminee')
  WHERE id = NEW.cible_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_recalc_note ON public.avis;
CREATE TRIGGER trg_recalc_note
  AFTER INSERT OR UPDATE ON public.avis
  FOR EACH ROW EXECUTE FUNCTION recalc_note_user();

-- ── 5.5 Créditer points après course terminée ─────────────────────────────────
CREATE OR REPLACE FUNCTION crediter_points_course()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE pts INTEGER;
BEGIN
  IF NEW.statut = 'terminee' AND COALESCE(OLD.statut, '') <> 'terminee' THEN
    pts := GREATEST(1, FLOOR(COALESCE(NEW.prix_fcfa, 0) / 100));
    INSERT INTO public.transactions_points(user_id, montant, motif, course_id)
      VALUES (NEW.client_id, pts, 'course', NEW.id);
    UPDATE public.users SET points = points + pts WHERE id = NEW.client_id;
    IF EXISTS (SELECT 1 FROM public.users WHERE id = NEW.client_id AND parrain_id IS NOT NULL) THEN
      INSERT INTO public.transactions_points(user_id, montant, motif, course_id)
        SELECT parrain_id, GREATEST(1, pts / 2), 'parrainage', NEW.id
          FROM public.users WHERE id = NEW.client_id;
      UPDATE public.users u SET points = u.points + GREATEST(1, pts / 2)
        FROM public.users c WHERE c.id = NEW.client_id AND u.id = c.parrain_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_points_course ON public.courses;
CREATE TRIGGER trg_points_course
  AFTER UPDATE OF statut ON public.courses
  FOR EACH ROW EXECUTE FUNCTION crediter_points_course();

-- ── 5.6 Jalons + streak après course terminée ─────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_after_course_terminee()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.statut = 'terminee' AND COALESCE(OLD.statut, '') <> 'terminee' THEN
    IF NEW.completed_at IS NULL THEN
      UPDATE public.courses SET completed_at = NOW() WHERE id = NEW.id;
    END IF;
    IF NEW.client_id IS NOT NULL THEN
      PERFORM verifier_jalons_client(NEW.client_id, COALESCE(NEW.prix_fcfa, 1000));
      PERFORM verifier_streak_hebdo(NEW.client_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_course_terminee ON public.courses;
CREATE TRIGGER after_course_terminee
  AFTER UPDATE ON public.courses
  FOR EACH ROW EXECUTE FUNCTION trigger_after_course_terminee();

-- ── 5.7 Sync kyc_valide depuis transporteurs_kyc ─────────────────────────────
CREATE OR REPLACE FUNCTION sync_kyc_valide()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.statut_kyc = 'approuve' THEN
    UPDATE public.users SET kyc_valide = TRUE  WHERE id = NEW.user_id;
  ELSE
    UPDATE public.users SET kyc_valide = FALSE WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_sync_kyc_valide ON public.transporteurs_kyc;
CREATE TRIGGER trigger_sync_kyc_valide
  AFTER INSERT OR UPDATE OF statut_kyc ON public.transporteurs_kyc
  FOR EACH ROW EXECUTE FUNCTION sync_kyc_valide();

-- ── 5.8 Fixer kyc_approuve_le quand kyc_valide passe à TRUE ──────────────────
CREATE OR REPLACE FUNCTION _set_kyc_approuve_le()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.kyc_valide = TRUE AND COALESCE(OLD.kyc_valide, FALSE) = FALSE THEN
    NEW.kyc_approuve_le = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kyc_approuve_le ON public.users;
CREATE TRIGGER trg_kyc_approuve_le
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION _set_kyc_approuve_le();

-- ── 5.9 Sync type_vehicule sur users depuis vehicules ─────────────────────────
CREATE OR REPLACE FUNCTION sync_type_vehicule_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.valide = TRUE AND NEW.categorie IS NOT NULL THEN
    UPDATE public.users SET type_vehicule = NEW.categorie WHERE id = NEW.transporteur_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_type_vehicule ON public.vehicules;
CREATE TRIGGER trg_sync_type_vehicule
  AFTER INSERT OR UPDATE OF valide, categorie ON public.vehicules
  FOR EACH ROW EXECUTE FUNCTION sync_type_vehicule_user();

-- ── 5.10 updated_at automatique sur paiements et retraits ────────────────────
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_paiement_ts ON public.paiements;
CREATE TRIGGER trg_paiement_ts
  BEFORE UPDATE ON public.paiements
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_retraits_ts ON public.retraits;
CREATE TRIGGER trg_retraits_ts
  BEFORE UPDATE ON public.retraits
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();


-- ══════════════════════════════════════════════════════════════════════════════
-- 6. RLS (Row Level Security)
-- ══════════════════════════════════════════════════════════════════════════════

-- ── users ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users_select"       ON public.users;
DROP POLICY IF EXISTS "users_update_soi"   ON public.users;
DROP POLICY IF EXISTS "users_admin_insert" ON public.users;
CREATE POLICY "users_select"       ON public.users FOR SELECT USING (auth.uid() = id OR is_admin());
CREATE POLICY "users_update_soi"   ON public.users FOR UPDATE USING (auth.uid() = id OR is_admin()) WITH CHECK (auth.uid() = id OR is_admin());
CREATE POLICY "users_admin_insert" ON public.users FOR INSERT WITH CHECK (auth.uid() = id OR is_admin());

-- ── vehicules ─────────────────────────────────────────────────────────────────
ALTER TABLE public.vehicules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "vehicules_select" ON public.vehicules;
DROP POLICY IF EXISTS "vehicules_insert" ON public.vehicules;
DROP POLICY IF EXISTS "vehicules_update" ON public.vehicules;
CREATE POLICY "vehicules_select" ON public.vehicules FOR SELECT USING (transporteur_id = auth.uid() OR is_admin());
CREATE POLICY "vehicules_insert" ON public.vehicules FOR INSERT WITH CHECK (transporteur_id = auth.uid());
CREATE POLICY "vehicules_update" ON public.vehicules FOR UPDATE USING (transporteur_id = auth.uid() OR is_admin());

-- ── courses ───────────────────────────────────────────────────────────────────
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "courses_admin_select"        ON public.courses;
DROP POLICY IF EXISTS "courses_client_insert"       ON public.courses;
DROP POLICY IF EXISTS "courses_update"              ON public.courses;
CREATE POLICY "courses_admin_select" ON public.courses FOR SELECT
  USING (client_id = auth.uid() OR transporteur_id = auth.uid() OR statut = 'en_attente' OR is_admin());
CREATE POLICY "courses_client_insert" ON public.courses FOR INSERT WITH CHECK (client_id = auth.uid());
CREATE POLICY "courses_update" ON public.courses FOR UPDATE
  USING (client_id = auth.uid() OR transporteur_id = auth.uid() OR is_admin());

-- ── messages ──────────────────────────────────────────────────────────────────
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "messages_lecture" ON public.messages;
DROP POLICY IF EXISTS "messages_insert"  ON public.messages;
CREATE POLICY "messages_lecture" ON public.messages FOR SELECT USING (
  auth.uid() IS NOT NULL AND (
    expediteur_id = auth.uid() OR destinataire_id = auth.uid()
    OR (course_id IS NOT NULL AND course_id IN (
      SELECT id FROM public.courses WHERE client_id = auth.uid() OR transporteur_id = auth.uid()
    ))
  )
);
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL AND expediteur_id = auth.uid()
);

-- ── paiements ─────────────────────────────────────────────────────────────────
ALTER TABLE public.paiements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "paiements_lecture"              ON public.paiements;
DROP POLICY IF EXISTS "paiements_insert"               ON public.paiements;
DROP POLICY IF EXISTS "paiements_update"               ON public.paiements;
DROP POLICY IF EXISTS "paiements_transporteur_lecture" ON public.paiements;
DROP POLICY IF EXISTS "paiements_admin_select"         ON public.paiements;
CREATE POLICY "paiements_lecture" ON public.paiements FOR SELECT
  USING (client_id = auth.uid() OR is_admin()
    OR course_id IN (SELECT id FROM public.courses WHERE transporteur_id = auth.uid()));
CREATE POLICY "paiements_insert"  ON public.paiements FOR INSERT
  WITH CHECK (client_id = auth.uid() AND course_id IN (SELECT id FROM public.courses WHERE client_id = auth.uid()));
CREATE POLICY "paiements_update"  ON public.paiements FOR UPDATE
  USING (client_id = auth.uid() OR is_admin());

-- ── wallets ───────────────────────────────────────────────────────────────────
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wallets_lecture"       ON public.wallets;
DROP POLICY IF EXISTS "wallets_creation"      ON public.wallets;
DROP POLICY IF EXISTS "wallets_modification"  ON public.wallets;
DROP POLICY IF EXISTS "wallets_admin_select"  ON public.wallets;
DROP POLICY IF EXISTS "wallets_admin_update"  ON public.wallets;
CREATE POLICY "wallets_lecture"      ON public.wallets FOR SELECT USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "wallets_creation"     ON public.wallets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "wallets_modification" ON public.wallets FOR UPDATE USING (user_id = auth.uid() OR is_admin()) WITH CHECK (user_id = auth.uid() OR is_admin());

-- ── transactions_wallet ───────────────────────────────────────────────────────
ALTER TABLE public.transactions_wallet ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "transactions_lecture"      ON public.transactions_wallet;
DROP POLICY IF EXISTS "transactions_creation"     ON public.transactions_wallet;
DROP POLICY IF EXISTS "transactions_modification" ON public.transactions_wallet;
CREATE POLICY "transactions_lecture"  ON public.transactions_wallet FOR SELECT
  USING (wallet_id IN (SELECT id FROM public.wallets WHERE user_id = auth.uid()) OR is_admin());
CREATE POLICY "transactions_creation" ON public.transactions_wallet FOR INSERT
  WITH CHECK (wallet_id IN (SELECT id FROM public.wallets WHERE user_id = auth.uid()));

-- ── transactions_points ───────────────────────────────────────────────────────
ALTER TABLE public.transactions_points ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "transactions_points_lecture" ON public.transactions_points;
CREATE POLICY "transactions_points_lecture" ON public.transactions_points
  FOR SELECT USING (user_id = auth.uid());

-- ── avis ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.avis ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "avis_lecture"  ON public.avis;
DROP POLICY IF EXISTS "avis_creation" ON public.avis;
DROP POLICY IF EXISTS "avis_modif"    ON public.avis;
CREATE POLICY "avis_lecture"  ON public.avis FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "avis_creation" ON public.avis FOR INSERT WITH CHECK (auteur_id = auth.uid());
CREATE POLICY "avis_modif"    ON public.avis FOR UPDATE USING (auteur_id = auth.uid());

-- ── retraits ──────────────────────────────────────────────────────────────────
ALTER TABLE public.retraits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "retraits_select_own"  ON public.retraits;
DROP POLICY IF EXISTS "retraits_insert_own"  ON public.retraits;
DROP POLICY IF EXISTS "retraits_admin_select" ON public.retraits;
DROP POLICY IF EXISTS "retraits_admin_update" ON public.retraits;
CREATE POLICY "retraits_select_own"   ON public.retraits FOR SELECT  USING (transporteur_id = auth.uid() OR is_admin());
CREATE POLICY "retraits_insert_own"   ON public.retraits FOR INSERT  WITH CHECK (transporteur_id = auth.uid());
CREATE POLICY "retraits_admin_update" ON public.retraits FOR UPDATE  USING (is_admin()) WITH CHECK (is_admin());

-- ── candidatures ──────────────────────────────────────────────────────────────
ALTER TABLE public.candidatures ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "candidatures_lecture" ON public.candidatures;
DROP POLICY IF EXISTS "candidatures_insert"  ON public.candidatures;
CREATE POLICY "candidatures_lecture" ON public.candidatures FOR SELECT
  USING (transporteur_id = auth.uid()
    OR course_id IN (SELECT id FROM public.courses WHERE client_id = auth.uid())
    OR is_admin());
CREATE POLICY "candidatures_insert" ON public.candidatures FOR INSERT WITH CHECK (transporteur_id = auth.uid());

-- ── transporteurs_kyc ─────────────────────────────────────────────────────────
ALTER TABLE public.transporteurs_kyc ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "kyc_admin_select" ON public.transporteurs_kyc;
DROP POLICY IF EXISTS "kyc_admin_update" ON public.transporteurs_kyc;
DROP POLICY IF EXISTS "kyc_insert_self"  ON public.transporteurs_kyc;
CREATE POLICY "kyc_admin_select" ON public.transporteurs_kyc FOR SELECT  USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "kyc_admin_update" ON public.transporteurs_kyc FOR UPDATE  USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "kyc_insert_self"  ON public.transporteurs_kyc FOR INSERT  WITH CHECK (user_id = auth.uid());

-- ── positions_gps ─────────────────────────────────────────────────────────────
ALTER TABLE public.positions_gps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gps_insert" ON public.positions_gps;
DROP POLICY IF EXISTS "gps_select" ON public.positions_gps;
CREATE POLICY "gps_insert" ON public.positions_gps FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "gps_select" ON public.positions_gps FOR SELECT
  USING (user_id = auth.uid()
    OR course_id IN (SELECT id FROM public.courses WHERE client_id = auth.uid() OR transporteur_id = auth.uid()));

-- ── parametres_tarifs ─────────────────────────────────────────────────────────
ALTER TABLE public.parametres_tarifs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tarifs_lecture_publique" ON public.parametres_tarifs;
DROP POLICY IF EXISTS "tarifs_admin_ecriture"   ON public.parametres_tarifs;
CREATE POLICY "tarifs_lecture_publique" ON public.parametres_tarifs FOR SELECT USING (true);
CREATE POLICY "tarifs_admin_ecriture"   ON public.parametres_tarifs FOR ALL    USING (is_admin());

-- ── configurations_systeme ────────────────────────────────────────────────────
ALTER TABLE public.configurations_systeme ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "config_lecture_authenticated" ON public.configurations_systeme;
DROP POLICY IF EXISTS "config_admin_ecriture"        ON public.configurations_systeme;
CREATE POLICY "config_lecture_authenticated" ON public.configurations_systeme FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "config_admin_ecriture"        ON public.configurations_systeme FOR ALL    USING (is_admin()) WITH CHECK (is_admin());

-- ── commissions_parrainage ────────────────────────────────────────────────────
ALTER TABLE public.commissions_parrainage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "commissions_lecture_parrain" ON public.commissions_parrainage;
DROP POLICY IF EXISTS "commissions_admin_select"    ON public.commissions_parrainage;
CREATE POLICY "commissions_lecture_parrain" ON public.commissions_parrainage FOR SELECT USING (parrain_id = auth.uid());
CREATE POLICY "commissions_admin_select"    ON public.commissions_parrainage FOR SELECT USING (is_admin());

-- ── abonnements_transporteurs ─────────────────────────────────────────────────
ALTER TABLE public.abonnements_transporteurs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "transporteur_own_abonnements" ON public.abonnements_transporteurs;
DROP POLICY IF EXISTS "admin_all_abonnements"        ON public.abonnements_transporteurs;
CREATE POLICY "transporteur_own_abonnements" ON public.abonnements_transporteurs FOR SELECT USING (auth.uid() = transporteur_id);
CREATE POLICY "admin_all_abonnements"        ON public.abonnements_transporteurs FOR ALL   USING (is_admin());

-- ── recompenses_client ────────────────────────────────────────────────────────
ALTER TABLE public.recompenses_client ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "recompenses_lecture" ON public.recompenses_client;
CREATE POLICY "recompenses_lecture" ON public.recompenses_client FOR SELECT USING (auth.uid() = client_id);

-- ── jalons_client ─────────────────────────────────────────────────────────────
ALTER TABLE public.jalons_client ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "jalons_client_lecture" ON public.jalons_client;
CREATE POLICY "jalons_client_lecture" ON public.jalons_client FOR SELECT USING (auth.uid() = client_id);

-- ── classement_mensuel_tr ─────────────────────────────────────────────────────
ALTER TABLE public.classement_mensuel_tr ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "classement_lecture" ON public.classement_mensuel_tr;
CREATE POLICY "classement_lecture" ON public.classement_mensuel_tr FOR SELECT USING (auth.uid() IS NOT NULL);


-- ══════════════════════════════════════════════════════════════════════════════
-- 7. INDEX DE PERFORMANCE
-- ══════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_courses_statut           ON public.courses(statut);
CREATE INDEX IF NOT EXISTS idx_courses_client_id        ON public.courses(client_id);
CREATE INDEX IF NOT EXISTS idx_courses_transporteur_id  ON public.courses(transporteur_id);
CREATE INDEX IF NOT EXISTS idx_courses_created_at       ON public.courses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_role               ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_statut_connexion   ON public.users(statut_connexion);
CREATE INDEX IF NOT EXISTS idx_paiements_moneroo_id     ON public.paiements(moneroo_payment_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_statut ON public.transactions_wallet(statut);
CREATE INDEX IF NOT EXISTS idx_positions_gps_user_course  ON public.positions_gps(user_id, course_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_course_id       ON public.messages(course_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at      ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_dm              ON public.messages(expediteur_id, destinataire_id) WHERE course_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_messages_lu_dest         ON public.messages(destinataire_id, lu) WHERE destinataire_id IS NOT NULL AND lu = FALSE;
CREATE INDEX IF NOT EXISTS idx_messages_lu_course       ON public.messages(course_id, lu) WHERE course_id IS NOT NULL AND lu = FALSE;
CREATE INDEX IF NOT EXISTS idx_retraits_transporteur    ON public.retraits(transporteur_id);
CREATE INDEX IF NOT EXISTS idx_commissions_parrain      ON public.commissions_parrainage(parrain_id);
CREATE INDEX IF NOT EXISTS idx_commissions_filleul      ON public.commissions_parrainage(filleul_id);
CREATE INDEX IF NOT EXISTS idx_commissions_course       ON public.commissions_parrainage(course_id);
CREATE INDEX IF NOT EXISTS idx_abonnements_tr           ON public.abonnements_transporteurs(transporteur_id, statut);
CREATE INDEX IF NOT EXISTS idx_jalons_client_id         ON public.jalons_client(client_id);
CREATE INDEX IF NOT EXISTS idx_recompenses_client_id    ON public.recompenses_client(client_id);


-- ══════════════════════════════════════════════════════════════════════════════
-- 8. REALTIME
-- ══════════════════════════════════════════════════════════════════════════════
-- Activer REPLICA IDENTITY FULL sur courses pour les événements DELETE/UPDATE

ALTER TABLE public.courses REPLICA IDENTITY FULL;

DO $$ BEGIN
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.courses;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.paiements;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.wallets;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.candidatures;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;


-- ══════════════════════════════════════════════════════════════════════════════
-- 9. CRON JOBS (nécessite l'extension pg_cron)
-- ══════════════════════════════════════════════════════════════════════════════

-- Expiration des courses inactives : toutes les 15 min
DO $$ BEGIN
  BEGIN PERFORM cron.unschedule('expirer-courses-inactives'); EXCEPTION WHEN others THEN NULL; END;
  BEGIN PERFORM cron.schedule('expirer-courses-inactives', '*/15 * * * *', 'SELECT expirer_courses_inactives()');
  EXCEPTION WHEN others THEN NULL; END;
END $$;

-- Classement TR : chaque nuit à minuit
INSERT INTO cron.job(schedule, command, jobname, database, username)
  SELECT '0 0 * * *', 'SELECT calculer_classement_mensuel()',
         'caarco-classement-tr-quotidien', current_database(), current_user
  WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-classement-tr-quotidien');

-- Bonus volume mensuel : 1er du mois à 6h
INSERT INTO cron.job(schedule, command, jobname, database, username)
  SELECT '0 6 1 * *', 'SELECT calculer_bonus_volume_mensuel()',
         'caarco-bonus-volume-mensuel', current_database(), current_user
  WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-bonus-volume-mensuel');

-- Prime qualité mensuelle : 1er du mois à 6h30
INSERT INTO cron.job(schedule, command, jobname, database, username)
  SELECT '30 6 1 * *', 'SELECT calculer_prime_qualite_mensuelle()',
         'caarco-prime-qualite-mensuel', current_database(), current_user
  WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-prime-qualite-mensuel');

-- Purge positions GPS : chaque nuit à 2h (RGPD — suppression après 30 jours)
INSERT INTO cron.job(schedule, command, jobname, database, username)
  SELECT '0 2 * * *',
         'DELETE FROM public.positions_gps WHERE created_at < NOW() - INTERVAL ''30 days''',
         'caarco-purge-gps', current_database(), current_user
  WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'caarco-purge-gps');


-- ══════════════════════════════════════════════════════════════════════════════
-- 10. DONNÉES DE RÉFÉRENCE (seed)
-- ══════════════════════════════════════════════════════════════════════════════

-- Tarifs par catégorie de véhicule
INSERT INTO public.parametres_tarifs (vehicule, tarif_km, frais_fixes) VALUES
  ('moto',                 150, 500),
  ('voiture',              250, 500),
  ('tricycle_camionnette', 400, 500),
  ('camion',               700, 500)
ON CONFLICT (vehicule) DO NOTHING;

-- Paramètres système
INSERT INTO public.configurations_systeme (cle, valeur, description) VALUES
  ('commission_parrainage_pct', '0.05', 'Part de la commission CAARCO reversée au parrain (ex: 0.05 = 5%)'),
  ('majoration_nuit_pct',       '0.20', 'Majoration tarifaire de nuit (20%)'),
  ('heure_debut_nuit',          '20',   'Heure de début de la plage nuit (format 24h)'),
  ('heure_fin_nuit',            '5',    'Heure de fin de la plage nuit (format 24h)'),
  ('bonus_volume_tier1_pct',    '2',    'Bonus volume : 10-24 courses/mois → 2% des commissions'),
  ('bonus_volume_tier2_pct',    '4',    'Bonus volume : 25-49 courses/mois → 4% des commissions'),
  ('bonus_volume_tier3_pct',    '7',    'Bonus volume : 50+ courses/mois → 7% des commissions'),
  ('bonus_qualite_note_xaf',    '2000', 'Prime qualité : note ≥ 4.5 → 2 000 XAF'),
  ('bonus_qualite_accept_xaf',  '2000', 'Prime qualité : taux acceptation > 80% → 2 000 XAF'),
  ('streak_client_xaf',         '100',  'Bonus streak : 3 courses en 1 semaine → 100 XAF'),
  ('kyc_commission_duree_j',    '7',    'Durée (jours) du bonus commission KYC'),
  ('kyc_commission_taux',       '0.10', 'Taux commission pendant la période KYC (10% vs 20% standard)')
ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur, updated_at = NOW();


-- ══════════════════════════════════════════════════════════════════════════════
-- 11. VUES PRATIQUES
-- ══════════════════════════════════════════════════════════════════════════════

-- Vue admin : documents KYC avec alertes d'expiration
CREATE OR REPLACE VIEW public.kyc_validite AS
SELECT
  k.user_id, k.type_vehicule, k.statut_kyc,
  k.cni_expiration, k.permis_expiration,
  (k.cni_expiration    - CURRENT_DATE)::INTEGER AS cni_jours_restants,
  (k.permis_expiration - CURRENT_DATE)::INTEGER AS permis_jours_restants,
  CASE
    WHEN k.cni_expiration IS NULL                              THEN 'inconnu'
    WHEN k.cni_expiration < CURRENT_DATE                      THEN 'expire'
    WHEN k.cni_expiration < CURRENT_DATE + INTERVAL '30 days' THEN 'alerte'
    ELSE 'ok'
  END AS cni_statut,
  CASE
    WHEN k.permis_expiration IS NULL                              THEN 'inconnu'
    WHEN k.permis_expiration < CURRENT_DATE                      THEN 'expire'
    WHEN k.permis_expiration < CURRENT_DATE + INTERVAL '30 days' THEN 'alerte'
    ELSE 'ok'
  END AS permis_statut,
  u.nom, u.telephone
FROM public.transporteurs_kyc k
JOIN public.users u ON u.id = k.user_id
WHERE k.statut_kyc = 'approuve';


-- ══════════════════════════════════════════════════════════════════════════════
-- FIN DU SCHÉMA CAARCO
-- ══════════════════════════════════════════════════════════════════════════════
-- Pour appliquer sur un projet Supabase vide :
--   1. Dashboard → SQL Editor → New Query → Coller ce fichier → Run
--   2. Vérifier : SELECT postgis_version();
--   3. Vérifier les tables : SELECT table_name FROM information_schema.tables WHERE table_schema='public';
--   4. Vérifier les cron jobs : SELECT jobname, schedule FROM cron.job;
--   5. Insérer un utilisateur admin test si besoin via auth.users puis public.users
-- ══════════════════════════════════════════════════════════════════════════════
