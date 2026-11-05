-- ========================================================
-- Migration: 002_security_helpers.sql
-- Description: Central security helper functions with search_path protection
-- ========================================================

-- 1. دالة فحص صلاحية الأدمن الآمنة (تقطع حلقة تكرار RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  );
$$;

-- 2. دالة استرجاع معرف مزود الخدمة المعتمد للمستخدم الحالي
CREATE OR REPLACE FUNCTION public.get_my_provider_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT id FROM public.provider_profiles
  WHERE user_id = auth.uid() AND status = 'approved'
  LIMIT 1;
$$;

-- 3. دالة تحديث حقل updated_at التلقائية
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
