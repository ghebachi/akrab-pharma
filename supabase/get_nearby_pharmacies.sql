-- ============================================================
--  Akrab Pharma – get_nearby_pharmacies RPC
--  Returns all pharmacies within 25 km, sorted by distance.
--  Run this in the Supabase SQL Editor.
-- ============================================================

DROP FUNCTION IF EXISTS public.get_nearby_pharmacies(DOUBLE PRECISION, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION public.get_nearby_pharmacies(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION
)
RETURNS TABLE (
  id              UUID,
  name_ar         TEXT,
  name_fr         TEXT,
  municipality    TEXT,
  phone_number    TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.name_ar,
    p.name_fr,
    p.municipality,
    p.phone_number,
    ROUND((ST_Y(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ROUND((ST_X(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ROUND(
      (ST_DistanceSphere(p.location::geometry, ST_MakePoint(user_lng, user_lat)))::NUMERIC,
      0
    )::DOUBLE PRECISION AS distance_meters
  FROM public.pharmacies p
  WHERE ST_DWithin(
    p.location::geography,
    ST_MakePoint(user_lng, user_lat)::geography,
    25000
  )
  ORDER BY distance_meters ASC;
END;
$$;

-- Test
SELECT * FROM get_nearby_pharmacies(36.4647, 7.4297);
