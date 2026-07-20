-- ============================================================
--  Akrab Pharma – Production RPC Function (v3)
--  Drop + recreate (idempotent)
-- ============================================================

DROP FUNCTION IF EXISTS public.get_nearest_duty_pharmacies(
  DOUBLE PRECISION, DOUBLE PRECISION, TEXT
);

CREATE OR REPLACE FUNCTION public.get_nearest_duty_pharmacies(
  user_lat  DOUBLE PRECISION,
  user_lng  DOUBLE PRECISION,
  target_date TEXT DEFAULT NULL
)
RETURNS TABLE (
  id              UUID,
  name_ar         TEXT,
  name_fr         TEXT,
  municipality    TEXT,
  phone_number    TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  is_night_duty   BOOLEAN,
  duty_date       DATE,
  distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_point   geography;
  search_date  DATE;
BEGIN
  -- 1. Default to today if no date provided
  search_date := COALESCE(target_date::DATE, CURRENT_DATE);

  -- 2. Build the user's geographic point (SRID 4326 = WGS-84)
  user_point := ST_SetSRID(
                  ST_MakePoint(user_lng, user_lat), 4326
                )::geography;

  -- 3. Return query
  --    PRIMARY sort: distance (nearest first) — uses Haversine via geography
  --    SECONDARY sort: most recently created pharmacy first
  --    INNER JOIN returns 0 rows when no schedules match (no error).
  RETURN QUERY
  SELECT
    p.id,
    p.name_ar,
    p.name_fr,
    p.municipality,
    p.phone_number,
    ROUND((ST_Y(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ROUND((ST_X(p.location::geometry))::NUMERIC, 6)::DOUBLE PRECISION,
    ds.is_night_duty,
    ds.duty_date,
    ROUND((ST_Distance(p.location, user_point))::NUMERIC, 1)::DOUBLE PRECISION
  FROM public.pharmacies p
  INNER JOIN public.duty_schedules ds
    ON ds.pharmacy_id = p.id
  WHERE ds.duty_date = search_date
  ORDER BY
    ST_Distance(p.location, user_point) ASC,  -- nearest first
    p.created_at DESC;                         -- most recently added first
END;
$$;

-- ============================================================
-- Test queries
-- ============================================================

-- Today's duty pharmacies sorted by distance + recency
SELECT * FROM get_nearest_duty_pharmacies(36.4620, 7.4290);

-- Specific date (returns empty if no duty that day — not an error)
SELECT * FROM get_nearest_duty_pharmacies(36.4620, 7.4290, '2026-07-17');

-- Count how many are on duty
SELECT count(*) AS total FROM get_nearest_duty_pharmacies(36.4620, 7.4290);
