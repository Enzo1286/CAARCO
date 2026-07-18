-- ============================================================================
-- SAUVEGARDE DE ROLLBACK -- migrations 112 + 113 (2026-07-18)
-- Definitions exactes des 16 fonctions telles qu'elles etaient EN PROD
-- avant execution. Recoller ce fichier restaure l'etat anterieur.
-- Pour les colonnes supprimees par la 112 :
--   ALTER TABLE public.users ADD COLUMN statut_vip boolean DEFAULT false;
--   ALTER TABLE public.users ADD COLUMN est_vip    boolean DEFAULT false;
--   (22 lignes, toutes a false au moment de la suppression : aucune donnee perdue)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.admin_crediter_wallet_client(p_user_id uuid, p_montant integer, p_motif text DEFAULT 'Crédit administrateur'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_wallet_id UUID;
  v_reference TEXT;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_admin() THEN
    RAISE EXCEPTION 'NON_AUTORISE : réservé aux administrateurs';
  END IF;

  IF p_montant <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'montant_invalide');
  END IF;

  INSERT INTO wallets(user_id, solde_fcfa, solde_bonus)
    VALUES (p_user_id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_user_id;

  IF v_wallet_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'raison', 'wallet_introuvable');
  END IF;

  UPDATE wallets
     SET solde_fcfa  = solde_fcfa  + p_montant,
         solde_bonus = solde_bonus + p_montant,
         updated_at  = NOW()
   WHERE id = v_wallet_id;

  v_reference := 'ADMIN-' || to_char(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_id, 'recharge', p_montant, 'validee', v_reference);

  RETURN jsonb_build_object(
    'ok',        true,
    'wallet_id', v_wallet_id,
    'montant',   p_montant,
    'reference', v_reference
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_reset_tous_comptes()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.calculer_bonus_mensuel_tr()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_mois_prec DATE := (date_trunc('month',NOW())-INTERVAL '1 month')::DATE;
  v_tier1 INTEGER; v_tier2 INTEGER; v_tier3 INTEGER;
  v_bn INTEGER; v_ba INTEGER;
  v_tr RECORD; v_nb INTEGER; v_comm INTEGER;
  v_note NUMERIC; v_accept NUMERIC;
  v_bv INTEGER; v_bq INTEGER; v_bt INTEGER;
  v_wid UUID;
BEGIN
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier1_pct'),2) INTO v_tier1;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier2_pct'),4) INTO v_tier2;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_volume_tier3_pct'),7) INTO v_tier3;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_qualite_note_xaf'),2000) INTO v_bn;
  SELECT COALESCE((SELECT valeur::INTEGER FROM configurations_systeme WHERE cle='bonus_qualite_accept_xaf'),2000) INTO v_ba;
  FOR v_tr IN SELECT u.id AS user_id FROM users u WHERE u.role='transporteur'
    AND EXISTS(SELECT 1 FROM courses c WHERE c.transporteur_id=u.id AND c.statut='terminee'
      AND date_trunc('month',COALESCE(c.completed_at,c.updated_at))=v_mois_prec)
  LOOP
    SELECT COUNT(*)::INTEGER INTO v_nb FROM courses
      WHERE transporteur_id=v_tr.user_id AND statut='terminee'
        AND date_trunc('month',COALESCE(completed_at,updated_at))=v_mois_prec;
    SELECT COALESCE(SUM(tw.montant_fcfa),0)::INTEGER INTO v_comm
      FROM transactions_wallet tw JOIN wallets w ON w.id=tw.wallet_id
      WHERE w.user_id=v_tr.user_id AND tw.type='recette'
        AND date_trunc('month',tw.created_at)=v_mois_prec;
    v_bv := CASE WHEN v_nb>=50 THEN ROUND(v_comm*v_tier3::NUMERIC/100)
                 WHEN v_nb>=25 THEN ROUND(v_comm*v_tier2::NUMERIC/100)
                 WHEN v_nb>=10 THEN ROUND(v_comm*v_tier1::NUMERIC/100)
                 ELSE 0 END;
    SELECT COALESCE(AVG(a.note_globale),0) INTO v_note FROM avis a
      JOIN courses c ON c.id=a.course_id WHERE c.transporteur_id=v_tr.user_id
        AND date_trunc('month',a.created_at)=v_mois_prec;
    SELECT CASE WHEN COUNT(*)=0 THEN 0
      ELSE COUNT(*) FILTER (WHERE statut='accepte')::NUMERIC/COUNT(*) END INTO v_accept
      FROM candidatures WHERE transporteur_id=v_tr.user_id
        AND date_trunc('month',created_at)=v_mois_prec;
    v_bq:=0;
    IF v_note>=4.5 THEN v_bq:=v_bq+v_bn; END IF;
    IF v_accept>0.80 THEN v_bq:=v_bq+v_ba; END IF;
    v_bt:=v_bv+v_bq;
    IF v_bt>0 THEN
      INSERT INTO wallets(user_id,solde_fcfa) VALUES(v_tr.user_id,0) ON CONFLICT(user_id) DO NOTHING;
      SELECT id INTO v_wid FROM wallets WHERE user_id=v_tr.user_id;
      UPDATE wallets SET solde_fcfa=solde_fcfa+v_bt,updated_at=NOW() WHERE id=v_wid;
      INSERT INTO transactions_wallet(wallet_id,type,montant_fcfa,statut,reference)
        VALUES(v_wid,'bonus_fidelite',v_bt,'validee','bonus_'||TO_CHAR(v_mois_prec,'YYYY_MM'));
    END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculer_bonus_volume_mensuel()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v RECORD; v_wid UUID; v_bonus INT; v_pct NUMERIC; v_ref TEXT;
BEGIN
  v_ref := 'bonus_vol_' || to_char(NOW() - INTERVAL '1 month', 'YYYY_MM');
  IF EXISTS (SELECT 1 FROM transactions_wallet WHERE reference LIKE v_ref || '%' LIMIT 1) THEN RETURN; END IF;
  FOR v IN
    SELECT c.transporteur_id AS uid, COUNT(*) AS nb, COALESCE(SUM(p.montant_fcfa),0)::INT AS ca
    FROM courses c JOIN paiements p ON p.course_id = c.id AND p.statut = 'libere'
    WHERE c.statut = 'terminee'
      AND date_trunc('month', c.updated_at) = date_trunc('month', NOW() - INTERVAL '1 month')
    GROUP BY c.transporteur_id
  LOOP
    IF v.nb >= 50 THEN v_pct := 0.07; ELSIF v.nb >= 25 THEN v_pct := 0.04;
    ELSIF v.nb >= 10 THEN v_pct := 0.02; ELSE CONTINUE; END IF;
    v_bonus := GREATEST(0, ROUND(v.ca * 0.15 * v_pct));
    IF v_bonus = 0 THEN CONTINUE; END IF;
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v.uid, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM wallets WHERE user_id = v.uid;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW() WHERE id = v_wid;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'bonus_volume', v_bonus, 'validee', v_ref || '_' || v.uid);
    UPDATE users SET bonus_volume_mois_fcfa = v_bonus WHERE id = v.uid;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculer_bonus_volume_tr(p_mois date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_mois DATE; v_debut TIMESTAMPTZ; v_fin TIMESTAMPTZ; rec RECORD;
        v_nb INTEGER; v_bonus_pct NUMERIC; v_total_comm INTEGER; v_bonus_fcfa INTEGER;
BEGIN
  v_mois  := COALESCE(p_mois, date_trunc('month', NOW() - INTERVAL '1 month')::DATE);
  v_debut := v_mois::TIMESTAMPTZ;
  v_fin   := (v_mois + INTERVAL '1 month')::TIMESTAMPTZ;
  FOR rec IN SELECT DISTINCT transporteur_id FROM courses
             WHERE statut='terminee' AND updated_at>=v_debut AND updated_at<v_fin AND transporteur_id IS NOT NULL
  LOOP
    SELECT COUNT(*) INTO v_nb FROM courses WHERE transporteur_id=rec.transporteur_id AND statut='terminee' AND updated_at>=v_debut AND updated_at<v_fin;
    IF    v_nb>=50 THEN v_bonus_pct:=0.07;
    ELSIF v_nb>=25 THEN v_bonus_pct:=0.04;
    ELSIF v_nb>=10 THEN v_bonus_pct:=0.02;
    ELSE v_bonus_pct:=0; END IF;
    CONTINUE WHEN v_bonus_pct=0;
    SELECT COALESCE(SUM(ROUND(prix_fcfa*0.15)),0)::INTEGER INTO v_total_comm FROM courses
    WHERE transporteur_id=rec.transporteur_id AND statut='terminee' AND updated_at>=v_debut AND updated_at<v_fin;
    v_bonus_fcfa:=ROUND(v_total_comm*v_bonus_pct);
    CONTINUE WHEN v_bonus_fcfa<=0;
    UPDATE wallets SET solde_fcfa=solde_fcfa+v_bonus_fcfa WHERE user_id=rec.transporteur_id;
  END LOOP;
END; $function$
;

CREATE OR REPLACE FUNCTION public.calculer_prime_qualite_mensuelle()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v RECORD; v_wid UUID; v_bonus INT; v_ref TEXT;
BEGIN
  v_ref := 'prime_qual_' || to_char(NOW() - INTERVAL '1 month', 'YYYY_MM');
  IF EXISTS (SELECT 1 FROM transactions_wallet WHERE reference LIKE v_ref || '%' LIMIT 1) THEN RETURN; END IF;
  FOR v IN
    SELECT u.id AS uid, COALESCE(u.note_moyenne, 0) AS note, COUNT(c.id) AS nb
    FROM users u LEFT JOIN courses c ON c.transporteur_id = u.id AND c.statut = 'terminee'
      AND date_trunc('month', c.updated_at) = date_trunc('month', NOW() - INTERVAL '1 month')
    WHERE u.role = 'transporteur' GROUP BY u.id, u.note_moyenne HAVING COUNT(c.id) >= 5
  LOOP
    v_bonus := 0;
    IF v.note >= 4.5 THEN v_bonus := 500; END IF;
    IF v_bonus = 0 THEN CONTINUE; END IF;
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v.uid, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wid FROM wallets WHERE user_id = v.uid;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_bonus, updated_at = NOW() WHERE id = v_wid;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wid, 'prime_qualite', v_bonus, 'validee', v_ref || '_' || v.uid);
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculer_prime_qualite_tr(p_mois date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_mois DATE; v_debut TIMESTAMPTZ; v_fin TIMESTAMPTZ; rec RECORD;
        v_note NUMERIC; v_total_cand INTEGER; v_cand_acceptees INTEGER; v_taux NUMERIC; v_bonus INTEGER;
BEGIN
  v_mois:=COALESCE(p_mois,date_trunc('month',NOW()-INTERVAL '1 month')::DATE);
  v_debut:=v_mois::TIMESTAMPTZ; v_fin:=(v_mois+INTERVAL '1 month')::TIMESTAMPTZ;
  FOR rec IN SELECT DISTINCT transporteur_id FROM courses WHERE statut='terminee' AND updated_at>=v_debut AND updated_at<v_fin AND transporteur_id IS NOT NULL
  LOOP
    SELECT COALESCE(AVG(n.score),0) INTO v_note FROM notations n JOIN courses c ON c.id=n.course_id
    WHERE n.note_id=rec.transporteur_id AND c.updated_at>=v_debut AND c.updated_at<v_fin;
    SELECT COUNT(*) INTO v_total_cand FROM candidatures WHERE transporteur_id=rec.transporteur_id AND created_at>=v_debut AND created_at<v_fin;
    SELECT COUNT(*) INTO v_cand_acceptees FROM candidatures ca JOIN courses c ON c.id=ca.course_id
    WHERE ca.transporteur_id=rec.transporteur_id AND ca.created_at>=v_debut AND ca.created_at<v_fin AND c.transporteur_id=rec.transporteur_id;
    v_taux:=CASE WHEN v_total_cand>0 THEN (v_cand_acceptees::NUMERIC/v_total_cand)*100 ELSE 0 END;
    v_bonus:=0;
    IF v_note>=4.5 THEN v_bonus:=v_bonus+2000; END IF;
    IF v_taux>80   THEN v_bonus:=v_bonus+2000; END IF;
    CONTINUE WHEN v_bonus=0;
    UPDATE wallets SET solde_fcfa=solde_fcfa+v_bonus WHERE user_id=rec.transporteur_id;
  END LOOP;
END; $function$
;

CREATE OR REPLACE FUNCTION public.crediter_wallet(p_wallet_id uuid, p_montant integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE wallets
  SET solde_fcfa = solde_fcfa + p_montant,
      updated_at = NOW()
  WHERE id = p_wallet_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.debiter_commission_especes(p_course_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tr_id     UUID;
  v_prix      INTEGER;
  v_comm      INTEGER;
  v_wallet_id UUID;
  v_solde     INTEGER;
  v_dette     INTEGER;
  v_debit     INTEGER;
BEGIN
  SELECT transporteur_id, prix_fcfa INTO v_tr_id, v_prix FROM courses WHERE id = p_course_id;
  IF v_tr_id IS NULL THEN RAISE EXCEPTION 'Course introuvable'; END IF;

  v_comm := ROUND(v_prix * 0.20);

  SELECT id, solde_fcfa INTO v_wallet_id, v_solde FROM wallets WHERE user_id = v_tr_id;
  IF v_wallet_id IS NULL THEN
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_tr_id, 0) RETURNING id, solde_fcfa INTO v_wallet_id, v_solde;
  END IF;

  v_debit := LEAST(v_comm, v_solde);
  v_dette := v_comm - v_debit;

  IF v_debit > 0 THEN
    UPDATE wallets SET solde_fcfa = solde_fcfa - v_debit, updated_at = NOW() WHERE id = v_wallet_id;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
      VALUES (v_wallet_id, 'debit_commission_especes', v_debit, p_course_id::TEXT, 'complete');
  END IF;

  IF v_dette > 0 THEN
    INSERT INTO dettes_commission(transporteur_id, course_id, montant_fcfa) VALUES (v_tr_id, p_course_id, v_dette);
    UPDATE users SET bloque_impaye = TRUE, dette_commission_fcfa = dette_commission_fcfa + v_dette WHERE id = v_tr_id;
  END IF;

  UPDATE courses SET statut_paiement = 'paye', methode_paiement = 'especes', updated_at = NOW() WHERE id = p_course_id;

  RETURN json_build_object('commission', v_comm, 'debit', v_debit, 'dette', v_dette, 'bloque', v_dette > 0);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.debiter_wallet(p_wallet_id uuid, p_montant integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE wallets
  SET solde_fcfa = solde_fcfa - p_montant,
      updated_at = now()
  WHERE id = p_wallet_id
    AND user_id = auth.uid()
    AND solde_fcfa >= p_montant;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Solde insuffisant ou wallet non trouvé';
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.liberer_sequestre_course(p_course_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_paiement_id    UUID;
  v_montant        INT;
  v_transporteur   UUID;
  v_wallet_tr      UUID;
  v_taux_commission NUMERIC;
  v_commission     INT;
  v_net            INT;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_admin() THEN
    RAISE EXCEPTION 'NON_AUTORISE : fonction du modèle séquestre déprécié, réservée aux admins/service_role';
  END IF;

  SELECT id, montant_fcfa INTO v_paiement_id, v_montant
    FROM paiements
   WHERE course_id = p_course_id AND statut IN ('sequestre', 'initie')
   ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_mobile_payment');
  END IF;

  SELECT transporteur_id INTO v_transporteur FROM courses WHERE id = p_course_id;

  IF v_transporteur IS NULL THEN
    RETURN jsonb_build_object('skip', true, 'raison', 'no_transporter');
  END IF;

  v_taux_commission := COALESCE(commission_taux_tr(v_transporteur), 0.15);
  v_commission      := ROUND(v_montant * v_taux_commission);
  v_net             := v_montant - v_commission;

  INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_transporteur, 0)
    ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_wallet_tr FROM wallets WHERE user_id = v_transporteur;

  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = NOW()
   WHERE id = v_wallet_tr;

  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (v_wallet_tr, 'recette', v_net, 'validee', p_course_id::text);

  UPDATE paiements SET statut = 'libere', libere_at = NOW() WHERE id = v_paiement_id;

  UPDATE courses SET statut_paiement = 'libere', updated_at = NOW() WHERE id = p_course_id;

  RETURN jsonb_build_object(
    'success', true,
    'net_transporteur', v_net,
    'commission', v_commission,
    'taux_commission', v_taux_commission,
    'montant_total', v_montant
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.payer_avec_wallet_atomique(p_wallet_id uuid, p_montant integer, p_reference text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_solde int;
  v_uid   uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'non_authentifie';
  END IF;
  IF p_montant <= 0 THEN
    RAISE EXCEPTION 'montant_invalide';
  END IF;

  -- Vérifier solde ET débiter en une seule opération atomique
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - p_montant,
         updated_at = now()
   WHERE id        = p_wallet_id
     AND user_id   = v_uid
     AND solde_fcfa >= p_montant;

  IF NOT FOUND THEN
    -- Distinguer "wallet introuvable" de "solde insuffisant"
    SELECT solde_fcfa INTO v_solde
      FROM wallets
     WHERE id = p_wallet_id AND user_id = v_uid;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'wallet_introuvable';
    ELSE
      RAISE EXCEPTION 'fonds_insuffisants — solde : % XAF, requis : % XAF',
        v_solde, p_montant;
    END IF;
  END IF;

  -- Enregistrer la transaction UNIQUEMENT si le débit a réussi
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference)
    VALUES (p_wallet_id, 'paiement', p_montant, 'validee', p_reference);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.payer_course_wallet(p_destinataire_id uuid, p_montant integer, p_reference text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_payeur_id       uuid := auth.uid();
  v_wallet_payeur   uuid;
  v_wallet_receveur uuid;
  v_solde           int;
BEGIN
  -- Validation
  IF v_payeur_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;
  IF p_montant <= 0 THEN
    RAISE EXCEPTION 'Montant invalide : doit être > 0';
  END IF;
  IF v_payeur_id = p_destinataire_id THEN
    RAISE EXCEPTION 'Impossible de se payer soi-même';
  END IF;

  -- Wallet du payeur (doit exister)
  SELECT id, solde_fcfa
    INTO v_wallet_payeur, v_solde
    FROM wallets
   WHERE user_id = v_payeur_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Portefeuille introuvable — rechargez d''abord votre wallet';
  END IF;
  IF v_solde < p_montant THEN
    RAISE EXCEPTION 'Solde insuffisant (disponible : % XAF)', v_solde;
  END IF;

  -- Wallet du receveur : créé automatiquement s'il n'existe pas encore
  INSERT INTO wallets (user_id, solde_fcfa)
    VALUES (p_destinataire_id, 0)
    ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_wallet_receveur
    FROM wallets WHERE user_id = p_destinataire_id;

  -- Débit payeur + Crédit receveur (atomique dans la même transaction)
  UPDATE wallets
     SET solde_fcfa = solde_fcfa - p_montant, updated_at = now()
   WHERE id = v_wallet_payeur;

  UPDATE wallets
     SET solde_fcfa = solde_fcfa + p_montant, updated_at = now()
   WHERE id = v_wallet_receveur;

  -- Enregistrement des deux lignes de transaction
  INSERT INTO transactions_wallet (wallet_id, type, montant_fcfa, statut, reference)
  VALUES
    (v_wallet_payeur,   'paiement', p_montant, 'validee', p_reference),
    (v_wallet_receveur, 'recette',  p_montant, 'validee', p_reference);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.process_ride_payment(p_client_id uuid, p_tr_id uuid, p_ride_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_montant             int;
  v_client_wallet_id    uuid;
  v_tr_wallet_id        uuid;
  v_solde_client        int;
  v_net                 int;
  v_commission          int;
  v_reference           text;
  v_pct_parrainage      numeric;
  v_parrain_client      uuid;
  v_parrain_tr          uuid;
  v_wallet_parrain      uuid;
  v_comm_parrain        int;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'non_authentifie'; END IF;
  IF auth.uid() != p_client_id THEN RAISE EXCEPTION 'identite_invalide'; END IF;
  SELECT prix_fcfa INTO v_montant FROM courses WHERE id = p_ride_id AND client_id = p_client_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'course_introuvable'; END IF;
  IF v_montant IS NULL OR v_montant <= 0 THEN RAISE EXCEPTION 'montant_invalide'; END IF;
  SELECT id, solde_fcfa INTO v_client_wallet_id, v_solde_client FROM wallets WHERE user_id = p_client_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'wallet_client_introuvable'; END IF;
  IF v_solde_client < v_montant THEN RAISE EXCEPTION 'fonds_insuffisants'; END IF;
  v_commission     := ROUND(v_montant * 0.15);
  v_net            := v_montant - v_commission;
  v_reference      := 'WAL-' || UPPER(SUBSTRING(p_ride_id::text FROM 1 FOR 8));
  v_pct_parrainage := 0.10;
  INSERT INTO wallets(user_id, solde_fcfa) VALUES (p_tr_id, 0) ON CONFLICT (user_id) DO NOTHING;
  SELECT id INTO v_tr_wallet_id FROM wallets WHERE user_id = p_tr_id;
  UPDATE wallets SET solde_fcfa = solde_fcfa - v_montant, updated_at = now() WHERE id = v_client_wallet_id;
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference) VALUES (v_client_wallet_id, 'paiement', v_montant, 'validee', v_reference);
  UPDATE wallets SET solde_fcfa = solde_fcfa + v_net, updated_at = now() WHERE id = v_tr_wallet_id;
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference) VALUES (v_tr_wallet_id, 'recette', v_net, 'validee', v_reference);

  -- CORRECTION BUG : ne pas mettre statut='terminee' ici.
  -- Seul terminer_livraison() peut terminer la course quand le TR clique Livrer.
  -- On met uniquement statut_paiement='paye' pour debloquer AttenteReglementScreen.
  UPDATE courses SET statut_paiement = 'paye', updated_at = now() WHERE id = p_ride_id;

  INSERT INTO paiements(course_id, montant_fcfa, commission_fcfa, net_transporteur, methode, statut, ref_transaction, libere_at)
  VALUES (p_ride_id, v_montant, v_commission, v_net, 'wallet', 'libere', v_reference, now())
  ON CONFLICT DO NOTHING;

  SELECT parrain_id INTO v_parrain_client FROM users WHERE id = p_client_id;
  IF v_parrain_client IS NOT NULL THEN
    v_comm_parrain := GREATEST(1, ROUND(v_commission::numeric * v_pct_parrainage));
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parrain_client, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_client;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = now() WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference) VALUES (v_wallet_parrain, 'recette', v_comm_parrain, 'validee', v_reference);
    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa) VALUES (v_parrain_client, p_client_id, p_ride_id, v_comm_parrain);
  END IF;

  SELECT parrain_id INTO v_parrain_tr FROM users WHERE id = p_tr_id;
  IF v_parrain_tr IS NOT NULL AND v_parrain_tr IS DISTINCT FROM v_parrain_client THEN
    v_comm_parrain := GREATEST(1, ROUND(v_commission::numeric * v_pct_parrainage));
    INSERT INTO wallets(user_id, solde_fcfa) VALUES (v_parrain_tr, 0) ON CONFLICT (user_id) DO NOTHING;
    SELECT id INTO v_wallet_parrain FROM wallets WHERE user_id = v_parrain_tr;
    UPDATE wallets SET solde_fcfa = solde_fcfa + v_comm_parrain, updated_at = now() WHERE id = v_wallet_parrain;
    INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, statut, reference) VALUES (v_wallet_parrain, 'recette', v_comm_parrain, 'validee', v_reference);
    INSERT INTO commissions_parrainage(parrain_id, filleul_id, course_id, montant_fcfa) VALUES (v_parrain_tr, p_tr_id, p_ride_id, v_comm_parrain);
  END IF;

  RETURN jsonb_build_object('reference', v_reference, 'montant', v_montant, 'net_transporteur', v_net, 'commission', v_commission);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rembourser_dette_tr(p_tr_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_dette INTEGER; v_solde INTEGER; v_wallet_id UUID;
BEGIN
  SELECT dette_commission_fcfa INTO v_dette FROM users WHERE id = p_tr_id;
  IF COALESCE(v_dette, 0) = 0 THEN
    RETURN json_build_object('dette_remboursee', 0, 'bloque', FALSE);
  END IF;
  SELECT id, solde_fcfa INTO v_wallet_id, v_solde FROM wallets WHERE user_id = p_tr_id;
  IF COALESCE(v_solde, 0) < v_dette THEN
    RETURN json_build_object('erreur', 'solde_insuffisant', 'dette', v_dette, 'solde', COALESCE(v_solde, 0));
  END IF;
  UPDATE wallets SET solde_fcfa = solde_fcfa - v_dette, updated_at = NOW() WHERE id = v_wallet_id;
  INSERT INTO transactions_wallet(wallet_id, type, montant_fcfa, reference, statut)
    VALUES (v_wallet_id, 'remboursement_dette', v_dette, 'dette_commission', 'complete');
  UPDATE dettes_commission SET statut = 'remboursee', remboursee_at = NOW()
    WHERE transporteur_id = p_tr_id AND statut = 'en_attente';
  UPDATE users SET bloque_impaye = FALSE, dette_commission_fcfa = 0 WHERE id = p_tr_id;
  RETURN json_build_object('dette_remboursee', v_dette, 'bloque', FALSE);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.traiter_retrait_admin(p_retrait_id uuid, p_statut text, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET row_security TO 'off'
AS $function$
DECLARE
  v_retrait     retraits%ROWTYPE;
  v_wallet_id   uuid;
  v_solde_total INTEGER;
  v_solde_bonus INTEGER;
  v_retirable   INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Acc�s refus� � admin requis';
  END IF;

  IF p_statut NOT IN ('traite', 'refuse') THEN
    RAISE EXCEPTION 'Statut invalide : %', p_statut;
  END IF;

  SELECT * INTO v_retrait
  FROM retraits
  WHERE id = p_retrait_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Retrait introuvable ou d�j� trait�';
  END IF;

  UPDATE retraits
  SET statut     = p_statut,
      note_admin = p_note,
      updated_at = now()
  WHERE id = p_retrait_id;

  IF p_statut = 'traite' THEN
    SELECT id, solde_fcfa, COALESCE(solde_bonus, 0)
      INTO v_wallet_id, v_solde_total, v_solde_bonus
      FROM wallets
     WHERE user_id = v_retrait.transporteur_id;

    IF FOUND THEN
      v_retirable := v_solde_total - v_solde_bonus;

      -- V�rification : le montant doit rester dans la part retirable
      IF v_retrait.montant_fcfa > v_retirable THEN
        RAISE EXCEPTION 'Montant d�passe le solde retirable (retirable: % XAF, demand�: % XAF)',
          v_retirable, v_retrait.montant_fcfa;
      END IF;

      UPDATE wallets
      SET solde_fcfa = GREATEST(v_solde_bonus, solde_fcfa - v_retrait.montant_fcfa),
          updated_at = now()
      WHERE id = v_wallet_id;
    END IF;
  END IF;
END;
$function$
;
