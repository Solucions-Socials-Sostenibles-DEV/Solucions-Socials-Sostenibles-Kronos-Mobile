-- =============================================================================
-- Obrador — Escandallos y KPIs mensuales
-- Ejecutar después de alter_obrador_rls_hardening.sql.
-- Crea fichas de coste persistentes y los datos sociales mensuales que no se
-- pueden deducir de lotes, expediciones o controles APPCC.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.obrador_escandalls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT NOT NULL CHECK (length(trim(nom)) > 0),
  linia TEXT NOT NULL DEFAULT 'frescos',
  id_producte UUID REFERENCES public.obrador_productes(id) ON DELETE SET NULL,
  rendiment NUMERIC(12,3) NOT NULL CHECK (rendiment > 0),
  unitat_rendiment TEXT NOT NULL DEFAULT 'kg',
  pvp_unitari NUMERIC(12,4) NOT NULL DEFAULT 0 CHECK (pvp_unitari >= 0),
  observacions TEXT,
  actiu BOOLEAN NOT NULL DEFAULT true,
  creat_per UUID DEFAULT auth.uid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Un producto solo puede tener una ficha activa. Las fichas históricas se
-- conservan poniéndolas a actiu = false, sin borrar el cálculo original.
CREATE UNIQUE INDEX IF NOT EXISTS uq_obrador_escandalls_producte_actiu
  ON public.obrador_escandalls (id_producte)
  WHERE id_producte IS NOT NULL AND actiu;
CREATE INDEX IF NOT EXISTS idx_obrador_escandalls_nom
  ON public.obrador_escandalls (nom);

CREATE TABLE IF NOT EXISTS public.obrador_escandall_ingredients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_escandall UUID NOT NULL REFERENCES public.obrador_escandalls(id) ON DELETE CASCADE,
  nom TEXT NOT NULL CHECK (length(trim(nom)) > 0),
  quantitat NUMERIC(12,4) NOT NULL CHECK (quantitat > 0),
  unitat TEXT NOT NULL,
  cost_unitari NUMERIC(12,4) NOT NULL CHECK (cost_unitari >= 0),
  merma_percent NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (merma_percent BETWEEN 0 AND 100),
  ordre INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_obrador_escandall_ingredients_escandall
  ON public.obrador_escandall_ingredients (id_escandall, ordre);

CREATE TABLE IF NOT EXISTS public.obrador_kpis_mensuales (
  mes DATE PRIMARY KEY CHECK (mes = date_trunc('month', mes)::date),
  personas_insercion INTEGER NOT NULL DEFAULT 0 CHECK (personas_insercion >= 0),
  horas_formacion NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (horas_formacion >= 0),
  contrataciones INTEGER NOT NULL DEFAULT 0 CHECK (contrataciones >= 0),
  observaciones TEXT,
  actualizado_por UUID DEFAULT auth.uid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.obrador_actualizar_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obrador_escandalls_updated_at ON public.obrador_escandalls;
CREATE TRIGGER trg_obrador_escandalls_updated_at
  BEFORE UPDATE ON public.obrador_escandalls
  FOR EACH ROW EXECUTE FUNCTION public.obrador_actualizar_updated_at();

DROP TRIGGER IF EXISTS trg_obrador_kpis_mensuales_updated_at ON public.obrador_kpis_mensuales;
CREATE TRIGGER trg_obrador_kpis_mensuales_updated_at
  BEFORE UPDATE ON public.obrador_kpis_mensuales
  FOR EACH ROW EXECUTE FUNCTION public.obrador_actualizar_updated_at();

ALTER TABLE public.obrador_escandalls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obrador_escandall_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obrador_kpis_mensuales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS obrador_escandalls_select_management ON public.obrador_escandalls;
CREATE POLICY obrador_escandalls_select_management ON public.obrador_escandalls
  FOR SELECT TO authenticated
  USING (public.obrador_is_management_user());
DROP POLICY IF EXISTS obrador_escandalls_write_management ON public.obrador_escandalls;
CREATE POLICY obrador_escandalls_write_management ON public.obrador_escandalls
  FOR ALL TO authenticated
  USING (public.obrador_is_management_user())
  WITH CHECK (public.obrador_is_management_user());

DROP POLICY IF EXISTS obrador_escandall_ingredients_select_management ON public.obrador_escandall_ingredients;
CREATE POLICY obrador_escandall_ingredients_select_management ON public.obrador_escandall_ingredients
  FOR SELECT TO authenticated
  USING (public.obrador_is_management_user());
DROP POLICY IF EXISTS obrador_escandall_ingredients_write_management ON public.obrador_escandall_ingredients;
CREATE POLICY obrador_escandall_ingredients_write_management ON public.obrador_escandall_ingredients
  FOR ALL TO authenticated
  USING (public.obrador_is_management_user())
  WITH CHECK (public.obrador_is_management_user());

DROP POLICY IF EXISTS obrador_kpis_mensuales_select_management ON public.obrador_kpis_mensuales;
CREATE POLICY obrador_kpis_mensuales_select_management ON public.obrador_kpis_mensuales
  FOR SELECT TO authenticated
  USING (public.obrador_is_management_user());
DROP POLICY IF EXISTS obrador_kpis_mensuales_write_management ON public.obrador_kpis_mensuales;
CREATE POLICY obrador_kpis_mensuales_write_management ON public.obrador_kpis_mensuales
  FOR ALL TO authenticated
  USING (public.obrador_is_management_user())
  WITH CHECK (public.obrador_is_management_user());
