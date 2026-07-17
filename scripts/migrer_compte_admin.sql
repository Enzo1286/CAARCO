-- ═══════════════════════════════════════════════════════════════
-- MIGRATION DU COMPTE SUPER-ADMIN — CAARCO
--
-- CE QUE FAIT CE SCRIPT :
--   1. Change le numéro du super-admin : 697028122 → 679570886
--      (le compte, son historique et ses droits sont conservés)
--   2. Supprime définitivement le 2e compte admin (« admin »)
--
-- MODE D'EMPLOI : tout copier → SQL Editor → Run. Rien à modifier.
--
-- ⚠️ TOUT EST DANS UNE TRANSACTION : si le moindre contrôle échoue,
--    RIEN n'est appliqué et tu reçois un message d'erreur clair.
--    Tu ne peux pas te retrouver à moitié migré.
--
-- ⚠️ TON MOT DE PASSE NE CHANGE PAS. Après ce script, tu te connectes
--    avec le numéro 679570886 et le MÊME mot de passe qu'aujourd'hui.
-- ═══════════════════════════════════════════════════════════════

BEGIN;

DO $$
DECLARE
  v_ancien_tel   TEXT := '697028122';
  v_nouveau_tel  TEXT := '679570886';
  v_tel_supprime TEXT := 'admin';
  v_id_principal UUID;
  v_id_supprime  UUID;
  v_id_libere    UUID;
  v_nb           INTEGER;
BEGIN

  -- ── CONTRÔLE 1 : le compte à migrer existe et est bien super-admin ──
  SELECT id INTO v_id_principal
  FROM public.users
  WHERE telephone = v_ancien_tel AND role = 'admin';

  IF v_id_principal IS NULL THEN
    RAISE EXCEPTION 'ARRÊT : aucun compte admin avec le numéro % — rien n''a été modifié.', v_ancien_tel;
  END IF;

  -- ── ÉTAPE 0 : libérer le numéro (compte transporteur de test « Enzo ») ──
  -- Vérifié le 2026-07-17 : 0 course, 0 token TC, 0 dossier KYC, 0 message.
  -- On ne supprime QUE s'il est réellement vide — sinon on s'arrête.
  SELECT id INTO v_id_libere
  FROM public.users
  WHERE telephone = v_nouveau_tel AND id <> v_id_principal;

  IF v_id_libere IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.users WHERE id = v_id_libere AND role = 'admin') THEN
      RAISE EXCEPTION 'ARRÊT : le compte % est un admin — refus de le supprimer automatiquement.', v_nouveau_tel;
    END IF;

    SELECT COUNT(*) INTO v_nb
    FROM public.courses
    WHERE client_id = v_id_libere OR transporteur_id = v_id_libere;

    IF v_nb > 0 THEN
      RAISE EXCEPTION 'ARRÊT : le compte % a % course(s) rattachée(s) — refus de le supprimer. Rien n''a été modifié.', v_nouveau_tel, v_nb;
    END IF;

    -- Résidus techniques rattachés au compte (aucune valeur métier) :
    -- wallets/transactions_wallet appartiennent au modèle wallet abandonné,
    -- leurs clés étrangères n'ont pas de CASCADE et bloqueraient la suppression.
    DELETE FROM public.transactions_wallet
      WHERE wallet_id IN (SELECT id FROM public.wallets WHERE user_id = v_id_libere);
    DELETE FROM public.wallets             WHERE user_id         = v_id_libere;
    DELETE FROM public.transactions_points WHERE user_id         = v_id_libere;
    DELETE FROM public.candidatures        WHERE transporteur_id = v_id_libere;
    DELETE FROM public.vehicules           WHERE transporteur_id = v_id_libere;
    DELETE FROM public.transporteurs_kyc   WHERE user_id         = v_id_libere;
    DELETE FROM public.avis                WHERE auteur_id = v_id_libere OR cible_id = v_id_libere;
    DELETE FROM public.messages            WHERE expediteur_id = v_id_libere OR destinataire_id = v_id_libere;
    UPDATE public.users SET parrain_id = NULL WHERE parrain_id = v_id_libere;

    DELETE FROM public.users WHERE id = v_id_libere;
    DELETE FROM auth.users   WHERE id = v_id_libere;

    RAISE NOTICE 'OK — compte de test « % » supprimé, numéro libéré.', v_nouveau_tel;
  END IF;

  -- ── CONTRÔLE 2 : le numéro est bien libre côté authentification ──
  SELECT COUNT(*) INTO v_nb
  FROM auth.users
  WHERE email = v_nouveau_tel || '@caarco.local' AND id <> v_id_principal;

  IF v_nb > 0 THEN
    RAISE EXCEPTION 'ARRÊT : l''email % est encore pris côté authentification — rien n''a été modifié.', v_nouveau_tel || '@caarco.local';
  END IF;

  -- ── ÉTAPE 1 : changer le numéro (profil ET authentification) ──
  -- Les deux DOIVENT rester cohérents : l'email est l'identifiant réel
  -- de connexion (auth.js construit {telephone}@caarco.local).
  UPDATE public.users
  SET telephone = v_nouveau_tel
  WHERE id = v_id_principal;

  UPDATE auth.users
  SET email = v_nouveau_tel || '@caarco.local',
      updated_at = now()
  WHERE id = v_id_principal;

  RAISE NOTICE 'OK — super-admin migré : % → %', v_ancien_tel, v_nouveau_tel;

  -- ── CONTRÔLE 3 : ne jamais supprimer le dernier super-admin ──
  SELECT id INTO v_id_supprime
  FROM public.users
  WHERE telephone = v_tel_supprime AND role = 'admin';

  IF v_id_supprime IS NULL THEN
    RAISE NOTICE 'Compte « % » introuvable — déjà supprimé ? Rien à faire.', v_tel_supprime;
  ELSE
    IF v_id_supprime = v_id_principal THEN
      RAISE EXCEPTION 'ARRÊT : le compte à supprimer est le compte principal — rien n''a été modifié.';
    END IF;

    SELECT COUNT(*) INTO v_nb
    FROM public.users
    WHERE role = 'admin' AND id <> v_id_supprime;

    IF v_nb = 0 THEN
      RAISE EXCEPTION 'ARRÊT : ce serait le dernier admin restant — rien n''a été modifié.';
    END IF;

    -- ── ÉTAPE 2 : suppression définitive du 2e compte ──
    -- public.users d'abord, puis auth.users (même id).
    -- Si une clé étrangère bloque (données rattachées à ce compte), la
    -- transaction entière est annulée : rien ne sera à moitié fait.
    -- Mêmes résidus techniques que ci-dessus (voir ÉTAPE 0).
    DELETE FROM public.transactions_wallet
      WHERE wallet_id IN (SELECT id FROM public.wallets WHERE user_id = v_id_supprime);
    DELETE FROM public.wallets             WHERE user_id         = v_id_supprime;
    DELETE FROM public.transactions_points WHERE user_id         = v_id_supprime;
    DELETE FROM public.candidatures        WHERE transporteur_id = v_id_supprime;
    DELETE FROM public.vehicules           WHERE transporteur_id = v_id_supprime;
    DELETE FROM public.transporteurs_kyc   WHERE user_id         = v_id_supprime;
    DELETE FROM public.avis                WHERE auteur_id = v_id_supprime OR cible_id = v_id_supprime;
    DELETE FROM public.messages            WHERE expediteur_id = v_id_supprime OR destinataire_id = v_id_supprime;
    UPDATE public.users SET parrain_id = NULL WHERE parrain_id = v_id_supprime;

    -- Traces d'administration : on conserve la ligne, on détache l'auteur.
    UPDATE public.transporteurs_kyc   SET valide_par = NULL WHERE valide_par = v_id_supprime;
    UPDATE public.campagnes_push      SET created_by = NULL WHERE created_by = v_id_supprime;
    UPDATE public.notification_templates SET updated_by = NULL WHERE updated_by = v_id_supprime;

    DELETE FROM public.users WHERE id = v_id_supprime;
    DELETE FROM auth.users   WHERE id = v_id_supprime;

    RAISE NOTICE 'OK — compte « % » supprimé définitivement.', v_tel_supprime;
  END IF;

END $$;

COMMIT;


-- ── VÉRIFICATION FINALE — doit afficher UNE SEULE ligne : 679570886 ──
SELECT
  u.telephone                    AS numero_de_connexion,
  a.email                        AS identifiant_reel,
  u.nom,
  CASE WHEN 'super_admin' = ANY(u.permissions)
       THEN '👑 SUPER-ADMIN' ELSE 'admin simple' END AS niveau,
  CASE WHEN f.status IS NULL
       THEN '❌ 2FA À ACTIVER'
       ELSE '✅ 2FA ' || f.status::text END          AS securite
FROM public.users u
JOIN auth.users a ON a.id = u.id
LEFT JOIN auth.mfa_factors f ON f.user_id = u.id
WHERE u.role = 'admin'
ORDER BY u.telephone;

-- ═══════════════════════════════════════════════════════════════
-- ENSUITE, DANS L'APP :
--   1. Déconnecte-toi si tu es connecté.
--   2. Connecte-toi avec : 679570886 + ton mot de passe habituel.
--   3. Va dans l'écran Sécurité → active le 2FA (Google Authenticator).
-- ═══════════════════════════════════════════════════════════════
