-- ========================================================
-- Migration: 003_triggers_and_automation.sql
-- Description: Business rules, data protection triggers, and automation
-- ========================================================

-- 1. مشغلات تحديث updated_at التلقائية
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_provider_profiles_updated_at ON public.provider_profiles;
CREATE TRIGGER trg_provider_profiles_updated_at BEFORE UPDATE ON public.provider_profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_provider_applications_updated_at ON public.provider_applications;
CREATE TRIGGER trg_provider_applications_updated_at BEFORE UPDATE ON public.provider_applications
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_categories_updated_at ON public.categories;
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_services_updated_at ON public.services;
CREATE TRIGGER trg_services_updated_at BEFORE UPDATE ON public.services
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_packages_updated_at ON public.packages;
CREATE TRIGGER trg_packages_updated_at BEFORE UPDATE ON public.packages
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_reviews_updated_at ON public.reviews;
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_complaints_updated_at ON public.complaints;
CREATE TRIGGER trg_complaints_updated_at BEFORE UPDATE ON public.complaints
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 2. إنشاء بروفايل المستخدم الجديد بأمان عند التسجيل في Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    full_name,
    email,
    phone,
    avatar_url,
    role,
    is_active
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1), 'عميل خِدمتي'),
    COALESCE(NEW.email, ''),
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'avatar_url',
    'customer', -- إجبار الدور على عميل وتجاهل أي قيمة مرسلة من العميل
    true
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. حماية دور الحساب من الترقية الذاتية (Role Escalation Protection)
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'غير مصرح: لا تملك صلاحية تعديل دور الحساب.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.protect_profile_role();

-- 4. توليد كود الحجز التلقائي الفريد (KH-YY-XXXXX)
CREATE OR REPLACE FUNCTION public.set_booking_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.booking_code IS NULL OR NEW.booking_code = '' THEN
    NEW.booking_code := 'KH-' || to_char(CURRENT_DATE, 'YY') || '-' || nextval('public.booking_code_seq')::text;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_booking_code ON public.bookings;
CREATE TRIGGER trg_set_booking_code
BEFORE INSERT ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.set_booking_code();

-- 5. حماية تحديث الحجز وقواعد انتقال الحالات (Booking State Machine)
CREATE OR REPLACE FUNCTION public.validate_booking_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_total_items INTEGER;
  v_accepted_items INTEGER;
  v_rejected_items INTEGER;
  v_expected_status TEXT;
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- منع تعديل الحقول الحساسة الثابتة
  IF NEW.customer_id <> OLD.customer_id OR
     NEW.booking_code <> OLD.booking_code OR
     NEW.total_amount <> OLD.total_amount OR
     NEW.package_id IS DISTINCT FROM OLD.package_id THEN
    RAISE EXCEPTION 'غير مصرح: لا يمكن تعديل المعرفات الأساسية أو إجمالي المبلغ.';
  END IF;

  -- تقييد تغيير التاريخ أو الفترة
  IF (NEW.event_date <> OLD.event_date OR NEW.time_slot <> OLD.time_slot) THEN
    IF OLD.status NOT IN ('pending', 'attention_needed') THEN
      RAISE EXCEPTION 'لا يمكن تعديل موعد الحجز بعد تأكيده أو بدء تنفيذه.';
    END IF;
  END IF;

  -- تدقيق انتقال الحالات وفق قواعد الأمان
  IF NEW.status <> OLD.status THEN
    -- أ. إذا كان العميل هو من يطلب التعديل مباشرة
    IF auth.uid() = OLD.customer_id THEN
      IF NEW.status = 'cancelled' THEN
        IF OLD.status IN ('completed', 'cancelled') THEN
          RAISE EXCEPTION 'لا يمكن إلغاء حجز مكتمل أو ملغي مسبقاً.';
        END IF;
      ELSE
        RAISE EXCEPTION 'غير مصرح للعميل بتغيير حالة الحجز إلى % مباشرة؛ مسموح له بالإلغاء فقط.', NEW.status;
      END IF;

    -- ب. إذا كانت الحالة ناتجة عن مزامنة ردود مقدمي الخدمات على العناصر
    ELSIF NEW.status IN ('confirmed', 'partially_accepted', 'attention_needed') THEN
      SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE item_status = 'accepted'),
        COUNT(*) FILTER (WHERE item_status = 'rejected')
      INTO v_total_items, v_accepted_items, v_rejected_items
      FROM public.booking_items
      WHERE booking_id = NEW.id;

      IF v_rejected_items > 0 THEN
        v_expected_status := 'attention_needed';
      ELSIF v_total_items > 0 AND v_accepted_items = v_total_items THEN
        v_expected_status := 'confirmed';
      ELSIF v_accepted_items > 0 THEN
        v_expected_status := 'partially_accepted';
      ELSE
        v_expected_status := 'pending';
      END IF;

      IF NEW.status <> v_expected_status THEN
        RAISE EXCEPTION 'غير مصرح: حالة الحجز المطلوبة (%) لا تتطابق مع الحالة الفعلية لخدمات الحجز (المتوقع: %).', NEW.status, v_expected_status;
      END IF;

    ELSE
      -- الحالات التشغيلية الأخرى (in_progress, completed) مقتصرة حصراً على إدارة المنصة
      RAISE EXCEPTION 'غير مصرح: تغيير حالة الحجز إلى % يتطلب صلاحيات إدارة.', NEW.status;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_booking_update ON public.bookings;
CREATE TRIGGER trg_validate_booking_update
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.validate_booking_update();

-- 6. منع الحجز المزدوج المتزامن (Concurrency-Safe Double Booking Guard)
CREATE OR REPLACE FUNCTION public.check_booking_slot_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_booking_date DATE;
  v_time_slot TEXT;
  v_booking_status TEXT;
  v_conflict_count INTEGER;
  v_service_active BOOLEAN;
BEGIN
  -- قفل سجل الخدمة لمنع السباق المتزامن
  PERFORM 1 FROM public.services WHERE id = NEW.service_id FOR UPDATE;

  SELECT event_date, time_slot, status 
  INTO v_booking_date, v_time_slot, v_booking_status
  FROM public.bookings
  WHERE id = NEW.booking_id;

  IF v_booking_status = 'cancelled' OR NEW.item_status = 'rejected' THEN
    RETURN NEW;
  END IF;

  -- فحص التوفر اليدوي
  SELECT is_available INTO v_service_active
  FROM public.service_availability
  WHERE service_id = NEW.service_id 
    AND available_date = v_booking_date
    AND (time_slot = 'full_day' OR time_slot = v_time_slot);

  IF v_service_active IS FALSE THEN
    RAISE EXCEPTION 'الخدمة غير متاحة للتاريخ أو الفترة الزمنية المحددة من قِبل المزود.';
  END IF;

  -- فحص التعارض مع الحجوزات النشطة الأخرى
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.booking_items bi
  JOIN public.bookings b ON b.id = bi.booking_id
  WHERE bi.service_id = NEW.service_id
    AND bi.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
    AND b.id <> NEW.booking_id
    AND b.event_date = v_booking_date
    AND bi.item_status IN ('pending', 'accepted')
    AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
    AND (
      b.time_slot = 'full_day' OR 
      v_time_slot = 'full_day' OR 
      b.time_slot = v_time_slot
    );

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'تعذر الحجز: الخدمة محجوزة بالفعل في التاريخ والفترة الزمنية المحددة.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_booking_slot_conflict ON public.booking_items;
CREATE TRIGGER trg_check_booking_slot_conflict
BEFORE INSERT OR UPDATE OF service_id, item_status ON public.booking_items
FOR EACH ROW EXECUTE FUNCTION public.check_booking_slot_conflict();

-- 7. تقييد تعديلات مقدم الخدمة على booking_items
CREATE OR REPLACE FUNCTION public.restrict_booking_item_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- فحص الحقول غير القابلة للتعديل من مقدم الخدمة
  IF NEW.id <> OLD.id OR
     NEW.booking_id <> OLD.booking_id OR
     NEW.service_id <> OLD.service_id OR
     NEW.quantity <> OLD.quantity OR
     NEW.unit_price <> OLD.unit_price OR
     NEW.subtotal <> OLD.subtotal OR
     NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'غير مصرح: يقتصر حق مقدم الخدمة على الرد بالقبول أو الرفض وتدوين السبب فقط.';
  END IF;

  IF OLD.item_status <> 'pending' AND NEW.item_status <> OLD.item_status THEN
    RAISE EXCEPTION 'لا يمكن إعادة تعديل حالة الخدمة بعد إرسال الرد مسبقاً.';
  END IF;

  NEW.responded_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restrict_booking_item_update ON public.booking_items;
CREATE TRIGGER trg_restrict_booking_item_update
BEFORE UPDATE ON public.booking_items
FOR EACH ROW EXECUTE FUNCTION public.restrict_booking_item_update();

-- 8. انعكاس حالة عناصر الحجز على الحجز الرئيسي والإشعارات
CREATE OR REPLACE FUNCTION public.on_booking_item_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_customer_id UUID;
  v_booking_status TEXT;
  v_total_items INTEGER;
  v_accepted_items INTEGER;
  v_rejected_items INTEGER;
  v_service_name TEXT;
BEGIN
  IF NEW.item_status = OLD.item_status THEN
    RETURN NEW;
  END IF;

  SELECT customer_id, status INTO v_customer_id, v_booking_status
  FROM public.bookings WHERE id = NEW.booking_id;

  SELECT name INTO v_service_name FROM public.services WHERE id = NEW.service_id;

  -- إحصاء حالات عناصر الحجز
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE item_status = 'accepted'),
    COUNT(*) FILTER (WHERE item_status = 'rejected')
  INTO v_total_items, v_accepted_items, v_rejected_items
  FROM public.booking_items
  WHERE booking_id = NEW.booking_id;

  -- تحديث حالة الحجز الرئيسي
  IF v_rejected_items > 0 THEN
    -- في حال رفض أي خدمة يحتاج الحجز إجراء من العميل
    UPDATE public.bookings SET status = 'attention_needed' WHERE id = NEW.booking_id;
    
    INSERT INTO public.notifications (user_id, title, body, type, related_booking_id)
    VALUES (
      v_customer_id,
      'تحديث بخصوص طلبك',
      'تعذر قبول خدمة (' || COALESCE(v_service_name, 'إحدى الخدمات') || ') للتاريخ المحدد، يرجى استبدالها أو الاستمرار بدونها.',
      'booking_update',
      NEW.booking_id
    );
  ELSIF v_accepted_items = v_total_items THEN
    -- عند قبول جميع الخدمات يصبح الحجز مؤكداً
    UPDATE public.bookings SET status = 'confirmed' WHERE id = NEW.booking_id;

    INSERT INTO public.notifications (user_id, title, body, type, related_booking_id)
    VALUES (
      v_customer_id,
      'تم تأكيد حجزك بالكامل!',
      'وافق جميع مقدمي الخدمات على طلبك وأصبح حجزك مؤكداً بنجاح.',
      'booking_confirmed',
      NEW.booking_id
    );
  ELSIF v_accepted_items > 0 THEN
    UPDATE public.bookings SET status = 'partially_accepted' WHERE id = NEW.booking_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_booking_item_status_change ON public.booking_items;
CREATE TRIGGER trg_on_booking_item_status_change
AFTER UPDATE OF item_status ON public.booking_items
FOR EACH ROW EXECUTE FUNCTION public.on_booking_item_status_change();

-- 9. أرشفة تغيرات حالة الحجز في booking_status_history
CREATE OR REPLACE FUNCTION public.log_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.booking_status_history (
      booking_id,
      old_status,
      new_status,
      changed_by,
      note
    )
    VALUES (
      NEW.id,
      OLD.status,
      NEW.status,
      auth.uid(),
      'تحديث تلقائي لحالة الحجز'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_booking_status_change ON public.bookings;
CREATE TRIGGER trg_log_booking_status_change
AFTER UPDATE OF status ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.log_booking_status_change();
