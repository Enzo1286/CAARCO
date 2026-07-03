-- Migration 076 — Système de contributions à la carte CAARCO
-- Les utilisateurs contribuent à améliorer la carte (routes, lieux, adresses)
-- et gagnent des points fidélité. Validation pair-à-pair : 3 confirmations → confirmé.

-- ══════════════════════════════════════════════════════════════════
-- 1. Champ points_carte sur les utilisateurs
-- ══════════════════════════════════════════════════════════════════
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS points_carte INTEGER DEFAULT 0;

-- ══════════════════════════════════════════════════════════════════
-- 2. Table contributions_carte
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.contributions_carte (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type                TEXT NOT NULL CHECK (type IN (
                        'route_fermee',
                        'correction_adresse',
                        'lieu_manquant',
                        'validation_lieu'
                      )),
  lat                 DECIMAL(10,7) NOT NULL,
  lng                 DECIMAL(10,7) NOT NULL,
  -- Champs selon le type
  description         TEXT,           -- description libre / nom du lieu
  adresse_originale   TEXT,           -- pour correction_adresse
  adresse_corrigee    TEXT,           -- pour correction_adresse
  categorie_lieu      TEXT,           -- pour lieu_manquant (marche, ecole, quartier…)
  -- Référence vers une autre contribution (pour validation_lieu)
  contribution_ref_id UUID REFERENCES public.contributions_carte(id) ON DELETE CASCADE,
  -- Lien optionnel à une course (contexte de la contribution)
  course_id           UUID REFERENCES public.courses(id) ON DELETE SET NULL,
  -- Statut et validation
  statut              TEXT DEFAULT 'en_attente' CHECK (statut IN (
                        'en_attente', 'confirme', 'rejete'
                      )),
  validations_count   INTEGER DEFAULT 0,
  points_accordes     INTEGER DEFAULT 0,
  confirme_at         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour requêtes géographiques (trouver contributions proches)
CREATE INDEX IF NOT EXISTS idx_contributions_carte_pos
  ON public.contributions_carte (lat, lng, statut);
CREATE INDEX IF NOT EXISTS idx_contributions_carte_user
  ON public.contributions_carte (user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_carte_ref
  ON public.contributions_carte (contribution_ref_id);

ALTER TABLE public.contributions_carte ENABLE ROW LEVEL SECURITY;

-- Lecture : chaque utilisateur peut voir ses propres contributions
-- + les contributions en_attente autour de lui (pour validation)
CREATE POLICY "contributions_lecture" ON public.contributions_carte
  FOR SELECT USING (
    auth.uid() = user_id
    OR statut = 'en_attente'
    OR statut = 'confirme'
  );

-- Insertion : uniquement son propre user_id
CREATE POLICY "contributions_insertion" ON public.contributions_carte
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════════════
-- 3. Table validations_contribution (qui a validé quoi)
-- ══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.validations_contribution (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contribution_id     UUID REFERENCES public.contributions_carte(id) ON DELETE CASCADE,
  user_id             UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(contribution_id, user_id)   -- un seul vote par utilisateur
);

ALTER TABLE public.validations_contribution ENABLE ROW LEVEL SECURITY;
CREATE POLICY "validations_acces" ON public.validations_contribution
  FOR ALL USING (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════════════
-- 4. Points par type de contribution
-- ══════════════════════════════════════════════════════════════════
-- route_fermee    : 5 pts (crédité à l'auteur quand confirmé)
-- correction_adresse : 3 pts (crédité immédiatement)
-- lieu_manquant   : 10 pts (crédité à l'auteur quand confirmé)
-- validation_lieu : 2 pts (crédité au validateur à chaque validation)
-- Bonus auteur : +2 pts supplémentaires quand confirmé

-- ══════════════════════════════════════════════════════════════════
-- 5. RPC : soumettre_contribution
-- ══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION soumettre_contribution(
  p_type              TEXT,
  p_lat               DECIMAL,
  p_lng               DECIMAL,
  p_description       TEXT       DEFAULT NULL,
  p_adresse_originale TEXT       DEFAULT NULL,
  p_adresse_corrigee  TEXT       DEFAULT NULL,
  p_categorie_lieu    TEXT       DEFAULT NULL,
  p_course_id         UUID       DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_contrib RECORD;
  v_pts     INTEGER;
BEGIN
  -- Créditer les pts immédiatement uniquement pour correction_adresse
  v_pts := CASE
    WHEN p_type = 'correction_adresse' THEN 3
    ELSE 0
  END;

  INSERT INTO contributions_carte (
    user_id, type, lat, lng,
    description, adresse_originale, adresse_corrigee, categorie_lieu,
    course_id, points_accordes, statut
  ) VALUES (
    auth.uid(), p_type, p_lat, p_lng,
    p_description, p_adresse_originale, p_adresse_corrigee, p_categorie_lieu,
    p_course_id, v_pts,
    CASE WHEN p_type = 'correction_adresse' THEN 'confirme' ELSE 'en_attente' END
  ) RETURNING * INTO v_contrib;

  -- Créditer les points immédiats (correction_adresse)
  IF v_pts > 0 THEN
    UPDATE users SET points_carte = COALESCE(points_carte, 0) + v_pts
      WHERE id = auth.uid();
  END IF;

  RETURN jsonb_build_object(
    'id',         v_contrib.id,
    'type',       v_contrib.type,
    'statut',     v_contrib.statut,
    'points',     v_pts
  );
END;
$$;

GRANT EXECUTE ON FUNCTION soumettre_contribution(TEXT, DECIMAL, DECIMAL, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;

-- ══════════════════════════════════════════════════════════════════
-- 6. RPC : valider_contribution (vote pair-à-pair)
-- ══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION valider_contribution(p_contribution_id UUID)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_contrib       RECORD;
  v_pts_validateur INTEGER := 2;
  v_pts_auteur     INTEGER := 0;
  v_seuil          INTEGER := 3;
BEGIN
  -- Récupérer la contribution
  SELECT * INTO v_contrib FROM contributions_carte WHERE id = p_contribution_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CONTRIBUTION_INTROUVABLE';
  END IF;
  IF v_contrib.statut != 'en_attente' THEN
    RAISE EXCEPTION 'CONTRIBUTION_DEJA_TRAITEE';
  END IF;
  IF v_contrib.user_id = auth.uid() THEN
    RAISE EXCEPTION 'AUTO_VALIDATION_INTERDITE';
  END IF;

  -- Insérer le vote (UNIQUE contrainte empêche le double vote)
  INSERT INTO validations_contribution (contribution_id, user_id)
    VALUES (p_contribution_id, auth.uid());

  -- Créditer le validateur
  UPDATE users SET points_carte = COALESCE(points_carte, 0) + v_pts_validateur
    WHERE id = auth.uid();

  -- Mettre à jour le compteur
  UPDATE contributions_carte
    SET validations_count = validations_count + 1
  WHERE id = p_contribution_id
  RETURNING * INTO v_contrib;

  -- Seuil atteint → confirmation automatique
  IF v_contrib.validations_count >= v_seuil THEN
    v_pts_auteur := CASE v_contrib.type
      WHEN 'route_fermee'   THEN 5
      WHEN 'lieu_manquant'  THEN 10
      ELSE 0
    END;

    UPDATE contributions_carte SET
      statut          = 'confirme',
      points_accordes = v_pts_auteur,
      confirme_at     = NOW()
    WHERE id = p_contribution_id;

    -- Créditer l'auteur de la contribution
    IF v_pts_auteur > 0 THEN
      UPDATE users SET points_carte = COALESCE(points_carte, 0) + v_pts_auteur
        WHERE id = v_contrib.user_id;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'validations',  v_contrib.validations_count,
    'confirme',     v_contrib.validations_count >= v_seuil,
    'points_gagnes', v_pts_validateur
  );
END;
$$;

GRANT EXECUTE ON FUNCTION valider_contribution(UUID) TO authenticated;

-- ══════════════════════════════════════════════════════════════════
-- 7. RPC : contributions_proches (pour la validation pair-à-pair)
-- ══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION contributions_proches(
  p_lat    DECIMAL,
  p_lng    DECIMAL,
  p_rayon  DECIMAL DEFAULT 5  -- km
)
RETURNS TABLE (
  id                UUID,
  type              TEXT,
  lat               DECIMAL,
  lng               DECIMAL,
  description       TEXT,
  categorie_lieu    TEXT,
  validations_count INTEGER,
  user_nom          TEXT,
  created_at        TIMESTAMPTZ,
  deja_valide       BOOLEAN
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    c.id, c.type, c.lat, c.lng, c.description,
    c.categorie_lieu, c.validations_count,
    u.nom AS user_nom, c.created_at,
    EXISTS (
      SELECT 1 FROM validations_contribution v
       WHERE v.contribution_id = c.id AND v.user_id = auth.uid()
    ) AS deja_valide
  FROM contributions_carte c
  JOIN users u ON u.id = c.user_id
  WHERE c.statut = 'en_attente'
    AND c.user_id != auth.uid()
    AND distance_km(p_lat, p_lng, c.lat::float8, c.lng::float8) <= p_rayon
  ORDER BY c.created_at DESC
  LIMIT 20
$$;

GRANT EXECUTE ON FUNCTION contributions_proches(DECIMAL, DECIMAL, DECIMAL) TO authenticated;
