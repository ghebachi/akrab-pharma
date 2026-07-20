-- ============================================================
--  Akrab Pharma – Add pharmacist auth columns to pharmacies
--  Run this in the Supabase SQL Editor.
-- ============================================================

-- 1. Add pharmacist_id (links to auth.users) and is_duty toggle
ALTER TABLE public.pharmacies
  ADD COLUMN IF NOT EXISTS pharmacist_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_duty       BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_pharmacies_pharmacist
  ON public.pharmacies (pharmacist_id);

-- 2. Pharmacists can read their own pharmacy row
DROP POLICY IF EXISTS "Pharmacists can view their pharmacy" ON public.pharmacies;
CREATE POLICY "Pharmacists can view their pharmacy"
  ON public.pharmacies FOR SELECT
  TO authenticated
  USING (
    pharmacist_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- 3. Pharmacists can update their own pharmacy row (is_duty only enforced via app)
DROP POLICY IF EXISTS "Pharmacists can update their pharmacy" ON public.pharmacies;
CREATE POLICY "Pharmacists can update their pharmacy"
  ON public.pharmacies FOR UPDATE
  TO authenticated
  USING (
    pharmacist_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  )
  WITH CHECK (
    pharmacist_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- 4. Example: link a pharmacy to a pharmacist
-- UPDATE public.pharmacies
-- SET pharmacist_id = '<auth-user-uuid>'
-- WHERE id = 'a1000000-0000-0000-0000-000000000001';
