-- ═══════════════════════════════════════════════════════════════
-- Migration 053 — Packs d'abonnement transporteurs
-- 3 tiers : standard / pro / elite
-- ═══════════════════════════════════════════════════════════════

-- ── Colonne pack_actuel sur users ────────────────────────────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS pack_actuel  TEXT DEFAULT 'gratuit'
    CHECK (pack_actuel IN ('gratuit','standard','pro','elite')),
  ADD COLUMN IF NOT EXISTS pack_expire_at TIMESTAMPTZ;

-- ── Table des abonnements actifs / historique ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.abonnements_transporteurs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transporteur_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pack             TEXT NOT NULL CHECK (pack IN ('standard','pro','elite')),
  periode          TEXT NOT NULL CHECK (periode IN ('mensuel','annuel')),
  prix_fcfa        INTEGER NOT NULL,
  statut           TEXT NOT NULL DEFAULT 'actif'
                     CHECK (statut IN ('actif','expire','annule','en_attente')),
  debut_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fin_at           TIMESTAMPTZ NOT NULL,
  moneroo_id       TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les requêtes courantes
CREATE INDEX IF NOT EXISTS idx_abonnements_transporteur
  ON public.abonnements_transporteurs (transporteur_id, statut);

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE public.abonnements_transporteurs ENABLE ROW LEVEL SECURITY;

-- Le transporteur voit uniquement ses propres abonnements
CREATE POLICY "transporteur_own_abonnements"
  ON public.abonnements_transporteurs
  FOR SELECT
  USING (auth.uid() = transporteur_id);

-- Insertion uniquement via Edge Function (service_role)
-- → pas de policy INSERT pour le client

-- Admin voit tout (via is_admin())
CREATE POLICY "admin_all_abonnements"
  ON public.abonnements_transporteurs
  FOR ALL
  USING (is_admin());

-- ── Fonction : vérifier et expirer les abonnements dépassés ──────────────────
CREATE OR REPLACE FUNCTION public.expirer_abonnements()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Marquer les abonnements expirés
  UPDATE public.abonnements_transporteurs
  SET statut = 'expire'
  WHERE statut = 'actif'
    AND fin_at < NOW();

  -- Repasser les transporteurs sans abonnement actif sur pack 'gratuit'
  UPDATE public.users u
  SET pack_actuel = 'gratuit', pack_expire_at = NULL
  WHERE u.role = 'transporteur'
    AND u.pack_actuel != 'gratuit'
    AND NOT EXISTS (
      SELECT 1 FROM public.abonnements_transporteurs a
      WHERE a.transporteur_id = u.id
        AND a.statut = 'actif'
        AND a.fin_at > NOW()
    );
END;
$$;
