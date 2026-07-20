CREATE OR REPLACE FUNCTION public.get_nearest_duty_pharmacies(
  user_lat  DOUBLE PRECISION,
  user_lng  DOUBLE PRECISION,
  target_date TEXT
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
  distance_meters DOUBLE PRECISION
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_point geography;
BEGIN
  user_point := ST_SetSRID(
                  ST_MakePoint(user_lng, user_lat), 4326
                )::geography;

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
    ROUND((ST_Distance(p.location, user_point))::NUMERIC, 1)::DOUBLE PRECISION
  FROM public.pharmacies p
  INNER JOIN public.duty_schedules ds ON ds.pharmacy_id = p.id
  WHERE ds.duty_date = target_date::DATE
  ORDER BY ST_Distance(p.location, user_point) ASC;
END;
$$;
