-- ============================================================
-- Akrab Pharma – Initial Database Schema
-- Province: Guelma, Algeria
-- Stack: Supabase (PostgreSQL + PostGIS + RLS)
-- ============================================================

-- 0. Extensions
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- 1. Custom ENUM type
-- ============================================================
CREATE TYPE public.report_type AS ENUM (
  'closed',
  'wrong_location',
  'wrong_phone'
);

-- 2. Table: pharmacies
-- ============================================================
CREATE TABLE public.pharmacies (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  address       TEXT NOT NULL,
  municipality  TEXT NOT NULL,                       -- e.g. 'Guelma Center', 'Oued Zenati', 'Bouchegouf'
  phone_number  TEXT,
  whatsapp_number TEXT,
  location      extensions.geography(Point, 4326) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pharmacies_location
  ON public.pharmacies USING GIST (location);

CREATE INDEX idx_pharmacies_municipality
  ON public.pharmacies (municipality);

-- 3. Table: duty_schedules
-- ============================================================
CREATE TABLE public.duty_schedules (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id   UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  duty_date     DATE NOT NULL,
  is_night_duty BOOLEAN NOT NULL DEFAULT false,

  UNIQUE (pharmacy_id, duty_date, is_night_duty)
);

CREATE INDEX idx_duty_schedules_date
  ON public.duty_schedules (duty_date);

CREATE INDEX idx_duty_schedules_pharmacy_date
  ON public.duty_schedules (pharmacy_id, duty_date);

-- 4. Table: user_reports
-- ============================================================
CREATE TABLE public.user_reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id   UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  report_type   public.report_type NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_reports_pharmacy
  ON public.user_reports (pharmacy_id);

-- 5. Table: admin_users (controls write access via RLS)
-- ============================================================
CREATE TABLE public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view their own row"
  ON public.admin_users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 6. RPC Function: get_nearest_duty_pharmacies
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_nearest_duty_pharmacies(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  target_date TEXT
)
RETURNS TABLE (
  id              UUID,
  name            TEXT,
  address         TEXT,
  municipality    TEXT,
  phone_number    TEXT,
  whatsapp_number TEXT,
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
    ds.is_night_duty,
    ROUND(
      (extensions.ST_Distance(p.location, user_point))::NUMERIC,
      1
    )::DOUBLE PRECISION AS distance_meters
  FROM public.pharmacies p
  INNER JOIN public.duty_schedules ds
    ON ds.pharmacy_id = p.id
  WHERE ds.duty_date = target_date::DATE
  ORDER BY extensions.ST_Distance(p.location, user_point) ASC;
END;
$$;

-- 7. Row Level Security
-- ============================================================
ALTER TABLE public.pharmacies      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duty_schedules  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports    ENABLE ROW LEVEL SECURITY;

-- 7a. pharmacies – public read
CREATE POLICY "Public can view pharmacies"
  ON public.pharmacies
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 7b. pharmacies – admin write
CREATE POLICY "Admins can insert pharmacies"
  ON public.pharmacies
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update pharmacies"
  ON public.pharmacies
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can delete pharmacies"
  ON public.pharmacies
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

-- 7c. duty_schedules – public read
CREATE POLICY "Public can view duty schedules"
  ON public.duty_schedules
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 7d. duty_schedules – admin write
CREATE POLICY "Admins can insert duty schedules"
  ON public.duty_schedules
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update duty schedules"
  ON public.duty_schedules
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can delete duty schedules"
  ON public.duty_schedules
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

-- 7e. user_reports – public can insert (anonymous feedback)
CREATE POLICY "Public can submit reports"
  ON public.user_reports
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- 7f. user_reports – admin read
CREATE POLICY "Admins can view reports"
  ON public.user_reports
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );

-- 7g. user_reports – admin delete
CREATE POLICY "Admins can delete reports"
  ON public.user_reports
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users au
      WHERE au.user_id = auth.uid()
    )
  );
