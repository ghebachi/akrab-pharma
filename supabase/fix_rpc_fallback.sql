-- ============================================================
--  Akrab Pharma – Fallback RPC: all pharmacies sorted by distance
--  Used when get_nearest_duty_pharmacies returns [] (no duty today)
-- ============================================================

DROP FUNCTION IF EXISTS public.get_all_pharmacies_by_distance(
  DOUBLE PRECISION, DOUBLE PRECISION
);

CREATE OR REPLACE FUNCTION public.get_all_pharmacies_by_distance(
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
DECLARE
  user_point geography;
BEGIN
  user_point := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    p.id,
    p.name_ar,
    p.name_fr,
    p.municipality,
    p.phone_number,
    ROUND((ST_Y(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ROUND((ST_X(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ROUND((ST_Distance(p.location, user_point))::NUMERIC, 1)::DOUBLE PRECISION
  FROM public.pharmacies p
  ORDER BY ST_Distance(p.location, user_point) ASC;
END;
$$;

-- Test
SELECT * FROM get_all_pharmacies_by_distance(36.4620, 7.4290);
