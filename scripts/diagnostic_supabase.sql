-- ═══════════════════════════════════════════════════════════════
-- DIAGNOSTIC CAARCO — état réel de la base de production
--
-- MODE D'EMPLOI : tout copier, coller dans Supabase → SQL Editor,
-- cliquer Run. UNE SEULE requête, UN SEUL tableau de résultats.
-- Rien à sélectionner, rien à lancer bloc par bloc.
--
-- 100% LECTURE SEULE — ne modifie rien.
-- ═══════════════════════════════════════════════════════════════

WITH marqueurs(migration, sujet, genre, nom) AS (
  VALUES
    ('085', 'Sécurité TC + verrou courses',   'trigger', 'trg_courses_protege'),
    ('092', 'Verrou transitions de statut',   'fonction','changer_statut_course'),
    ('093', 'Journal d''audit admin',         'table',   'audit_admin'),
    ('094', '2FA TOTP admin',                 'fonction','admin_aal_suffisant'),
    ('095', 'Conflit horaire planifié',       'colonne', 'parametres_tarifs.marge_securite_min'),
    ('096', 'Paiements acceptés par le TR',   'colonne', 'users.paiements_acceptes'),
    ('098', 'Corrections sécurité 08/07',     'trigger', 'trg_verrouiller_prix_creation'),
    ('099', 'Super-admin : colonne',          'colonne', 'users.permissions'),
    ('099', 'Super-admin : fonction',         'fonction','is_super_admin'),
    ('100', 'Reset mot de passe (journal)',   'table',   'reset_mot_de_passe_log'),
    ('101', 'Jalons fidélité sans wallet',    'fonction','attribuer_jalon_client'),
    ('102', 'Packs commission réelle',        'fonction','admin_activer_pack_tr'),
    ('104', 'Commission perso : colonne',     'colonne', 'users.commission_taux_pct'),
    ('104', 'Commission perso : RPC',         'fonction','admin_definir_commission_personnalisee'),
    ('105', 'Expiration documents TR',        'colonne', 'transporteurs_kyc.assurance_expiration'),
    ('107', 'users.updated_at',               'colonne', 'users.updated_at'),
    ('108', 'Motif d''annulation',            'colonne', 'courses.motif_annulation')
),

resultat(tri, bloc, element, verdict) AS (

  -- ── 1. Migrations réellement appliquées (085 → 108) ──────────────────
  SELECT 1, 'MIGRATIONS', migration || ' — ' || sujet,
    CASE
      WHEN CASE genre
        WHEN 'fonction' THEN EXISTS (
          SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE n.nspname = 'public' AND p.proname = nom)
        WHEN 'trigger'  THEN EXISTS (
          SELECT 1 FROM pg_trigger WHERE tgname = nom AND NOT tgisinternal)
        WHEN 'table'    THEN to_regclass('public.' || nom) IS NOT NULL
        WHEN 'colonne'  THEN EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name  = split_part(nom, '.', 1)
            AND column_name = split_part(nom, '.', 2))
      END THEN '✅ APPLIQUÉE'
      ELSE '❌ MANQUANTE'
    END
  FROM marqueurs

  -- ── 2. Version de calculer_prix() (097 vs 103, même signature) ───────
  UNION ALL
  SELECT 2, 'PRIX', 'calculer_prix()',
    CASE
      WHEN NOT EXISTS (
        SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'calculer_prix')
        THEN '❌ ABSENTE'
      WHEN EXISTS (
        SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'calculer_prix'
          AND pg_get_functiondef(p.oid) ILIKE '%poids_max_kg%')
        THEN '✅ version 103 (charge utile réelle)'
      ELSE '⚠️ version 097 ou antérieure — 103 non appliquée'
    END

  -- ── 3. Comptes admin et super-admin ──────────────────────────────────
  -- to_jsonb() lit les colonnes réellement présentes : la requête ne casse
  -- pas si `permissions` n'existe pas encore (099 non appliquée).
  UNION ALL
  SELECT 3, 'ADMINS',
    COALESCE(to_jsonb(u) ->> 'telephone', '?') || ' — ' || COALESCE(to_jsonb(u) ->> 'nom', '?'),
    CASE
      WHEN to_jsonb(u) ->> 'permissions' IS NULL
        THEN '⚠️ admin (colonne permissions absente → 099 non appliquée)'
      WHEN to_jsonb(u) ->> 'permissions' LIKE '%super_admin%'
        THEN '👑 SUPER-ADMIN'
      ELSE 'admin simple — permissions : ' || (to_jsonb(u) ->> 'permissions')
    END
  FROM public.users u
  WHERE u.role = 'admin'

  -- ── 4. 2FA réellement actif sur les comptes admin ? ──────────────────
  UNION ALL
  SELECT 4, '2FA ADMIN',
    COALESCE(to_jsonb(u) ->> 'telephone', '?') || ' — ' || COALESCE(to_jsonb(u) ->> 'nom', '?'),
    CASE
      WHEN f.status IS NULL THEN '❌ AUCUN FACTEUR — mot de passe seul'
      WHEN f.status::text = 'verified' THEN '✅ 2FA actif (' || f.factor_type || ')'
      ELSE '⚠️ facteur ' || f.status::text
    END
  FROM public.users u
  LEFT JOIN auth.mfa_factors f ON f.user_id = u.id
  WHERE u.role = 'admin'

  -- ── 5. Garde-fou anti-escalade de privilèges ─────────────────────────
  UNION ALL
  SELECT 5, 'SÉCURITÉ', 'trigger ' || tgname,
    CASE tgenabled
      WHEN 'O' THEN '✅ actif'
      WHEN 'D' THEN '❌ DÉSACTIVÉ'
      ELSE tgenabled::text
    END
  FROM pg_trigger
  WHERE tgrelid = 'public.users'::regclass
    AND NOT tgisinternal
    AND tgname = 'role_security_trigger'
)

SELECT bloc, element, verdict
FROM resultat
ORDER BY tri, element;
