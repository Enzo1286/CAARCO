-- 024: messages.lu + users.type_vehicule + RPCs compteur/marquer

-- ── 1. Colonne lu sur messages ───────────────────────────────────────────────
ALTER TABLE messages ADD COLUMN IF NOT EXISTS lu BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_messages_lu_dest
  ON messages(destinataire_id, lu)
  WHERE destinataire_id IS NOT NULL AND lu = FALSE;

CREATE INDEX IF NOT EXISTS idx_messages_lu_course
  ON messages(course_id, lu)
  WHERE course_id IS NOT NULL AND lu = FALSE;

-- ── 2. Colonne type_vehicule sur users ───────────────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS type_vehicule TEXT
  CHECK (type_vehicule IN ('moto','voiture','tricycle_camionnette','camion'));

-- Backfill depuis la table vehicules (une seule fois)
UPDATE users u
SET type_vehicule = v.categorie
FROM vehicules v
WHERE v.transporteur_id = u.id
  AND v.valide = true
  AND v.categorie IS NOT NULL
  AND u.type_vehicule IS NULL;

-- ── 3. RPC : compteur messages non lus ──────────────────────────────────────
CREATE OR REPLACE FUNCTION compteur_messages_non_lus(p_user_id UUID)
RETURNS INTEGER
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT COUNT(*)::int FROM messages
     WHERE destinataire_id = p_user_id AND lu = false AND course_id IS NULL),
    0
  ) +
  COALESCE(
    (SELECT COUNT(*)::int FROM messages m
     JOIN courses c ON c.id = m.course_id
     WHERE (c.client_id = p_user_id OR c.transporteur_id = p_user_id)
       AND m.expediteur_id != p_user_id
       AND m.lu = false),
    0
  );
$$;
GRANT EXECUTE ON FUNCTION compteur_messages_non_lus(UUID) TO authenticated;

-- ── 4. RPC : marquer DMs comme lus ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION marquer_dm_lus(p_destinataire_id UUID, p_expediteur_id UUID)
RETURNS void LANGUAGE sql SECURITY DEFINER
AS $$
  UPDATE messages
  SET lu = true
  WHERE destinataire_id = p_destinataire_id
    AND expediteur_id   = p_expediteur_id
    AND lu = false
    AND course_id IS NULL;
$$;
GRANT EXECUTE ON FUNCTION marquer_dm_lus(UUID, UUID) TO authenticated;

-- ── 5. RPC : marquer messages de course comme lus ────────────────────────────
CREATE OR REPLACE FUNCTION marquer_course_lus(p_course_id UUID, p_user_id UUID)
RETURNS void LANGUAGE sql SECURITY DEFINER
AS $$
  UPDATE messages
  SET lu = true
  WHERE course_id     = p_course_id
    AND expediteur_id != p_user_id
    AND lu = false;
$$;
GRANT EXECUTE ON FUNCTION marquer_course_lus(UUID, UUID) TO authenticated;
