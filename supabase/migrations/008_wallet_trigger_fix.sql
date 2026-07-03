-- Migration 008 : fix trigger expediteur_id + tables portefeuille

-- 1. Trigger messages : COALESCE — JS wins if provided, auth.uid() as fallback
CREATE OR REPLACE FUNCTION messages_avant_insert()
RETURNS TRIGGER AS $$
BEGIN
  NEW.expediteur_id := COALESCE(NEW.expediteur_id, auth.uid());
  IF NEW.expediteur_id IS NULL THEN
    RAISE EXCEPTION 'expediteur_id ne peut pas être null — utilisateur non authentifié';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Table wallets
CREATE TABLE IF NOT EXISTS wallets (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid REFERENCES users(id) UNIQUE NOT NULL,
  solde_fcfa int  DEFAULT 0 CHECK (solde_fcfa >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3. Table transactions_wallet
CREATE TABLE IF NOT EXISTS transactions_wallet (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id    uuid REFERENCES wallets(id) NOT NULL,
  type         text NOT NULL CHECK (type IN ('recharge','paiement','remboursement')),
  montant_fcfa int  NOT NULL CHECK (montant_fcfa > 0),
  methode      text CHECK (methode IN ('orange_money','mtn_momo','carte')),
  statut       text DEFAULT 'en_attente'
                    CHECK (statut IN ('en_attente','validee','echouee','annulee')),
  reference    text,
  created_at   timestamptz DEFAULT now()
);

-- 4. RLS wallets
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wallets_lecture"     ON wallets;
DROP POLICY IF EXISTS "wallets_creation"    ON wallets;
DROP POLICY IF EXISTS "wallets_modification"ON wallets;
CREATE POLICY "wallets_lecture"      ON wallets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "wallets_creation"     ON wallets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "wallets_modification" ON wallets FOR UPDATE USING (user_id = auth.uid());

-- 5. RLS transactions_wallet
ALTER TABLE transactions_wallet ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "transactions_lecture"  ON transactions_wallet;
DROP POLICY IF EXISTS "transactions_creation" ON transactions_wallet;
CREATE POLICY "transactions_lecture"  ON transactions_wallet FOR SELECT
  USING (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));
CREATE POLICY "transactions_creation" ON transactions_wallet FOR INSERT
  WITH CHECK (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));
CREATE POLICY "transactions_modification" ON transactions_wallet FOR UPDATE
  USING (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));

-- 6. Fonction RPC : créditer le solde (atomique)
CREATE OR REPLACE FUNCTION crediter_wallet(p_wallet_id uuid, p_montant int)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
  UPDATE wallets
  SET solde_fcfa = solde_fcfa + p_montant,
      updated_at = now()
  WHERE id = p_wallet_id AND user_id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet non trouvé ou non autorisé';
  END IF;
END;
$$;

-- 7. Fonction RPC : débiter le solde (atomique, vérifie solde suffisant)
CREATE OR REPLACE FUNCTION debiter_wallet(p_wallet_id uuid, p_montant int)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER AS $$
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
$$;
