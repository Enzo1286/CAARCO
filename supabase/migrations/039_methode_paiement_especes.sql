-- ── Tâche 1 : Paiement espèces & commission wallet TR ──────────────────────

-- 1. Ajouter methode_paiement à la table courses
ALTER TABLE public.courses
  ADD COLUMN IF NOT EXISTS methode_paiement TEXT NOT NULL DEFAULT 'online';

ALTER TABLE public.courses
  DROP CONSTRAINT IF EXISTS courses_methode_paiement_check;
ALTER TABLE public.courses
  ADD CONSTRAINT courses_methode_paiement_check
  CHECK (methode_paiement IN ('online', 'wallet', 'especes'));

-- 2. Autoriser le type 'commission' dans transactions_wallet
ALTER TABLE public.transactions_wallet
  DROP CONSTRAINT IF EXISTS transactions_wallet_type_check;
ALTER TABLE public.transactions_wallet
  ADD CONSTRAINT transactions_wallet_type_check
  CHECK (type IN ('recharge', 'paiement', 'recette', 'retrait', 'commission', 'bonus', 'remboursement'));

-- 3. RPC atomique : débiter 15% du wallet TR après une course en espèces
CREATE OR REPLACE FUNCTION public.debiter_commission_especes(p_course_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transporteur_id UUID;
  v_prix_fcfa       INTEGER;
  v_commission      INTEGER;
  v_methode         TEXT;
  v_statut          TEXT;
  v_wallet_id       UUID;
  v_solde           INTEGER;
BEGIN
  SELECT transporteur_id, prix_fcfa, methode_paiement, statut
  INTO v_transporteur_id, v_prix_fcfa, v_methode, v_statut
  FROM public.courses
  WHERE id = p_course_id;

  IF v_transporteur_id IS NULL THEN
    RAISE EXCEPTION 'Course introuvable : %', p_course_id;
  END IF;
  IF v_methode != 'especes' THEN
    RAISE EXCEPTION 'Course non espèces (methode: %)', v_methode;
  END IF;

  v_commission := ROUND(v_prix_fcfa * 0.15);

  SELECT id, solde_fcfa INTO v_wallet_id, v_solde
  FROM public.wallets
  WHERE user_id = v_transporteur_id;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet introuvable pour le transporteur : %', v_transporteur_id;
  END IF;
  IF v_solde < v_commission THEN
    RAISE EXCEPTION 'Solde insuffisant (solde: % XAF, commission: % XAF)', v_solde, v_commission;
  END IF;

  UPDATE public.wallets
  SET solde_fcfa = solde_fcfa - v_commission
  WHERE id = v_wallet_id;

  INSERT INTO public.transactions_wallet (wallet_id, type, montant_fcfa, reference, statut)
  VALUES (
    v_wallet_id,
    'commission',
    v_commission,
    'COM-' || UPPER(SUBSTRING(p_course_id::TEXT, 1, 8)),
    'validee'
  );

  RETURN v_commission;
END;
$$;

GRANT EXECUTE ON FUNCTION public.debiter_commission_especes(UUID) TO authenticated;
