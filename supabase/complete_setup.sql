-- ============================================================
--  Akrab Pharma – Complete Database Setup
--  Province: Guelma, Algeria
--  Stack: Supabase (PostgreSQL + PostGIS + RLS)
--
--  Run this ENTIRE script in the Supabase SQL Editor.
--  It is idempotent: safe to re-run (drops then recreates).
-- ============================================================

-- ============================================================
-- 0. CLEANUP (idempotent)
-- ============================================================
DROP FUNCTION IF EXISTS public.get_nearest_duty_pharmacies(
  DOUBLE PRECISION, DOUBLE PRECISION, DATE
);
DROP POLICY IF EXISTS "Public can view pharmacies"        ON public.pharmacies;
DROP POLICY IF EXISTS "Admins can insert pharmacies"      ON public.pharmacies;
DROP POLICY IF EXISTS "Admins can update pharmacies"      ON public.pharmacies;
DROP POLICY IF EXISTS "Admins can delete pharmacies"      ON public.pharmacies;
DROP POLICY IF EXISTS "Public can view duty schedules"    ON public.duty_schedules;
DROP POLICY IF EXISTS "Admins can insert duty schedules"  ON public.duty_schedules;
DROP POLICY IF EXISTS "Admins can update duty schedules"  ON public.duty_schedules;
DROP POLICY IF EXISTS "Admins can delete duty schedules"  ON public.duty_schedules;
DROP POLICY IF EXISTS "Public can submit reports"         ON public.user_reports;
DROP POLICY IF EXISTS "Admins can view reports"           ON public.user_reports;
DROP POLICY IF EXISTS "Admins can delete reports"         ON public.user_reports;
DROP POLICY IF EXISTS "Admins can view their own row"     ON public.admin_users;

ALTER TABLE public.user_reports    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.duty_schedules  DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacies      DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users     DISABLE ROW LEVEL SECURITY;

DROP TABLE IF EXISTS public.user_reports    CASCADE;
DROP TABLE IF EXISTS public.duty_schedules  CASCADE;
DROP TABLE IF EXISTS public.admin_users     CASCADE;
DROP TABLE IF EXISTS public.pharmacies      CASCADE;
DROP TYPE  IF EXISTS public.report_type     CASCADE;

-- ============================================================
-- 1. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- ============================================================
-- 2. CUSTOM ENUM TYPE
-- ============================================================
CREATE TYPE public.report_type AS ENUM (
  'closed',
  'wrong_location',
  'wrong_phone'
);

-- ============================================================
-- 3. TABLES
-- ============================================================

-- 3a. pharmacies
CREATE TABLE public.pharmacies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  address         TEXT NOT NULL,
  municipality    TEXT NOT NULL,
  phone_number    TEXT,
  whatsapp_number TEXT,
  location        extensions.geography(Point, 4326) NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pharmacies_location   ON public.pharmacies USING GIST (location);
CREATE INDEX idx_pharmacies_municipality ON public.pharmacies (municipality);

-- 3b. duty_schedules
CREATE TABLE public.duty_schedules (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id   UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  duty_date     DATE NOT NULL,
  is_night_duty BOOLEAN NOT NULL DEFAULT false,

  UNIQUE (pharmacy_id, duty_date, is_night_duty)
);

CREATE INDEX idx_duty_schedules_date          ON public.duty_schedules (duty_date);
CREATE INDEX idx_duty_schedules_pharmacy_date ON public.duty_schedules (pharmacy_id, duty_date);

-- 3c. user_reports
CREATE TABLE public.user_reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  report_type public.report_type NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_reports_pharmacy ON public.user_reports (pharmacy_id);

-- 3d. admin_users
CREATE TABLE public.admin_users (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view their own row"
  ON public.admin_users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- 4. RPC FUNCTION: get_nearest_duty_pharmacies
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_nearest_duty_pharmacies(
  user_lat  DOUBLE PRECISION,
  user_lng  DOUBLE PRECISION,
  target_date DATE
)
RETURNS TABLE (
  id              UUID,
  name            TEXT,
  address         TEXT,
  municipality    TEXT,
  phone_number    TEXT,
  whatsapp_number TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  is_night_duty   BOOLEAN,
  distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_point extensions.geography;
BEGIN
  user_point := extensions.ST_SetSRID(
                  extensions.ST_MakePoint(user_lng, user_lat),
                  4326
                )::extensions.geography;

  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.address,
    p.municipality,
    p.phone_number,
    p.whatsapp_number,
    ROUND(
      (extensions.ST_Y(p.location::extensions.geometry))::NUMERIC,
      6
    )::DOUBLE PRECISION AS latitude,
    ROUND(
      (extensions.ST_X(p.location::extensions.geometry))::NUMERIC,
      6
    )::DOUBLE PRECISION AS longitude,
    ds.is_night_duty,
    ROUND(
      (extensions.ST_Distance(p.location, user_point))::NUMERIC,
      1
    )::DOUBLE PRECISION AS distance_meters
  FROM public.pharmacies p
  INNER JOIN public.duty_schedules ds
    ON ds.pharmacy_id = p.id
  WHERE ds.duty_date = target_date
  ORDER BY extensions.ST_Distance(p.location, user_point) ASC;
END;
$$;

-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================

-- 5a. pharmacies
ALTER TABLE public.pharmacies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view pharmacies"
  ON public.pharmacies FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Admins can insert pharmacies"
  ON public.pharmacies FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE POLICY "Admins can update pharmacies"
  ON public.pharmacies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE POLICY "Admins can delete pharmacies"
  ON public.pharmacies FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- 5b. duty_schedules
ALTER TABLE public.duty_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view duty schedules"
  ON public.duty_schedules FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Admins can insert duty schedules"
  ON public.duty_schedules FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE POLICY "Admins can update duty schedules"
  ON public.duty_schedules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE POLICY "Admins can delete duty schedules"
  ON public.duty_schedules FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- 5c. user_reports
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can submit reports"
  ON public.user_reports FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can view reports"
  ON public.user_reports FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE POLICY "Admins can delete reports"
  ON public.user_reports FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- ============================================================
-- 6. MOCK DATA — Guelma pharmacies + July 2026 duty roster
-- ============================================================

-- 6a. Pharmacies (3 locations in Guelma)
INSERT INTO public.pharmacies (id, name, address, municipality, phone_number, whatsapp_number, location)
VALUES
  (
    'a1000000-0000-0000-0000-000000000001',
    'Pharmacie Centrale',
    'Rue Didouche Mourad, Centre-ville',
    'Guelma Centre',
    '+213 34 71 00 01',
    '+213 555 00 01 01',
    extensions.ST_SetSRID(extensions.ST_MakePoint(7.4290, 36.4620), 4326)::extensions.geography
  ),
  (
    'a1000000-0000-0000-0000-000000000002',
    'Pharmacie de la Gare',
    'Avenue de la Gare, ancien quartier SNCF',
    'Guelma Centre',
    '+213 34 71 00 02',
    '+213 555 00 02 02',
    extensions.ST_SetSRID(extensions.ST_MakePoint(7.4325, 36.4685), 4326)::extensions.geography
  ),
  (
    'a1000000-0000-0000-0000-000000000003',
    'Pharmacie Bab Souk',
    'Rue du Marché, Bab Souk',
    'Guelma Centre',
    '+213 34 71 00 03',
    '+213 555 00 03 03',
    extensions.ST_SetSRID(extensions.ST_MakePoint(7.4220, 36.4580), 4326)::extensions.geography
  );

-- 6b. Duty schedules — July 16 – July 23, 2026
--     Mix of day and night duties across the three pharmacies.
INSERT INTO public.duty_schedules (pharmacy_id, duty_date, is_night_duty)
VALUES
  -- July 16 (today)
  ('a1000000-0000-0000-0000-000000000001', '2026-07-16', false),
  ('a1000000-0000-0000-0000-000000000001', '2026-07-16', true),
  ('a1000000-0000-0000-0000-000000000002', '2026-07-16', false),

  -- July 17
  ('a1000000-0000-0000-0000-000000000002', '2026-07-17', true),
  ('a1000000-0000-0000-0000-000000000003', '2026-07-17', false),

  -- July 18
  ('a1000000-0000-0000-0000-000000000003', '2026-07-18', true),
  ('a1000000-0000-0000-0000-000000000001', '2026-07-18', false),

  -- July 19
  ('a1000000-0000-0000-0000-000000000001', '2026-07-19', true),
  ('a1000000-0000-0000-0000-000000000002', '2026-07-19', false),

  -- July 20
  ('a1000000-0000-0000-0000-000000000002', '2026-07-20', true),
  ('a1000000-0000-0000-0000-000000000003', '2026-07-20', false),

  -- July 21
  ('a1000000-0000-0000-0000-000000000003', '2026-07-21', true),
  ('a1000000-0000-0000-0000-000000000001', '2026-07-21', false),

  -- July 22
  ('a1000000-0000-0000-0000-000000000001', '2026-07-22', true),
  ('a1000000-0000-0000-0000-000000000002', '2026-07-22', false),

  -- July 23
  ('a1000000-0000-0000-0000-000000000003', '2026-07-23', false),
  ('a1000000-0000-0000-0000-000000000003', '2026-07-23', true);

-- ============================================================
-- DONE
-- ============================================================
