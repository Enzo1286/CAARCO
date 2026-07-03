-- Migration 038 : Remise à zéro d'un compte ou de tous les comptes (admin)
-- RPCs protégées par SECURITY DEFINER

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Réinitialiser UN compte utilisateur
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_reset_compte(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_solde_actuel  INTEGER;
  v_nb_courses    INTEGER;
BEGIN
  -- Annuler toutes les courses actives où l'utilisateur est client ou transporteur
  UPDATE courses
  SET statut = 'annulee', updated_at = NOW()
  WHERE statut IN ('en_attente', 'en_recherche', 'acceptee', 'en_cours')
    AND (client_id = p_user_id OR transporteur_id = p_user_id);

  GET DIAGNOSTICS v_nb_courses = ROW_COUNT;

  -- Lire le solde actuel du wallet
  SELECT COALESCE(solde_fcfa, 0)
    INTO v_solde_actuel
    FROM wallets
   WHERE user_id = p_user_id;

  -- Enregistrer un mouvement de remise à zéro si le solde n'est pas déjà nul
  IF v_solde_actuel > 0 THEN
    INSERT INTO transactions_wallet (user_id, type, montant_fcfa, description)
    VALUES (p_user_id, 'retrait', v_solde_actuel, 'Remise à zéro du compte par admin');
  END IF;

  -- Mettre le solde à 0
  UPDATE wallets
  SET solde_fcfa = 0, updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Créer le wallet si inexistant (cas rare)
  IF NOT FOUND THEN
    INSERT INTO wallets (user_id, solde_fcfa)
    VALUES (p_user_id, 0)
    ON CONFLICT (user_id) DO UPDATE SET solde_fcfa = 0, updated_at = NOW();
  END IF;

  RETURN jsonb_build_object(
    'ok',            true,
    'user_id',       p_user_id,
    'courses_annulees', v_nb_courses,
    'solde_retire',  v_solde_actuel
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Réinitialiser TOUS les comptes (opération globale)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_reset_tous_comptes()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nb_courses  INTEGER;
  v_nb_wallets  INTEGER;
BEGIN
  -- Annuler toutes les courses actives sans exception
  UPDATE courses
  SET statut = 'annulee', updated_at = NOW()
  WHERE statut IN ('en_attente', 'en_recherche', 'acceptee', 'en_cours');

  GET DIAGNOSTICS v_nb_courses = ROW_COUNT;

  -- Enregistrer un retrait pour chaque wallet avec un solde positif
  INSERT INTO transactions_wallet (user_id, type, montant_fcfa, description)
  SELECT user_id, 'retrait', solde_fcfa, 'Remise à zéro globale par admin'
    FROM wallets
   WHERE solde_fcfa > 0;

  -- Remettre tous les wallets à zéro
  UPDATE wallets
  SET solde_fcfa = 0, updated_at = NOW()
  WHERE solde_fcfa != 0;

  GET DIAGNOSTICS v_nb_wallets = ROW_COUNT;

  RETURN jsonb_build_object(
    'ok',             true,
    'courses_annulees', v_nb_courses,
    'wallets_remis_a_zero', v_nb_wallets
  );
END;
$$;

-- Seul le service role peut appeler ces fonctions
REVOKE ALL ON FUNCTION admin_reset_compte(UUID)     FROM PUBLIC;
REVOKE ALL ON FUNCTION admin_reset_tous_comptes()   FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION admin_reset_compte(UUID)   TO service_role;
GRANT  EXECUTE ON FUNCTION admin_reset_tous_comptes() TO service_role;
