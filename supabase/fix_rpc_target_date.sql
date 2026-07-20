-- ============================================================
-- Akrab Pharma – Fix RPC: target_date TEXT (fixes 400 error)
-- Run this in Supabase SQL Editor
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_nearest_duty_pharmacies(
  user_lat  DOUBLE PRECISION,
  user_lng  DOUBLE PRECISION,
  target_date TEXT
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
  WHERE ds.duty_date = target_date::DATE
  ORDER BY extensions.ST_Distance(p.location, user_point) ASC;
END;
$$;

-- Test it:
SELECT * FROM get_nearest_duty_pharmacies(36.4620, 7.4290, '2026-07-16');
