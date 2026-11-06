-- ========================================================
-- Migration: 013_admin_broadcast_and_realtime_enhancements.sql
-- Description: Enable Realtime for complaint_categories,
--              add secure RPC for Admin broadcast notifications,
--              and ensure full Realtime publication coverage.
-- ========================================================

-- 1. Ensure complaint_categories is included in supabase_realtime publication
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'complaint_categories'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'complaint_categories'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_categories;
      RAISE NOTICE 'Added complaint_categories to supabase_realtime publication.';
    END IF;
  END IF;
END $$;

-- 2. Ensure REPLICA IDENTITY FULL on complaint_categories
ALTER TABLE IF EXISTS public.complaint_categories REPLICA IDENTITY FULL;

-- 3. Secure RPC for Admin Broadcast Notifications
-- Allows authorized administrators to broadcast system notifications
-- to all users, providers, or customers without violating strict RLS permissions.
CREATE OR REPLACE FUNCTION public.send_admin_broadcast_notification(
  p_title TEXT,
  p_body TEXT,
  p_type TEXT DEFAULT 'announcement',
  p_target_audience TEXT DEFAULT 'all' -- 'all', 'providers', 'customers'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_admin_id UUID;
  v_inserted_count INTEGER := 0;
BEGIN
  -- 1. التحقق من جلسة المصادقة وصلاحية الأدمن
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'غير مصرح: يجب أن تكون مسؤول نظام لإرسال الإشعارات والتعميمات.';
  END IF;

  -- 2. التحقق من المدخلات
  IF p_title IS NULL OR trim(p_title) = '' THEN
    RAISE EXCEPTION 'عنوان الإشعار مطلوب.';
  END IF;
  IF p_body IS NULL OR trim(p_body) = '' THEN
    RAISE EXCEPTION 'نص رسالة الإشعار مطلوب.';
  END IF;

  -- 3. إدراج الإشعارات للمستخدمين المستهدفين
  INSERT INTO public.notifications (user_id, title, body, type, is_read, created_at)
  SELECT 
    p.id,
    p_title,
    p_body,
    COALESCE(p_type, 'announcement'),
    false,
    now()
  FROM public.profiles p
  WHERE p.is_active = true
    AND (
      p_target_audience = 'all'
      OR (p_target_audience = 'providers' AND p.role = 'provider')
      OR (p_target_audience = 'customers' AND p.role = 'customer')
    );

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'target_audience', p_target_audience,
    'message', 'تم بث الإشعار بنجاح إلى ' || v_inserted_count || ' مستخدم.'
  );
END;
$$;

-- ضبط الملكية والصلاحيات للدالة
ALTER FUNCTION public.send_admin_broadcast_notification(TEXT, TEXT, TEXT, TEXT) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.send_admin_broadcast_notification(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_admin_broadcast_notification(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 4. تعليق توثيقي
COMMENT ON FUNCTION public.send_admin_broadcast_notification IS 
  'Secure atomic function for administrators to broadcast real-time notifications to users.';

