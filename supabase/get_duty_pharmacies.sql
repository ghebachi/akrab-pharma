-- ============================================================
--  Akrab Pharma – get_duty_pharmacies RPC
--  Returns duty pharmacies for TODAY filtered by wilaya name.
--  Run this in the Supabase SQL Editor.
-- ============================================================

DROP FUNCTION IF EXISTS public.get_duty_pharmacies(TEXT);

CREATE OR REPLACE FUNCTION public.get_duty_pharmacies(
  wilaya_name TEXT
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
    ds.is_night_duty,
    ds.duty_date,
    0::DOUBLE PRECISION AS distance_meters
  FROM public.duty_schedules ds
  INNER JOIN public.pharmacies p ON ds.pharmacy_id = p.id
  WHERE ds.duty_date = CURRENT_DATE
    AND p.municipality = wilaya_name
  ORDER BY ds.is_night_duty ASC, p.name_ar ASC;
END;
$$;

-- Test
SELECT * FROM get_duty_pharmacies('Guelma');
