-- Migration 060 — Fix calculer_classement_mensuel
-- La fonction référençait la table "notations" qui n'existe pas.
-- La vraie table de notes est "avis" et users.note_moyenne contient déjà
-- la moyenne calculée par trigger. On utilise directement note_moyenne.

CREATE OR REPLACE FUNCTION calculer_classement_mensuel()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE users SET rang_tr_mois = NULL, top_tr_mois = FALSE
   WHERE role = 'transporteur';

  WITH stats AS (
    SELECT
      c.transporteur_id                                            AS uid,
      COUNT(*)                                                     AS nb,
      ROW_NUMBER() OVER (
        ORDER BY COUNT(*) * 2 + COALESCE(u.note_moyenne, 5.0) * 10 DESC
      )                                                            AS rang
    FROM courses c
    JOIN users u ON u.id = c.transporteur_id
                AND u.role = 'transporteur'
                AND u.kyc_valide = TRUE
    WHERE c.statut = 'terminee'
      AND date_trunc('month', c.updated_at) = date_trunc('month', NOW())
    GROUP BY c.transporteur_id, u.note_moyenne
  )
  UPDATE users u
     SET rang_tr_mois = s.rang,
         top_tr_mois  = (s.rang <= 10)
    FROM stats s
   WHERE u.id = s.uid;
END;
$$;

GRANT EXECUTE ON FUNCTION calculer_classement_mensuel() TO service_role;
