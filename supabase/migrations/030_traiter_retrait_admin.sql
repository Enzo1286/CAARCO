-- Migration 030 : RPC atomique pour traiter un retrait (statut + déduction wallet)
-- L'admin ne peut pas modifier le wallet d'un autre user via RLS.
-- Cette fonction SECURITY DEFINER bypasse le RLS pour la déduction.

CREATE OR REPLACE FUNCTION traiter_retrait_admin(
  p_retrait_id uuid,
  p_statut     text,
  p_note       text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET row_security = off
AS $$
DECLARE
  v_retrait retraits%ROWTYPE;
  v_wallet_id uuid;
BEGIN
  -- Vérifier que l'appelant est admin
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Accès refusé — admin requis';
  END IF;

  IF p_statut NOT IN ('traite', 'refuse') THEN
    RAISE EXCEPTION 'Statut invalide : %', p_statut;
  END IF;

  -- Récupérer le retrait (uniquement si encore en_attente)
  SELECT * INTO v_retrait
  FROM retraits
  WHERE id = p_retrait_id AND statut = 'en_attente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Retrait introuvable ou déjà traité';
  END IF;

  -- Mettre à jour le statut
  UPDATE retraits
  SET statut     = p_statut,
      note_admin = p_note,
      updated_at = now()
  WHERE id = p_retrait_id;

  -- Déduire du wallet seulement si "traite" (paiement effectué)
  IF p_statut = 'traite' THEN
    SELECT id INTO v_wallet_id
    FROM wallets
    WHERE user_id = v_retrait.transporteur_id;

    IF FOUND THEN
      UPDATE wallets
      SET solde_fcfa = GREATEST(0, solde_fcfa - v_retrait.montant_fcfa),
          updated_at = now()
      WHERE id = v_wallet_id;
    END IF;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION traiter_retrait_admin(uuid, text, text) TO authenticated;
