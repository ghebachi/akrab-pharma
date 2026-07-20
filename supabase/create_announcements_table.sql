-- ============================================================
--  Akrab Pharma – Site Announcements table
--  Run this in the Supabase SQL Editor.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.site_announcements (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title       TEXT NOT NULL DEFAULT '',
  message     TEXT NOT NULL DEFAULT '',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- RLS: anyone can read active announcements, only anon key can insert
ALTER TABLE public.site_announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read active announcements"
  ON public.site_announcements
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Service role can manage announcements"
  ON public.site_announcements
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- Test: insert a sample announcement
-- ============================================================
-- INSERT INTO public.site_announcements (title, message, is_active)
-- VALUES ('Maintenance Notice', 'The app will be updated tonight from 2AM-4AM.', true);
