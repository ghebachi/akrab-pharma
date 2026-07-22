-- ============================================================
--  Akrab Pharma – site_visits table + increment RPC
--  Run this in the Supabase SQL Editor.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.site_visits (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visited_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;

-- Anyone can record a visit
DROP POLICY IF EXISTS "Anyone can record visits" ON public.site_visits;
CREATE POLICY "Anyone can record visits"
  ON public.site_visits FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Only admins can count visits
DROP POLICY IF EXISTS "Admins can count visits" ON public.site_visits;
CREATE POLICY "Admins can count visits"
  ON public.site_visits FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- RPC: increment visit count (call once per app open)
CREATE OR REPLACE FUNCTION public.record_site_visit()
RETURNS void
LANGUAGE sql SECURITY DEFINER
AS $$
  INSERT INTO public.site_visits DEFAULT VALUES;
$$;
