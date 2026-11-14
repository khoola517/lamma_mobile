-- Migration: 015_complaints_notifications_automation.sql
-- Description: Automated Push Notifications & Realtime Alerts for Support Complaints & Admin Resolutions

CREATE OR REPLACE FUNCTION public.on_complaint_change_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_title TEXT;
  v_body TEXT;
  v_type TEXT;
BEGIN
  -- 1. عند إنشاء شكوى جديدة من قبل العميل
  IF TG_OP = 'INSERT' THEN
    -- إشعار تأكيد فوري للعميل باستلام الشكوى
    INSERT INTO public.notifications (user_id, title, body, type)
    VALUES (
      NEW.user_id,
      'تم استلام شكواك بنجاح 📋',
      'شكواك بعنوان (' || NEW.subject || ') قيد المراجعة حالياً من قبل الإدارة وسيتم الرد عليك قريباً.',
      'complaint_submitted'
    );

    -- إشعار لجميع مسؤولي النظام (Admins) بتوفر شكوى جديدة لمراجعتها
    INSERT INTO public.notifications (user_id, title, body, type)
    SELECT id, 'شكوى / بلاغ جديد ⚠️', 'وصلت شكوى جديدة من العميل بعنوان: ' || NEW.subject, 'admin_complaint_alert'
    FROM public.profiles
    WHERE role = 'admin' AND is_active = true;

    RETURN NEW;
  END IF;

  -- 2. عند تحديث الشكوى (مثل رد الإدارة أو تغيير الحالة)
  IF TG_OP = 'UPDATE' THEN
    -- أ. إذا قامت الإدارة بكتابة رد / حل جديد للعميل
    IF NEW.resolution IS DISTINCT FROM OLD.resolution AND NEW.resolution IS NOT NULL AND trim(NEW.resolution) <> '' THEN
      v_title := 'تم الرد على شكواك من الإدارة 💬';
      v_body := 'قامت إدارة خِدمتي بالرد على شكواك (' || NEW.subject || '): ' || NEW.resolution;
      v_type := 'complaint_resolution';

    -- ب. إذا تم تغيير الحالة إلى "تم الحل"
    ELSIF NEW.status = 'resolved' AND OLD.status IS DISTINCT FROM 'resolved' THEN
      v_title := 'تم حل شكواك بنجاح ✅';
      v_body := 'تمت معالجة شكواك (' || NEW.subject || ') بنجاح من قبل إدارة المنصة.' || COALESCE(' القرار: ' || NEW.resolution, '');
      v_type := 'complaint_resolved';

    -- ج. إذا تم تغيير الحالة إلى "قيد المعالجة"
    ELSIF NEW.status = 'in_review' AND OLD.status IS DISTINCT FROM 'in_review' THEN
      v_title := 'شكواك قيد المراجعة 🔍';
      v_body := 'بدأ فريق خدمة العملاء بمراجعة تفاصيل شكواك (' || NEW.subject || ').';
      v_type := 'complaint_in_review';

    -- د. إذا تم إغلاق الشكوى أو رفضها
    ELSIF NEW.status = 'closed' AND OLD.status IS DISTINCT FROM 'closed' THEN
      v_title := 'تم إغلاق ملف الشكوى 📁';
      v_body := 'تم إغلاق شكواك (' || NEW.subject || ').' || COALESCE(' الملاحظات: ' || NEW.resolution, '');
      v_type := 'complaint_closed';
    END IF;

    -- إرسال الإشعار للعميل صاحب الشكوى
    IF v_title IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, title, body, type)
      VALUES (
        NEW.user_id,
        v_title,
        v_body,
        v_type
      );
    END IF;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.on_complaint_change_notifications() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.on_complaint_change_notifications() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_complaint_notifications ON public.complaints;
CREATE TRIGGER trg_complaint_notifications
AFTER INSERT OR UPDATE ON public.complaints
FOR EACH ROW
EXECUTE FUNCTION public.on_complaint_change_notifications();

