-- Migration 042 : Normalisation des numéros de téléphone
-- Certains comptes ont été créés avec +237... dans l'email auth,
-- mais le login génère 237...@caarco.local → connexion impossible.
-- Ce script corrige les emails dans auth.users pour les aligner avec le login.

-- ⚠️  À exécuter avec le rôle service_role dans Supabase SQL Editor
-- (Auth API — accessible uniquement via service_role)

-- 1. Corriger les emails auth.users qui commencent par "+"
UPDATE auth.users
SET email = regexp_replace(email, '^\+', '', 'i')
WHERE email LIKE '+%@caarco.local';

-- 2. Détecter les comptes "fantômes" (auth.users sans public.users)
-- Exécuter séparément pour diagnostic :
-- SELECT au.id, au.email, au.created_at
-- FROM auth.users au
-- WHERE email LIKE '%@caarco.local'
-- AND NOT EXISTS (SELECT 1 FROM public.users pu WHERE pu.id = au.id)
-- ORDER BY au.created_at DESC;

-- 3. Supprimer les comptes fantômes si nécessaire (optionnel)
-- DELETE FROM auth.users
-- WHERE email LIKE '%@caarco.local'
-- AND NOT EXISTS (SELECT 1 FROM public.users pu WHERE pu.id = auth.users.id);
