-- ══════════════════════════════════════════════════════════════════════════
-- Migration 066 — Fonction remise_a_zero_totale()
-- Réservée à l'admin. Vide toutes les données de test avant le lancement Play Store.
-- Garde les comptes utilisateurs. Remet les soldes, compteurs et historiques à zéro.
-- ══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION remise_a_zero_totale()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  appelant_role TEXT;
  tbl           TEXT;
  tables_data   TEXT[] := ARRAY[
    'courses',
    'messages',
    'commissions_parrainage',
    'retraits',
    'recompenses_client',
    'positions_gps',
    'transactions_wallet',
    'abonnements_transporteurs',
    'avis',
    'transactions_points',
    'jalons_client',
    'classement_mensuel_tr',
    'publicites'
  ];
BEGIN
  -- Vérifie que l'appelant est admin
  SELECT role INTO appelant_role FROM users WHERE id = auth.uid();
  IF appelant_role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Acces refuse. Cette operation est reservee aux administrateurs.';
  END IF;

  -- TRUNCATE défensif : ignore les tables absentes
  FOREACH tbl IN ARRAY tables_data LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      EXECUTE 'TRUNCATE TABLE ' || quote_ident(tbl) || ' CASCADE';
    END IF;
  END LOOP;

  -- Remise à zéro des soldes wallets
  UPDATE wallets SET solde_fcfa = 0, updated_at = NOW() WHERE id IS NOT NULL;

  -- Remise à zéro des compteurs et scores
  UPDATE users SET
    points         = 0,
    nombre_courses = 0,
    note_moyenne   = 5.0
  WHERE id IS NOT NULL;

  RETURN json_build_object(
    'succes',  true,
    'message', 'Remise a zero complete effectuee. Base prete pour le lancement.'
  );
END;
$$;

-- Seuls les utilisateurs connectés peuvent appeler (authentification requise)
-- La fonction elle-même vérifie en plus que le rôle est 'admin'
GRANT EXECUTE ON FUNCTION remise_a_zero_totale() TO authenticated;
