-- ==============================================================================
-- Migration: 019_auto_cancel_expired_bookings.sql
-- Description:
-- 1. Creates 'cancel_expired_booking' to cancel a booking past its response deadline
--    and record the cancellation reason in status history.
-- 2. Updates 'on_booking_status_change_notifications' so that customer receives
--    a specific friendly push notification when cancelled due to deadline expiration.
-- 3. Creates 'auto_cancel_all_expired_bookings' to batch-cancel any pending bookings
--    older than the provider's response deadline (default 24h).
-- ==============================================================================

-- 1. دالة إلغاء الحجز المنتهية مهلته
CREATE OR REPLACE FUNCTION public.cancel_expired_booking(
  p_booking_id UUID,
  p_reason TEXT DEFAULT 'تجاوز مهلة تأكيد الحجز (24 ساعة)'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_customer_id UUID;
  v_booking_code TEXT;
  v_status TEXT;
  v_notes TEXT;
BEGIN
  SELECT customer_id, booking_code, status, notes
  INTO v_customer_id, v_booking_code, v_status, v_notes
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_booking_code IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'الحجز غير موجود');
  END IF;

  IF v_status <> 'pending' AND v_status <> 'attention_needed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'الحجز ليس في حالة انتظار');
  END IF;

  -- 1. تحديث عناصر الحجز
  UPDATE public.booking_items
  SET item_status = 'rejected',
      rejection_reason = p_reason,
      responded_at = now()
  WHERE booking_id = p_booking_id;

  -- 2. تحديث الحجز الرئيسي إلى cancelled مع تدوين السبب في notes
  UPDATE public.bookings
  SET status = 'cancelled',
      updated_at = now(),
      notes = CASE 
        WHEN v_notes IS NULL OR v_notes = '' THEN 'تم الإلغاء: ' || p_reason
        ELSE v_notes || ' (تم الإلغاء: ' || p_reason || ')'
      END
  WHERE id = p_booking_id;

  -- 3. تسجيل الحدث في سجل الحالات
  INSERT INTO public.booking_status_history (
    booking_id,
    old_status,
    new_status,
    changed_by,
    note
  ) VALUES (
    p_booking_id,
    v_status,
    'cancelled',
    auth.uid(),
    p_reason
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'booking_code', v_booking_code
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_expired_booking(UUID, TEXT) TO authenticated;

-- 2. تحديث دالة إشعارات تغيير الحالة لتخصيص إشعار إلغاء الحجز عند انتهاء المهلة
CREATE OR REPLACE FUNCTION public.on_booking_status_change_notifications()
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
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- تحديد نص ونوع الإشعار بحسب الحالة الجديدة
  IF NEW.status = 'confirmed' THEN
    v_title := 'تم تأكيد حجزك بنجاح 🎉';
    v_body := 'وافق مقدم الخدمة على حجزك رقم (' || NEW.booking_code || ') وأصبح مؤكداً.';
    v_type := 'booking_confirmed';

  ELSIF NEW.status = 'in_progress' THEN
    v_title := 'حجزك قيد التنفيذ ⏳';
    v_body := 'بدأ العمل على طلبك رقم (' || NEW.booking_code || ') وهو قيد التنفيذ الآن.';
    v_type := 'booking_in_progress';

  ELSIF NEW.status = 'completed' THEN
    v_title := 'اكتمل حجزك بنجاح ✅';
    v_body := 'تم إكمال حجزك رقم (' || NEW.booking_code || ') بنجاح. شكراً لاختيارك خِدمتي!';
    v_type := 'booking_completed';

  ELSIF NEW.status = 'attention_needed' THEN
    v_title := 'تحديث بخصوص طلبك ⚠️';
    v_body := 'حجزك رقم (' || NEW.booking_code || ') يتطلب مراجعتك لاتخاذ إجراء.';
    v_type := 'booking_attention_needed';

  ELSIF NEW.status = 'cancelled' THEN
    IF NEW.notes LIKE '%تجاوز مهلة%' OR NEW.notes LIKE '%24 ساعة%' THEN
      v_title := 'تم إلغاء الحجز لتجاوز مهلة الرد ⏳';
      v_body := 'تم إلغاء طلب حجزك رقم (' || NEW.booking_code || ') نظراً لانتهاء المهلة المحددة للرد من مقدم الخدمة.';
    ELSE
      v_title := 'تم إلغاء الحجز ❌';
      v_body := 'تم إلغاء حجزك رقم (' || NEW.booking_code || ').';
    END IF;
    v_type := 'booking_cancelled';

    -- إشعار لكافة مزودي الخدمات المرتبطين بهذا الحجز عند الإلغاء
    INSERT INTO public.notifications (user_id, title, body, type, related_booking_id)
    SELECT DISTINCT
      pp.user_id,
      'إلغاء طلب حجز',
      'تم إلغاء الحجز رقم (' || NEW.booking_code || ') المتضمن خدمتك (' || s.name || ').',
      'booking_cancelled',
      NEW.id
    FROM public.booking_items bi
    JOIN public.services s ON s.id = bi.service_id
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE bi.booking_id = NEW.id AND pp.user_id IS NOT NULL;
  END IF;

  -- إرسال الإشعار للعميل
  IF v_title IS NOT NULL AND NEW.customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, related_booking_id)
    VALUES (NEW.customer_id, v_title, v_body, v_type, NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

-- 3. دالة فحص وإلغاء كافة الحجوزات المعلقة التي تجاوزت مهلة الرد دفعة واحدة
CREATE OR REPLACE FUNCTION public.auto_cancel_all_expired_bookings()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_rec RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_rec IN (
    SELECT DISTINCT
      b.id,
      b.booking_code,
      COALESCE((pp.settings->>'default_response_hours')::INT, 24) AS deadline_hours
    FROM public.bookings b
    JOIN public.booking_items bi ON bi.booking_id = b.id
    JOIN public.services s ON s.id = bi.service_id
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE b.status = 'pending'
      AND b.created_at < (now() - (COALESCE((pp.settings->>'default_response_hours')::INT, 24) || ' hours')::INTERVAL)
  )
  LOOP
    PERFORM public.cancel_expired_booking(
      v_rec.id,
      'تجاوز مهلة تأكيد الحجز (' || v_rec.deadline_hours || ' ساعة)'
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.auto_cancel_all_expired_bookings() TO authenticated;

