-- ═══════════════════════════════════════════════════════════════
-- RÉINITIALISER LE MOT DE PASSE ADMIN — CAARCO
--
-- Compte admin UNIQUE depuis le 2026-07-17 : numéro 679570886.
-- (Les anciens comptes 697028122 et « admin » n'existent plus :
--  697028122 a été migré vers 679570886, « admin » a été supprimé.)
--
-- TU N'AS QU'UNE SEULE CHOSE À FAIRE :
-- remplacer le mot en MAJUSCULES ligne 24 par ton nouveau mot de passe.
-- Puis tout copier → Supabase Dashboard → SQL Editor → Run.
--
-- Garde les guillemets simples ' ' autour du mot de passe !
-- Ton 2FA (TOTP) reste inchangé : aucun risque de verrouillage.
-- ═══════════════════════════════════════════════════════════════

-- (Prépare l'outil de chiffrement — ne touche à rien de tes données)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
SET search_path TO extensions, public, auth;


-- ── COMPTE ADMIN — numéro 679570886 ──
UPDATE auth.users
SET
  encrypted_password = crypt(

    'METS_ICI_TON_NOUVEAU_MOT_DE_PASSE'   -- ← REMPLACE (garde les ' ')

  , gen_salt('bf')),
  updated_at = now()
WHERE email = '679570886@caarco.local';


-- ── Vérification finale : affiche le résultat ──
SELECT
  u.email AS identifiant_de_connexion,
  CASE
    WHEN u.updated_at > now() - interval '1 minute'
      THEN '✅ mot de passe réinitialisé à l''instant'
    ELSE '❌ NON modifié — vérifie l''email ci-dessus'
  END AS resultat
FROM auth.users u
WHERE u.email = '679570886@caarco.local';

-- ═══════════════════════════════════════════════════════════════
-- ENSUITE : dans l'app CAARCO (ou le portail web admin), connecte-toi
-- avec le numéro 679570886 + ton nouveau mot de passe, puis complète
-- le défi 2FA habituel. Aucune reconfiguration du 2FA n'est nécessaire.
-- ═══════════════════════════════════════════════════════════════
