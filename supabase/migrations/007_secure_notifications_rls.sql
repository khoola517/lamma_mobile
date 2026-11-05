-- ========================================================
-- Migration: 007_secure_notifications_rls.sql
-- Description: Strict Row Level Security (RLS), Permissions & Realtime for Notifications
-- ========================================================

-- 1. تفعيل حماية مستوى الصفوف (Row Level Security) على جدول notifications حصراً
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 2. إزالة أي سياسات سابقة لضمان التكرار الآمن (Idempotent Migration)
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_owner" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_disallowed" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_disallowed" ON public.notifications;

-- 3. سياسة القراءة (SELECT): تسمح حصراً للمستخدم المسجل بقراءة إشعاراته فقط
CREATE POLICY "notifications_select_own"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- 4. سياسة التحديث (UPDATE): تسمح للمستخدم بتحديث إشعاراته فقط
CREATE POLICY "notifications_update_own"
ON public.notifications
FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

-- 5. التجريد الكامل والتأمين الصارم للصلاحيات على مستوى الجدول والأعمدة:
-- أولاً: سحب كافة الصلاحيات الموروثة على الجدول تماماً من anon و authenticated
REVOKE ALL ON TABLE public.notifications FROM anon, authenticated;

-- ثانياً: إعادة منح الحد الأدنى المشروع فقط لدور authenticated:
-- السماح بقراءة الإشعارات (المحكومة بسياسة RLS)
GRANT SELECT ON public.notifications TO authenticated;
-- السماح بتحديث حقل is_read فقط دون أي عمود آخر
GRANT UPDATE (is_read) ON public.notifications TO authenticated;

-- 6. دالة ومحفّز (Trigger) لضمان مناعة بيانات الإشعار الأساسية من أي تغيير (Data Immutability)
-- مقارنة جميع الحقول باستخدام IS DISTINCT FROM لضمان المقارنة الآمنة لقيم NULL في كافة الحقول
CREATE OR REPLACE FUNCTION public.enforce_notification_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- التحقق من عدم المساس بأي حقل سوى حالة القراءة is_read
  IF NEW.id IS DISTINCT FROM OLD.id OR
     NEW.user_id IS DISTINCT FROM OLD.user_id OR
     NEW.title IS DISTINCT FROM OLD.title OR
     NEW.body IS DISTINCT FROM OLD.body OR
     NEW.type IS DISTINCT FROM OLD.type OR
     NEW.related_booking_id IS DISTINCT FROM OLD.related_booking_id OR
     NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'غير مصرح: لا يمكن تعديل محتوى الإشعار أو هويته، يُسمح فقط بتحديث حالة القراءة (is_read).';
  END IF;
  RETURN NEW;
END;
$$;

-- ضبط ملكية الدالة ومسار البحث وسحب كافة صلاحيات الاستدعاء المباشر
ALTER FUNCTION public.enforce_notification_immutability() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.enforce_notification_immutability() FROM PUBLIC, anon, authenticated;

-- ربط المشغل قبل عملية التحديث
DROP TRIGGER IF EXISTS trg_enforce_notification_immutability ON public.notifications;
CREATE TRIGGER trg_enforce_notification_immutability
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.enforce_notification_immutability();

-- 7. تفعيل البث اللحظي الآمن (Supabase Realtime) المقيد بـ RLS لجدول notifications
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

ALTER TABLE public.notifications REPLICA IDENTITY FULL;
