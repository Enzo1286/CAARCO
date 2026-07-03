-- ═══════════════════════════════════════════════════════
-- TABLE lieux — Points de référence CAARCO
-- ═══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.lieux (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom          TEXT NOT NULL,
  categorie    TEXT DEFAULT 'Autre'
                 CHECK (categorie IN (
                   'Marché','École','Hôpital','Mosquée / Église',
                   'Quartier','Carrefour','Station essence','Hôtel',
                   'Pharmacie','Atelier / Garage','Autre'
                 )),
  lat          DOUBLE PRECISION NOT NULL,
  lng          DOUBLE PRECISION NOT NULL,
  ville        TEXT DEFAULT 'Bafoussam',
  statut       TEXT NOT NULL DEFAULT 'en_attente'
                 CHECK (statut IN ('en_attente','valide','rejete')),
  createur_id  UUID REFERENCES public.users(id) ON DELETE SET NULL,
  valide_par   UUID REFERENCES public.users(id) ON DELETE SET NULL,
  valide_at    TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS lieux_statut_idx ON public.lieux (statut);
CREATE INDEX IF NOT EXISTS lieux_lat_lng_idx ON public.lieux (lat, lng);

-- RLS
ALTER TABLE public.lieux ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut lire les lieux validés
CREATE POLICY "lieux_lecture_valides" ON public.lieux
  FOR SELECT USING (statut = 'valide' OR auth.uid() = createur_id OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Tout utilisateur connecté peut proposer un lieu
CREATE POLICY "lieux_insert_connecte" ON public.lieux
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = createur_id);

-- Admin peut mettre à jour (valider/rejeter)
CREATE POLICY "lieux_update_admin" ON public.lieux
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- ═══════════════════════════════════════════════════════
-- RPC lieux_proches — trouve les lieux dans un rayon (mètres)
-- ═══════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.lieux_proches(
  p_lat      DOUBLE PRECISION,
  p_lng      DOUBLE PRECISION,
  p_rayon_m  INTEGER DEFAULT 50
) RETURNS TABLE (
  id        UUID,
  nom       TEXT,
  categorie TEXT,
  lat       DOUBLE PRECISION,
  lng       DOUBLE PRECISION,
  statut    TEXT,
  distance_m DOUBLE PRECISION
)
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT
    id, nom, categorie, lat, lng, statut,
    (6371000 * acos(
      LEAST(1.0, cos(radians(p_lat)) * cos(radians(lat)) *
      cos(radians(lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(lat)))
    )) AS distance_m
  FROM public.lieux
  WHERE (statut = 'valide' OR statut = 'en_attente')
    AND (6371000 * acos(
      LEAST(1.0, cos(radians(p_lat)) * cos(radians(lat)) *
      cos(radians(lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(lat)))
    )) <= p_rayon_m
  ORDER BY distance_m ASC
  LIMIT 5;
$$;

-- ═══════════════════════════════════════════════════════
-- RPC rechercher_lieux — recherche textuelle pour autocomplétion
-- ═══════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.rechercher_lieux(
  p_texte TEXT,
  p_limit  INTEGER DEFAULT 8
) RETURNS TABLE (
  id        UUID,
  nom       TEXT,
  categorie TEXT,
  lat       DOUBLE PRECISION,
  lng       DOUBLE PRECISION,
  ville     TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT id, nom, categorie, lat, lng, ville
  FROM public.lieux
  WHERE statut = 'valide'
    AND (
      lower(nom)      ILIKE '%' || lower(p_texte) || '%' OR
      lower(ville)    ILIKE '%' || lower(p_texte) || '%' OR
      lower(categorie) ILIKE '%' || lower(p_texte) || '%'
    )
  ORDER BY
    CASE WHEN lower(nom) ILIKE lower(p_texte) || '%' THEN 0 ELSE 1 END,
    nom ASC
  LIMIT p_limit;
$$;
