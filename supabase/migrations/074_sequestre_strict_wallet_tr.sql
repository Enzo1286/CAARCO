-- Migration 074 — Séquestre strict : terminer_livraison vérifie le paiement client + crédite le wallet TR
--
-- Problème résolu : le TR pouvait cliquer "Livré" sans que le client ait payé.
-- Avant cette migration : terminer_livraison marquait la course terminée SANS créditer le wallet.
-- Après cette migration :
--   · Mobile Money (orange_money / mtn_momo) : paiement doit être en 'sequestre' → sinon ERREUR
--     → liberer_sequestre_course fait le crédit wallet + commission + parrainage
--   · Espèces / Wallet / méthode inconnue : termination directe (pas de séquestre applicable)
--
-- Nouveau template de notification : informer le TR que le client a payé (séquestre en attente de livraison)

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. Réécriture de terminer_livraison
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION terminer_livraison(p_course_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_course  RECORD;
  v_methode TEXT;
  v_wallet  jsonb;
BEGIN
  -- Vérifier la course
  SELECT * INTO v_course FROM public.courses WHERE id = p_course_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'COURSE_INTROUVABLE' USING HINT = 'Course inexistante.';
  END IF;

  IF auth.uid() != v_course.transporteur_id THEN
    RAISE EXCEPTION 'NON_AUTORISE' USING HINT = 'Seul le transporteur assigné peut terminer la course.';
  END IF;

  IF LOWER(v_course.statut) NOT IN ('en_cours', 'acceptee') THEN
    RAISE EXCEPTION 'STATUT_INVALIDE'
      USING HINT = format('Statut actuel: %s — attendu en_cours ou acceptee.', v_course.statut);
  END IF;

  v_methode := LOWER(COALESCE(v_course.methode_paiement, ''));

  -- ── Cours Mobile Money : vérifier le séquestre + créditer le wallet ─────────
  IF v_methode IN ('orange_money', 'mtn_momo') THEN

    -- Vérifier que le client a bien payé (paiement en séquestre)
    IF NOT EXISTS (
      SELECT 1 FROM public.paiements
       WHERE course_id = p_course_id
         AND LOWER(statut) = 'sequestre'
    ) THEN
      RAISE EXCEPTION 'PAIEMENT_NON_RECU'
        USING HINT = 'Le client n''a pas encore payé. Attendez sa confirmation avant de cliquer Livré.';
    END IF;

    -- liberer_sequestre_course : crédite le wallet TR (commission dynamique) + termine la course
    SELECT liberer_sequestre_course(p_course_id) INTO v_wallet;

    RETURN jsonb_build_object(
      'success',   true,
      'course_id', p_course_id,
      'statut',    'terminee',
      'wallet',    v_wallet
    );
  END IF;

  -- ── Espèces / Wallet / méthode inconnue : termination directe ───────────────
  UPDATE public.courses SET
    statut       = 'terminee',
    completed_at = NOW(),
    updated_at   = NOW()
  WHERE id = p_course_id;

  UPDATE public.paiements SET
    statut    = 'libere',
    libere_at = NOW()
  WHERE course_id = p_course_id
    AND LOWER(statut) IN ('en_attente', 'initie', 'sequestre');

  RETURN jsonb_build_object(
    'success',   true,
    'course_id', p_course_id,
    'statut',    'terminee'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION terminer_livraison(UUID) TO authenticated;

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. Nouveau template — informer le TR que le client a payé (avant livraison)
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO notification_templates (cle, groupe, description, variables, titre, corps)
VALUES (
  'client_paye_sequestre_tr',
  'course_tr',
  'Envoyé au TR quand le client clique Conclure (paiement en séquestre, wallet crédité après livraison).',
  ARRAY['{nom}', '{nom_client}', '{montant}', '{net_montant}'],
  '💳 Client a payé !',
  'Bonjour {nom} ! {nom_client} a payé {montant} XAF. Ton solde de {net_montant} XAF sera crédité dès que tu cliques sur Livré.'
)
ON CONFLICT (cle) DO UPDATE SET
  titre      = EXCLUDED.titre,
  corps      = EXCLUDED.corps,
  variables  = EXCLUDED.variables,
  updated_at = NOW();

-- Mettre à jour le template paiement_recu_tr (déclenché APRÈS la livraison, quand le wallet est réellement crédité)
UPDATE notification_templates
SET
  titre      = '💰 Wallet crédité !',
  corps      = 'Bonjour {nom} ! {montant} XAF ont été crédités sur votre wallet CAARCO. Vous pouvez retirer vers Mobile Money quand vous le souhaitez.',
  updated_at = NOW()
WHERE cle = 'paiement_recu_tr';
