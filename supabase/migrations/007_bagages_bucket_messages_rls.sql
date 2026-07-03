-- Migration 007 : bucket bagages + désactivation RLS messages

-- 1. Créer/mettre en mode public le bucket 'bagages'
INSERT INTO storage.buckets (id, name, public)
VALUES ('bagages', 'bagages', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Politique d'accès au bucket bagages
DROP POLICY IF EXISTS "bagages_acces" ON storage.objects;
CREATE POLICY "bagages_acces" ON storage.objects
  FOR ALL
  USING (bucket_id = 'bagages' AND auth.uid() IS NOT NULL)
  WITH CHECK (bucket_id = 'bagages' AND auth.uid() IS NOT NULL);

-- 3. Désactiver RLS sur messages (debug — réactiver une fois le trigger validé)
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
