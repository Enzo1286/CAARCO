-- ══════════════════════════════════════════════════════════════════
-- Migration 065 — Table publicites (espaces publicitaires in-app)
-- Géré depuis le Dashboard Supabase, sans toucher au code
-- ══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.publicites (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre      TEXT    NOT NULL,                       -- Nom interne (ex: "Bannière juin 2026")
  image_url  TEXT    NOT NULL,                       -- URL Supabase Storage bucket "publicites"
  lien_url   TEXT,                                   -- URL ouverte au clic (NULL = pas de lien)
  debut      TIMESTAMPTZ NOT NULL DEFAULT NOW(),     -- Début d'affichage
  fin        TIMESTAMPTZ,                            -- NULL = permanent
  actif      BOOLEAN NOT NULL DEFAULT true,          -- false = masqué sans suppression
  ordre      INTEGER NOT NULL DEFAULT 0,             -- Ordre dans le carousel (0 = premier)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.publicites ENABLE ROW LEVEL SECURITY;

-- Tous les utilisateurs connectés peuvent lire les publicités actives
CREATE POLICY "publicites_lecture" ON public.publicites
  FOR SELECT USING (actif = true);

-- Seul le service_role (admin) peut insérer/modifier/supprimer
-- Les admins passent par le Dashboard Supabase → pas de policy INSERT/UPDATE/DELETE côté client

-- Index pour la requête principale (filtres actif + dates + ordre)
CREATE INDEX IF NOT EXISTS idx_publicites_actif_dates
  ON public.publicites (actif, debut, fin, ordre);

-- Bucket Supabase Storage pour les images publicitaires (public = lecture sans auth)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'publicites',
  'publicites',
  true,
  5242880,                              -- 5 Mo max par image
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Politique de lecture publique sur le bucket
CREATE POLICY "publicites_bucket_lecture" ON storage.objects
  FOR SELECT USING (bucket_id = 'publicites');

-- Seul le service_role peut uploader
CREATE POLICY "publicites_bucket_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'publicites'
    AND auth.role() = 'service_role'
  );
