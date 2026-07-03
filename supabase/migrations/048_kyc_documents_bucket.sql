-- Migration 048 : créer le bucket kyc-documents pour les dossiers KYC transporteurs

-- Créer le bucket (privé — les docs KYC ne doivent pas être publics par défaut)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kyc-documents',
  'kyc-documents',
  true,                          -- public pour que les URLs de prévisualisation admin fonctionnent
  10485760,                      -- 10 MB max par fichier
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- RLS Storage : le TR peut uploader dans son propre dossier kyc/<user_id>/
CREATE POLICY "kyc_upload_owner"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc-documents'
  AND (storage.foldername(name))[1] = 'kyc'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Le TR peut lire/supprimer ses propres fichiers KYC
CREATE POLICY "kyc_select_owner"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc-documents'
  AND (storage.foldername(name))[1] = 'kyc'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Mise à jour (upsert) — nécessaire car on utilise upsert: true dans le code
CREATE POLICY "kyc_update_owner"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'kyc-documents'
  AND (storage.foldername(name))[1] = 'kyc'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Admin peut tout lire pour la validation KYC
CREATE POLICY "kyc_admin_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc-documents'
  AND EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  )
);
