-- Migration 016 : RLS sur la table candidatures
-- CORRECTION BUG : le client voyait "Diffusion en cours" indéfiniment car RLS
-- bloquait silencieusement le SELECT sur candidatures → obtenirCandidatures()
-- retournait [] sans erreur et AttenteScreen ne passait jamais au TR trouvé.

-- ── 1. Activer RLS si pas encore actif ───────────────────────────────────────
ALTER TABLE candidatures ENABLE ROW LEVEL SECURITY;

-- ── 2. Supprimer les anciennes policies si elles existent ────────────────────
DROP POLICY IF EXISTS "candidatures_client_lecture"   ON candidatures;
DROP POLICY IF EXISTS "candidatures_tr_lecture"       ON candidatures;
DROP POLICY IF EXISTS "candidatures_tr_insert"        ON candidatures;
DROP POLICY IF EXISTS "candidatures_tr_update"        ON candidatures;

-- ── 3. SELECT : client voit les candidatures de SES courses ──────────────────
--             TR voit SES propres candidatures
CREATE POLICY "candidatures_client_lecture" ON candidatures
  FOR SELECT
  USING (
    course_id IN (
      SELECT id FROM courses WHERE client_id = auth.uid()
    )
    OR transporteur_id = auth.uid()
  );

-- ── 4. INSERT : seul un TR peut postuler ─────────────────────────────────────
CREATE POLICY "candidatures_tr_insert" ON candidatures
  FOR INSERT
  WITH CHECK (transporteur_id = auth.uid());

-- ── 5. UPDATE : TR auteur OU client de la course (pour marquer le TR choisi) ─
CREATE POLICY "candidatures_tr_update" ON candidatures
  FOR UPDATE
  USING (
    transporteur_id = auth.uid()
    OR course_id IN (SELECT id FROM courses WHERE client_id = auth.uid())
  );

-- ── 6. DELETE : TR peut retirer sa candidature, client peut refuser ──────────
CREATE POLICY "candidatures_tr_delete" ON candidatures
  FOR DELETE
  USING (
    transporteur_id = auth.uid()
    OR course_id IN (SELECT id FROM courses WHERE client_id = auth.uid())
  );
