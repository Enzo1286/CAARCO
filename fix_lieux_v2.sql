-- ═══════════════════════════════════════════════════════
-- AJOUT colonne confirmations sur lieux
-- ═══════════════════════════════════════════════════════
ALTER TABLE public.lieux
  ADD COLUMN IF NOT EXISTS confirmations INTEGER NOT NULL DEFAULT 1;

-- ═══════════════════════════════════════════════════════
-- TABLE lieux_corrections — votes pour renommer un lieu
-- ═══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.lieux_corrections (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lieu_id      UUID NOT NULL REFERENCES public.lieux(id) ON DELETE CASCADE,
  nom_propose  TEXT NOT NULL,
  votes        INTEGER NOT NULL DEFAULT 1,
  createur_id  UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS lieux_corrections_lieu_idx ON public.lieux_corrections (lieu_id);

ALTER TABLE public.lieux_corrections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "corrections_lecture" ON public.lieux_corrections
  FOR SELECT USING (true);

CREATE POLICY "corrections_insert" ON public.lieux_corrections
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "corrections_update_vote" ON public.lieux_corrections
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ═══════════════════════════════════════════════════════
-- RPC soumettre_lieu_gps
-- Insère un lieu validé directement (soumis via bouton GPS = position confirmée en direct)
-- ═══════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.soumettre_lieu_gps(
  p_nom       TEXT,
  p_lat       DOUBLE PRECISION,
  p_lng       DOUBLE PRECISION,
  p_ville     TEXT DEFAULT 'Bafoussam',
  p_categorie TEXT DEFAULT 'Autre'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_lieu_id UUID;
  v_proche  UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Non connecté';
  END IF;

  -- Vérifier qu'il n'y a pas déjà un lieu validé à moins de 30 m (doublon exact)
  SELECT id INTO v_proche
  FROM public.lieux
  WHERE statut = 'valide'
    AND (6371000 * acos(
      LEAST(1.0, cos(radians(p_lat)) * cos(radians(lat)) *
      cos(radians(lng) - radians(p_lng)) +
      sin(radians(p_lat)) * sin(radians(lat)))
    )) < 30
  LIMIT 1;

  IF v_proche IS NOT NULL THEN
    -- Lieu très proche déjà validé → juste incrémenter les confirmations
    UPDATE public.lieux SET confirmations = confirmations + 1 WHERE id = v_proche;
    RETURN jsonb_build_object('action', 'confirme', 'lieu_id', v_proche);
  END IF;

  -- Créer le lieu directement validé
  INSERT INTO public.lieux (nom, categorie, lat, lng, ville, statut, createur_id, confirmations)
  VALUES (trim(p_nom), p_categorie, p_lat, p_lng, p_ville, 'valide', v_user_id, 1)
  RETURNING id INTO v_lieu_id;

  RETURN jsonb_build_object('action', 'cree', 'lieu_id', v_lieu_id);
END;
$$;

-- ═══════════════════════════════════════════════════════
-- RPC confirmer_lieu — le lieu est correct, +1 confirmation
-- ═══════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.confirmer_lieu(
  p_lieu_id UUID
) RETURNS void
LANGUAGE sql SECURITY DEFINER
AS $$
  UPDATE public.lieux
  SET confirmations = confirmations + 1
  WHERE id = p_lieu_id;
$$;

-- ═══════════════════════════════════════════════════════
-- RPC voter_correction — propose/vote pour un nouveau nom
-- Si votes >= 3 → le nom est remplacé automatiquement
-- ═══════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.voter_correction(
  p_lieu_id   UUID,
  p_nom_propose TEXT
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_correction_id UUID;
  v_votes         INTEGER;
  v_nom_normalise TEXT;
BEGIN
  v_nom_normalise := trim(p_nom_propose);

  -- Chercher une correction existante avec le même nom proposé (insensible à la casse)
  SELECT id, votes INTO v_correction_id, v_votes
  FROM public.lieux_corrections
  WHERE lieu_id = p_lieu_id
    AND lower(nom_propose) = lower(v_nom_normalise)
  LIMIT 1;

  IF v_correction_id IS NULL THEN
    -- Première fois que ce nom est proposé
    INSERT INTO public.lieux_corrections (lieu_id, nom_propose, votes, createur_id)
    VALUES (p_lieu_id, v_nom_normalise, 1, auth.uid())
    RETURNING id INTO v_correction_id;
    v_votes := 1;
  ELSE
    -- Incrémenter les votes
    UPDATE public.lieux_corrections
    SET votes = votes + 1
    WHERE id = v_correction_id
    RETURNING votes INTO v_votes;
  END IF;

  -- 3 votes → remplacer le nom du lieu
  IF v_votes >= 3 THEN
    UPDATE public.lieux SET nom = v_nom_normalise WHERE id = p_lieu_id;
    DELETE FROM public.lieux_corrections WHERE lieu_id = p_lieu_id;
    RETURN jsonb_build_object('action', 'remplace', 'nom', v_nom_normalise, 'votes', v_votes);
  END IF;

  RETURN jsonb_build_object('action', 'vote_enregistre', 'votes', v_votes, 'restant', 3 - v_votes);
END;
$$;
