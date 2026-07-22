-- ============================================================
--  Akrab Pharma – Admin panel RPCs (optimized)
--  Run this in the Supabase SQL Editor.
-- ============================================================

-- 1. Single RPC: all admin stats in one query
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS TABLE (
  total_visits       BIGINT,
  total_pharmacies   BIGINT,
  total_schedules    BIGINT,
  night_schedules    BIGINT,
  total_reports      BIGINT
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    (SELECT count(*) FROM public.site_visits)::BIGINT,
    (SELECT count(*) FROM public.pharmacies)::BIGINT,
    (SELECT count(*) FROM public.duty_schedules
      WHERE duty_date >= (CURRENT_DATE - INTERVAL '30 days'))::BIGINT,
    (SELECT count(*) FROM public.duty_schedules
      WHERE is_night_duty = true
        AND duty_date >= (CURRENT_DATE - INTERVAL '30 days'))::BIGINT,
    (SELECT count(*) FROM public.user_reports)::BIGINT;
$$;

-- 2. Duty schedules joined with pharmacy info (filtered by date + night)
CREATE OR REPLACE FUNCTION public.get_admin_schedules(
  p_start_date DATE DEFAULT NULL,
  p_end_date   DATE DEFAULT NULL,
  p_night_only BOOLEAN DEFAULT false
)
RETURNS TABLE (
  schedule_id   UUID,
  duty_date     DATE,
  is_night_duty BOOLEAN,
  pharmacy_id   UUID,
  name_ar       TEXT,
  name_fr       TEXT,
  municipality  TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ds.id,
    ds.duty_date,
    ds.is_night_duty,
    p.id,
    p.name_ar,
    p.name_fr,
    p.municipality
  FROM public.duty_schedules ds
  INNER JOIN public.pharmacies p ON ds.pharmacy_id = p.id
  WHERE (p_start_date IS NULL OR ds.duty_date >= p_start_date)
    AND (p_end_date   IS NULL OR ds.duty_date <= p_end_date)
    AND (p_night_only = false OR ds.is_night_duty = true)
  ORDER BY ds.duty_date DESC, p.name_ar ASC;
$$;

-- 3. Reports joined with pharmacy info
CREATE OR REPLACE FUNCTION public.get_admin_reports()
RETURNS TABLE (
  report_id     UUID,
  report_type   TEXT,
  created_at    TIMESTAMPTZ,
  pharmacy_id   UUID,
  name_ar       TEXT,
  name_fr       TEXT,
  municipality  TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ur.id,
    ur.report_type::TEXT,
    ur.created_at,
    p.id,
    p.name_ar,
    p.name_fr,
    p.municipality
  FROM public.user_reports ur
  INNER JOIN public.pharmacies p ON ur.pharmacy_id = p.id
  ORDER BY ur.created_at DESC;
$$;
