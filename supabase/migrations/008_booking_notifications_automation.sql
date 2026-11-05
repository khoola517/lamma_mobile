-- ========================================================
-- Migration: 008_booking_notifications_automation.sql
-- Description: Automated Notification Triggers for Booking Lifecycle (Customer & Providers)
-- ========================================================

-- 1. تحديث دالة الحجز الذري create_booking_atomic لتوليد الإشعارات للعميل والمزودين عند إنشاء الحجز
CREATE OR REPLACE FUNCTION public.create_booking_atomic(
  p_event_type TEXT,
  p_event_date DATE,
  p_time_slot TEXT DEFAULT 'evening',
  p_service_ids UUID[] DEFAULT '{}',
  p_package_id UUID DEFAULT NULL,
  p_event_location TEXT DEFAULT NULL,
  p_guest_count INTEGER DEFAULT NULL,
  p_budget NUMERIC DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_customer_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_customer_id UUID;
  v_user_active BOOLEAN;
  v_user_role TEXT;
  v_sorted_ids UUID[];
  v_srv_id UUID;
  v_srv_rec RECORD;
  v_is_available BOOLEAN;
  v_conflict_count INTEGER;
  v_total_amount NUMERIC(12,2) := 0;
  v_new_booking_id UUID;
  v_new_booking_code TEXT;
BEGIN
  -- 1. التحقق من هوية المستخدم وجلسة المصادقة
  v_customer_id := COALESCE(auth.uid(), p_customer_id);
  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول أولاً لإتمام الحجز.';
  END IF;

  SELECT is_active, role INTO v_user_active, v_user_role
  FROM public.profiles
  WHERE id = v_customer_id;

  IF v_user_active IS NOT TRUE THEN
    RAISE EXCEPTION 'تعذر الحجز: حساب المستخدم معطل أو غير مسجل.';
  END IF;

  -- 2. التحقق من صحة المدخلات الأساسية
  IF p_event_type IS NULL OR trim(p_event_type) = '' THEN
    RAISE EXCEPTION 'يرجى تحديد نوع المناسبة.';
  END IF;

  IF p_event_date IS NULL OR p_event_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'تاريخ المناسبة غير صالح أو يقع في الماضي.';
  END IF;

  IF p_time_slot NOT IN ('morning', 'evening', 'full_day') THEN
    RAISE EXCEPTION 'الفترة الزمنية المختارة غير صالحة (%): يجب أن تكون morning أو evening أو full_day.', p_time_slot;
  END IF;

  IF p_service_ids IS NULL OR array_length(p_service_ids, 1) IS NULL OR array_length(p_service_ids, 1) = 0 THEN
    RAISE EXCEPTION 'يجب تحديد خدمة واحدة على الأقل لإتمام الحجز.';
  END IF;

  -- 3. ترتيب المعرفات لمنع التعليق التزامني (Deadlock Prevention)
  SELECT array_agg(DISTINCT id ORDER BY id) INTO v_sorted_ids
  FROM unnest(p_service_ids) AS id;

  -- 4. فحص وحجز الخدمات مع قفل تزامني محكم (Row Lock on Services)
  FOREACH v_srv_id IN ARRAY v_sorted_ids
  LOOP
    PERFORM 1 FROM public.services WHERE id = v_srv_id FOR UPDATE;

    SELECT s.id, s.name, s.price, s.capacity, s.status, pp.status AS provider_status
    INTO v_srv_rec
    FROM public.services s
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE s.id = v_srv_id;

    IF v_srv_rec.id IS NULL THEN
      RAISE EXCEPTION 'الخدمة المعرفة بـ % غير موجودة في النظام.', v_srv_id;
    END IF;

    IF v_srv_rec.status <> 'active' OR v_srv_rec.provider_status <> 'approved' THEN
      RAISE EXCEPTION 'الخدمة (%) غير متاحة للطلب حالياً أو مقدمها غير معتمد.', v_srv_rec.name;
    END IF;

    IF p_guest_count IS NOT NULL AND v_srv_rec.capacity IS NOT NULL AND v_srv_rec.capacity < p_guest_count THEN
      RAISE EXCEPTION 'سعة الخدمة (%) تتسع لـ % ضيف فقط، وهي أقل من الحضور المطلوب (%).', v_srv_rec.name, v_srv_rec.capacity, p_guest_count;
    END IF;

    SELECT is_available INTO v_is_available
    FROM public.service_availability
    WHERE service_id = v_srv_id
      AND available_date = p_event_date
      AND (time_slot = 'full_day' OR time_slot = p_time_slot)
    LIMIT 1;

    IF v_is_available IS FALSE THEN
      RAISE EXCEPTION 'الخدمة (%) غير متاحة للتاريخ أو الفترة الزمنية المحددة.', v_srv_rec.name;
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM public.booking_items bi
    JOIN public.bookings b ON b.id = bi.booking_id
    WHERE bi.service_id = v_srv_id
      AND b.event_date = p_event_date
      AND bi.item_status IN ('pending', 'accepted')
      AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
      AND (
        b.time_slot = 'full_day' OR 
        p_time_slot = 'full_day' OR 
        b.time_slot = p_time_slot
      );

    IF v_conflict_count > 0 THEN
      RAISE EXCEPTION 'تعذر الحجز: الخدمة (%) تم حجزها بالفعل من قِبل عميل آخر لنفس التاريخ والفترة.', v_srv_rec.name;
    END IF;

    v_total_amount := v_total_amount + v_srv_rec.price;
  END LOOP;

  -- 5. إدراج سجل الحجز الرئيسي بشكل ذري
  INSERT INTO public.bookings (
    customer_id,
    package_id,
    event_type,
    event_date,
    time_slot,
    event_location,
    guest_count,
    budget,
    total_amount,
    status,
    notes
  ) VALUES (
    v_customer_id,
    p_package_id,
    p_event_type,
    p_event_date,
    p_time_slot,
    p_event_location,
    p_guest_count,
    p_budget,
    v_total_amount,
    'pending',
    p_notes
  ) RETURNING id, booking_code INTO v_new_booking_id, v_new_booking_code;

  -- 6. إدراج عناصر الحجز بالسعر الرسمي لحظة الطلب
  FOREACH v_srv_id IN ARRAY v_sorted_ids
  LOOP
    SELECT s.price INTO v_srv_rec FROM public.services s WHERE s.id = v_srv_id;

    INSERT INTO public.booking_items (
      booking_id,
      service_id,
      quantity,
      unit_price,
      subtotal,
      item_status
    ) VALUES (
      v_new_booking_id,
      v_srv_id,
      1,
      v_srv_rec.price,
      v_srv_rec.price,
      'pending'
    );
  END LOOP;

  -- 7. تسجيل الحدث في سجل الحالات
  INSERT INTO public.booking_status_history (
    booking_id,
    old_status,
    new_status,
    changed_by,
    note
  ) VALUES (
    v_new_booking_id,
    NULL,
    'pending',
    v_customer_id,
    'إنشاء طلب الحجز المبدئي وإرسال الإشعارات للعميل ومقدمي الخدمات'
  );

  -- 8. إنشاء إشعار فوري للعميل بتأكيد استلام الطلب بنجاح
  INSERT INTO public.notifications (
    user_id,
    title,
    body,
    type,
    related_booking_id
  ) VALUES (
    v_customer_id,
    'تم استلام طلب حجزك بنجاح',
    'طلبك رقم (' || v_new_booking_code || ') قيد المراجعة بانتظار موافقة مقدمي الخدمات.',
    'booking_created',
    v_new_booking_id
  );

  -- 9. إنشاء إشعار لكل مزود خدمة تم طلب خدمته
  INSERT INTO public.notifications (
    user_id,
    title,
    body,
    type,
    related_booking_id
  )
  SELECT DISTINCT
    pp.user_id,
    'طلب حجز جديد',
    'لديك طلب حجز جديد برقم (' || v_new_booking_code || ') لخدمة (' || s.name || ') لمناسبة ' || p_event_type || ' بتاريخ ' || to_char(p_event_date, 'YYYY-MM-DD') || '.',
    'new_booking_request',
    v_new_booking_id
  FROM public.services s
  JOIN public.provider_profiles pp ON pp.id = s.provider_id
  WHERE s.id = ANY(v_sorted_ids) AND pp.user_id IS NOT NULL;

  -- 10. إرجاع النتيجة بتنسيق JSONB
  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_new_booking_id,
    'booking_code', v_new_booking_code,
    'total_amount', v_total_amount,
    'event_date', p_event_date,
    'time_slot', p_time_slot,
    'items_count', array_length(v_sorted_ids, 1),
    'message', 'تم إرسال طلب الحجز بنجاح وهو قيد انتظار موافقة مقدمي الخدمات.'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_booking_atomic FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_booking_atomic TO authenticated;


-- 2. محفّز (Trigger) تلقائي لإرسال الإشعارات عند تغيير حالة الحجز (مثل الإلغاء)
CREATE OR REPLACE FUNCTION public.on_booking_status_change_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- في حالة إلغاء الحجز
  IF NEW.status = 'cancelled' THEN
    -- إشعار للعميل
    INSERT INTO public.notifications (user_id, title, body, type, related_booking_id)
    VALUES (
      NEW.customer_id,
      'تم إلغاء الحجز',
      'تم إلغاء حجزك رقم (' || NEW.booking_code || ').',
      'booking_cancelled',
      NEW.id
    );

    -- إشعار لكافة مزودي الخدمات المرتبطين بهذا الحجز
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

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.on_booking_status_change_notifications() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.on_booking_status_change_notifications() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_booking_status_notifications ON public.bookings;
CREATE TRIGGER trg_booking_status_notifications
AFTER UPDATE OF status ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.on_booking_status_change_notifications();
