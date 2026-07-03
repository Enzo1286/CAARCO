-- Migration 072 — Système de templates de notifications personnalisables
--
-- L'admin peut éditer les messages sans redéployer l'app.
-- Variables disponibles dans les templates : {nom} {nom_tr} {nom_client}
--   {montant} {distance} {depart} {arrivee} {vehicule} {otp} {rang} {jalon}
--
-- L'Edge Function 'notify' est mise à jour pour accepter :
--   { userId, template_cle, variables }  OU  { userId, titre, corps }  (compat. ancienne API)

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. Table notification_templates
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notification_templates (
  cle         TEXT        PRIMARY KEY,
  groupe      TEXT        NOT NULL DEFAULT 'general',
  description TEXT        NOT NULL,  -- Aide contextuelle pour l'admin
  variables   TEXT[]      NOT NULL DEFAULT '{}', -- Variables disponibles pour cette clé
  titre       TEXT        NOT NULL,
  corps       TEXT        NOT NULL,
  actif       BOOLEAN     NOT NULL DEFAULT TRUE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  UUID        REFERENCES users(id)
);

-- RLS : lecture par tous les authentifiés, écriture admin uniquement
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_tpl_lecture"  ON notification_templates;
DROP POLICY IF EXISTS "notif_tpl_ecriture" ON notification_templates;

CREATE POLICY "notif_tpl_lecture"
  ON notification_templates FOR SELECT
  USING (actif = TRUE OR is_admin());

CREATE POLICY "notif_tpl_ecriture"
  ON notification_templates FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

GRANT SELECT ON notification_templates TO authenticated;
GRANT UPDATE ON notification_templates TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. Seed — templates par défaut
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO notification_templates (cle, groupe, description, variables, titre, corps)
VALUES

-- ── Cours : côté CLIENT ──────────────────────────────────────────────────────
('course_confirmee_client', 'course_client',
 'Envoyé au client quand un transporteur accepte sa course.',
 ARRAY['{nom}', '{nom_tr}', '{vehicule}', '{montant}'],
 '🚗 Transporteur trouvé !',
 'Bonjour {nom} ! {nom_tr} est en route pour récupérer votre colis. ({vehicule})'
),

('tr_en_route_client', 'course_client',
 'Envoyé au client quand le TR démarre sa navigation vers le point de collecte.',
 ARRAY['{nom}', '{nom_tr}', '{distance}'],
 '📍 {nom_tr} arrive !',
 '{nom_tr} est en route vers vous — environ {distance} km.'
),

('collecte_effectuee_client', 'course_client',
 'Envoyé au client quand le TR a collecté le colis (statut → en_cours).',
 ARRAY['{nom}', '{nom_tr}', '{arrivee}'],
 '📦 Colis pris en charge',
 '{nom_tr} a récupéré votre colis. Livraison en cours vers {arrivee}.'
),

('livraison_terminee_client', 'course_client',
 'Envoyé au client quand la livraison est confirmée.',
 ARRAY['{nom}', '{montant}'],
 '✅ Livraison confirmée',
 'Bonjour {nom} ! Votre colis a été livré avec succès. Merci d''avoir choisi CAARCO.'
),

('course_annulee_client', 'course_client',
 'Envoyé au client quand sa course est annulée.',
 ARRAY['{nom}'],
 '❌ Course annulée',
 'Bonjour {nom}, votre course a été annulée. Si vous avez payé, le remboursement est en cours.'
),

-- ── Cours : côté TRANSPORTEUR ────────────────────────────────────────────────
('nouvelle_course_tr', 'course_tr',
 'Envoyé en broadcast à tous les TR compatibles quand une nouvelle course est disponible.',
 ARRAY['{depart}', '{arrivee}', '{montant}'],
 '📦 Nouvelle course disponible !',
 '{depart} → {arrivee}{montant}'
),

('paiement_recu_tr', 'course_tr',
 'Envoyé au transporteur quand le séquestre est libéré (paiement reçu).',
 ARRAY['{nom}', '{montant}'],
 '💰 Paiement reçu !',
 'Félicitations {nom} ! {montant} XAF ont été crédités sur votre wallet.'
),

('livraison_terminee_tr', 'course_tr',
 'Envoyé au transporteur quand la livraison est confirmée côté client.',
 ARRAY['{nom}', '{montant}'],
 '✅ Course terminée',
 'Bravo {nom} ! Course terminée. {montant} XAF sont en cours de versement.'
),

-- ── KYC ─────────────────────────────────────────────────────────────────────
('kyc_approuve_tr', 'kyc',
 'Envoyé au transporteur quand son dossier KYC est approuvé.',
 ARRAY['{nom}'],
 '🎉 Compte vérifié !',
 'Félicitations {nom} ! Votre dossier a été validé. Vous pouvez maintenant accepter des courses.'
),

('kyc_rejete_tr', 'kyc',
 'Envoyé au transporteur quand son dossier KYC est rejeté.',
 ARRAY['{nom}'],
 '⚠ Dossier incomplet',
 'Bonjour {nom}, votre dossier KYC nécessite des corrections. Vérifiez les détails dans l''app.'
),

('kyc_info_manquantes_tr', 'kyc',
 'Envoyé quand le dossier KYC est en attente d''informations supplémentaires.',
 ARRAY['{nom}'],
 '📋 Informations manquantes',
 'Bonjour {nom}, des informations supplémentaires sont requises pour votre dossier. Connectez-vous pour les fournir.'
),

-- ── Fidélité ─────────────────────────────────────────────────────────────────
('jalon_client', 'fidelite',
 'Envoyé au client quand il franchit un jalon de fidélité.',
 ARRAY['{nom}', '{jalon}', '{montant}'],
 '🏅 Nouveau niveau atteint !',
 'Félicitations {nom} ! Vous avez atteint {jalon} courses. Un bonus de {montant} XAF vous a été offert !'
),

('classement_top10_tr', 'fidelite',
 'Envoyé au transporteur quand il entre dans le top 10 mensuel.',
 ARRAY['{nom}', '{rang}'],
 '🏆 Vous êtes dans le Top {rang} !',
 'Bravo {nom} ! Vous êtes #{rang} au classement de ce mois. Continuez pour rester dans le top !'
),

-- ── Finance ──────────────────────────────────────────────────────────────────
('retrait_traite_tr', 'finance',
 'Envoyé au transporteur quand son retrait Mobile Money est effectué.',
 ARRAY['{nom}', '{montant}'],
 '💸 Retrait effectué',
 '{montant} XAF ont été virés sur votre compte Mobile Money. Merci {nom} !'
),

('retrait_refuse_tr', 'finance',
 'Envoyé au transporteur quand son retrait est refusé.',
 ARRAY['{nom}', '{montant}'],
 '⚠ Retrait refusé',
 'Bonjour {nom}, votre demande de retrait de {montant} XAF a été refusée. Contactez le support.'
),

('credit_wallet', 'finance',
 'Envoyé quand l''admin crédite le wallet d''un utilisateur.',
 ARRAY['{nom}', '{montant}'],
 '🎁 Crédit ajouté',
 'Bonjour {nom} ! {montant} XAF ont été ajoutés à votre wallet CAARCO.'
),

-- ── Litiges ──────────────────────────────────────────────────────────────────
('litige_ouvert', 'litige',
 'Envoyé aux deux parties quand un litige est ouvert.',
 ARRAY['{nom}'],
 '⚖ Litige en cours',
 'Bonjour {nom}, un litige a été ouvert pour votre course. L''équipe CAARCO va trancher sous 24h.'
),

('litige_resolu', 'litige',
 'Envoyé quand l''admin clôture un litige.',
 ARRAY['{nom}'],
 '✅ Litige résolu',
 'Bonjour {nom}, votre litige a été résolu par l''équipe CAARCO. Consultez l''app pour les détails.'
)

ON CONFLICT (cle) DO NOTHING;

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. Fonction d'interpolation (utilisée dans les Edge Functions + RPCs)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION notif_interpoler(p_cle TEXT, p_vars JSONB)
RETURNS TABLE(titre TEXT, corps TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_titre TEXT;
  v_corps TEXT;
  v_cle   TEXT;
  v_val   TEXT;
BEGIN
  SELECT t.titre, t.corps
    INTO v_titre, v_corps
    FROM notification_templates t
   WHERE t.cle = p_cle AND t.actif = TRUE;

  IF NOT FOUND THEN
    RETURN; -- Pas de template → l'appelant utilisera ses valeurs par défaut
  END IF;

  -- Remplacer toutes les variables {key} par leurs valeurs
  IF p_vars IS NOT NULL THEN
    FOR v_cle, v_val IN
      SELECT key, value::TEXT
        FROM jsonb_each_text(p_vars)
    LOOP
      v_titre := REPLACE(v_titre, '{' || v_cle || '}', COALESCE(v_val, ''));
      v_corps := REPLACE(v_corps, '{' || v_cle || '}', COALESCE(v_val, ''));
    END LOOP;
  END IF;

  RETURN QUERY SELECT v_titre, v_corps;
END;
$$;

GRANT EXECUTE ON FUNCTION notif_interpoler(TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION notif_interpoler(TEXT, JSONB) TO service_role;
