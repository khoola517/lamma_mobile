-- ========================================================
-- Migration: 004_smart_planning_rpc.sql
-- Description: AI Smart Planning RPC function generating 3 package tiers
-- (Read-Only Preview without DB persistence, and atomic save_selected_package on user selection)
-- ========================================================

-- 1. دالة توليد الباقات الذكية الثلاث (دون حفظ أي بيانات في قاعدة البيانات - Read-Only)
CREATE OR REPLACE FUNCTION public.generate_smart_package(
  p_customer_id UUID,
  p_event_type TEXT,
  p_budget NUMERIC,
  p_guest_count INTEGER,
  p_category_ids UUID[],
  p_event_date DATE,
  p_time_slot TEXT DEFAULT 'evening'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cat_id UUID;
  v_missing_cats TEXT[] := '{}';
  v_min_total NUMERIC := 0;
  v_cheapest_service NUMERIC;
  v_eco_services JSONB := '[]'::jsonb;
  v_bal_services JSONB := '[]'::jsonb;
  v_vip_services JSONB := '[]'::jsonb;
  v_eco_total NUMERIC := 0;
  v_bal_total NUMERIC := 0;
  v_vip_total NUMERIC := 0;
  v_srv RECORD;
  v_cat_budget NUMERIC;
  v_weight NUMERIC;
  v_currency TEXT := 'YER';
  v_packages JSONB;
BEGIN
  -- 1. التحقق من المدخلات الأساسية
  IF p_budget <= 0 OR p_guest_count <= 0 OR array_length(p_category_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'INVALID_INPUT',
      'message', 'يرجى التأكد من إدخال ميزانية صالحة وعدد حضور واختيار التصنيفات المطلوبة.'
    );
  END IF;

  -- 2. التحقق من توفر خدمات لكل تصنيف وحساب الحد الأدنى الفعلي للميزانية
  FOREACH v_cat_id IN ARRAY p_category_ids
  LOOP
    SELECT s.price INTO v_cheapest_service
    FROM public.services s
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE s.category_id = v_cat_id
      AND s.status = 'active'
      AND pp.status = 'approved'
      AND (s.capacity IS NULL OR s.capacity >= p_guest_count)
      AND NOT EXISTS (
        SELECT 1 FROM public.service_availability sa
        WHERE sa.service_id = s.id 
          AND sa.available_date = p_event_date 
          AND sa.is_available = false
          AND (sa.time_slot = 'full_day' OR sa.time_slot = p_time_slot)
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_items bi
        JOIN public.bookings b ON b.id = bi.booking_id
        WHERE bi.service_id = s.id
          AND b.event_date = p_event_date
          AND bi.item_status IN ('pending', 'accepted')
          AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
          AND (b.time_slot = 'full_day' OR p_time_slot = 'full_day' OR b.time_slot = p_time_slot)
      )
    ORDER BY s.price ASC
    LIMIT 1;

    IF v_cheapest_service IS NULL THEN
      SELECT array_append(v_missing_cats, c.name) INTO v_missing_cats
      FROM public.categories c WHERE c.id = v_cat_id;
    ELSE
      v_min_total := v_min_total + v_cheapest_service;
    END IF;
  END LOOP;

  -- فحص عدم توفر أي تصنيف في ذلك التاريخ
  IF array_length(v_missing_cats, 1) > 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SERVICES_UNAVAILABLE',
      'unavailable_categories', v_missing_cats,
      'message', 'تعذر توفير خدمات متاحة في التاريخ المطلوب لبعض التصنيفات المحددة.'
    );
  END IF;

  -- فحص كفاية الميزانية
  IF p_budget < v_min_total THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'INSUFFICIENT_BUDGET',
      'min_required_budget', v_min_total,
      'currency', v_currency,
      'message', 'الميزانية المدخلة أقل من الحد الأدنى لتغطية الخدمات المطلوبة (' || v_min_total || ' ' || v_currency || ').'
    );
  END IF;

  -- 3. اختيار وحساب عناصر كل باقة في الذاكرة (دون إدراج أي سجل في جدول packages أو package_items)
  FOREACH v_cat_id IN ARRAY p_category_ids
  LOOP
    v_weight := 1.0 / array_length(p_category_ids, 1);
    v_cat_budget := p_budget * v_weight;

    -- أ. الخدمة الاقتصادية (الأقل سعراً من بين المتاحة)
    SELECT 
      s.id, 
      s.name, 
      s.price, 
      COALESCE(pp.business_name, 'مقدم خدمة معتمد') AS vendor,
      COALESCE(s.description, 'خدمة متكاملة للمناسبة') AS details,
      s.category_id,
      COALESCE(s.image_url, (SELECT si.image_url FROM public.service_images si WHERE si.service_id = s.id AND si.is_cover = true LIMIT 1)) AS image_url
    INTO v_srv
    FROM public.services s
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE s.category_id = v_cat_id 
      AND s.status = 'active' 
      AND pp.status = 'approved'
      AND (s.capacity IS NULL OR s.capacity >= p_guest_count)
      AND NOT EXISTS (
        SELECT 1 FROM public.service_availability sa
        WHERE sa.service_id = s.id 
          AND sa.available_date = p_event_date 
          AND sa.is_available = false
          AND (sa.time_slot = 'full_day' OR sa.time_slot = COALESCE(p_time_slot, 'evening'))
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_items bi
        JOIN public.bookings b ON b.id = bi.booking_id
        WHERE bi.service_id = s.id
          AND b.event_date = p_event_date
          AND bi.item_status IN ('pending', 'accepted')
          AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
          AND (b.time_slot = 'full_day' OR COALESCE(p_time_slot, 'evening') = 'full_day' OR b.time_slot = COALESCE(p_time_slot, 'evening'))
      )
    ORDER BY s.price ASC LIMIT 1;

    IF v_srv.id IS NOT NULL THEN
      v_eco_services := v_eco_services || jsonb_build_array(
        jsonb_build_object(
          'id', v_srv.id,
          'name', v_srv.name,
          'vendor', v_srv.vendor,
          'details', v_srv.details,
          'price', v_srv.price,
          'isIncluded', true,
          'imageUrl', v_srv.image_url,
          'categoryId', v_srv.category_id
        )
      );
      v_eco_total := v_eco_total + v_srv.price;
    END IF;

    -- ب. الخدمة المتوازنة (الأقرب لحصة التصنيف من الميزانية من بين المتاحة)
    SELECT 
      s.id, 
      s.name, 
      s.price, 
      COALESCE(pp.business_name, 'مقدم خدمة معتمد') AS vendor,
      COALESCE(s.description, 'خدمة متكاملة للمناسبة') AS details,
      s.category_id,
      COALESCE(s.image_url, (SELECT si.image_url FROM public.service_images si WHERE si.service_id = s.id AND si.is_cover = true LIMIT 1)) AS image_url
    INTO v_srv
    FROM public.services s
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE s.category_id = v_cat_id 
      AND s.status = 'active' 
      AND pp.status = 'approved'
      AND (s.capacity IS NULL OR s.capacity >= p_guest_count)
      AND NOT EXISTS (
        SELECT 1 FROM public.service_availability sa
        WHERE sa.service_id = s.id 
          AND sa.available_date = p_event_date 
          AND sa.is_available = false
          AND (sa.time_slot = 'full_day' OR sa.time_slot = COALESCE(p_time_slot, 'evening'))
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_items bi
        JOIN public.bookings b ON b.id = bi.booking_id
        WHERE bi.service_id = s.id
          AND b.event_date = p_event_date
          AND bi.item_status IN ('pending', 'accepted')
          AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
          AND (b.time_slot = 'full_day' OR COALESCE(p_time_slot, 'evening') = 'full_day' OR b.time_slot = COALESCE(p_time_slot, 'evening'))
      )
    ORDER BY abs(s.price - v_cat_budget) ASC LIMIT 1;

    IF v_srv.id IS NOT NULL THEN
      v_bal_services := v_bal_services || jsonb_build_array(
        jsonb_build_object(
          'id', v_srv.id,
          'name', v_srv.name,
          'vendor', v_srv.vendor,
          'details', v_srv.details,
          'price', v_srv.price,
          'isIncluded', true,
          'imageUrl', v_srv.image_url,
          'categoryId', v_srv.category_id
        )
      );
      v_bal_total := v_bal_total + v_srv.price;
    END IF;

    -- ج. الخدمة الفاخرة (الأعلى جودة وسعراً من بين المتاحة)
    SELECT 
      s.id, 
      s.name, 
      s.price, 
      COALESCE(pp.business_name, 'مقدم خدمة معتمد') AS vendor,
      COALESCE(s.description, 'خدمة متكاملة للمناسبة') AS details,
      s.category_id,
      COALESCE(s.image_url, (SELECT si.image_url FROM public.service_images si WHERE si.service_id = s.id AND si.is_cover = true LIMIT 1)) AS image_url
    INTO v_srv
    FROM public.services s
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE s.category_id = v_cat_id 
      AND s.status = 'active' 
      AND pp.status = 'approved'
      AND (s.capacity IS NULL OR s.capacity >= p_guest_count)
      AND NOT EXISTS (
        SELECT 1 FROM public.service_availability sa
        WHERE sa.service_id = s.id 
          AND sa.available_date = p_event_date 
          AND sa.is_available = false
          AND (sa.time_slot = 'full_day' OR sa.time_slot = COALESCE(p_time_slot, 'evening'))
      )
      AND NOT EXISTS (
        SELECT 1 FROM public.booking_items bi
        JOIN public.bookings b ON b.id = bi.booking_id
        WHERE bi.service_id = s.id
          AND b.event_date = p_event_date
          AND bi.item_status IN ('pending', 'accepted')
          AND b.status IN ('pending', 'partially_accepted', 'confirmed', 'in_progress', 'attention_needed')
          AND (b.time_slot = 'full_day' OR COALESCE(p_time_slot, 'evening') = 'full_day' OR b.time_slot = COALESCE(p_time_slot, 'evening'))
      )
    ORDER BY s.price DESC LIMIT 1;

    IF v_srv.id IS NOT NULL THEN
      v_vip_services := v_vip_services || jsonb_build_array(
        jsonb_build_object(
          'id', v_srv.id,
          'name', v_srv.name,
          'vendor', v_srv.vendor,
          'details', v_srv.details,
          'price', v_srv.price,
          'isIncluded', true,
          'imageUrl', v_srv.image_url,
          'categoryId', v_srv.category_id
        )
      );
      v_vip_total := v_vip_total + v_srv.price;
    END IF;
  END LOOP;

  -- 4. تكوين مصفوفة الباقات الثلاث مع تفاصيلها
  v_packages := jsonb_build_array(
    jsonb_build_object(
      'id', 'pkg_eco',
      'name', 'باقة اقتصادية',
      'price', v_eco_total,
      'servicesCount', jsonb_array_length(v_eco_services),
      'savingsText', 'باقة توفيرية ذكية',
      'isFeatured', false,
      'badge', NULL,
      'services', v_eco_services
    ),
    jsonb_build_object(
      'id', 'pkg_std',
      'name', 'باقة متوازنة (الأكثر طلباً)',
      'price', v_bal_total,
      'servicesCount', jsonb_array_length(v_bal_services),
      'savingsText', 'متوازنة وشاملة لاحتياجات المناسبة',
      'isFeatured', true,
      'badge', 'الأكثر اختياراً',
      'services', v_bal_services
    ),
    jsonb_build_object(
      'id', 'pkg_vip',
      'name', 'باقة فاخرة VIP',
      'price', v_vip_total,
      'servicesCount', jsonb_array_length(v_vip_services),
      'savingsText', 'أرقى الخيارات وأعلى مستويات الفخامة',
      'isFeatured', false,
      'badge', 'VIP',
      'services', v_vip_services
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'currency', v_currency,
    'packages', v_packages
  );
END;
$$;


-- 2. دالة حفظ الباقة المختارة مع تفاصيلها وخدماتها عند اختيار المستخدم لها
CREATE OR REPLACE FUNCTION public.save_selected_package(
  p_customer_id UUID DEFAULT NULL,
  p_package_id UUID DEFAULT NULL,
  p_name TEXT DEFAULT 'باقة مخصصة',
  p_event_type TEXT DEFAULT 'مناسبة عامة',
  p_budget NUMERIC DEFAULT 0,
  p_guest_count INTEGER DEFAULT 1,
  p_estimated_total NUMERIC DEFAULT 0,
  p_currency TEXT DEFAULT 'YER',
  p_services JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_customer_id UUID;
  v_saved_pkg_id UUID;
  v_item JSONB;
  v_srv_id UUID;
  v_srv_price NUMERIC;
  v_actual_total NUMERIC := 0;
BEGIN
  -- 1. التحقق من هوية المستخدم
  v_customer_id := COALESCE(p_customer_id, auth.uid());
  IF v_customer_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'UNAUTHORIZED',
      'message', 'يجب تسجيل الدخول لحفظ الباقة وتفاصيلها.'
    );
  END IF;

  -- 2. التحقق من وجود باقة سابقة للتحديث لمنع تراكم السجلات غير الضرورية
  IF p_package_id IS NOT NULL THEN
    SELECT id INTO v_saved_pkg_id
    FROM public.packages
    WHERE id = p_package_id AND customer_id = v_customer_id;
  END IF;

  IF v_saved_pkg_id IS NOT NULL THEN
    UPDATE public.packages
    SET name = p_name,
        event_type = p_event_type,
        budget = p_budget,
        guest_count = p_guest_count,
        estimated_total = p_estimated_total,
        currency = p_currency,
        status = 'selected',
        updated_at = now()
    WHERE id = v_saved_pkg_id;

    DELETE FROM public.package_items WHERE package_id = v_saved_pkg_id;
  ELSE
    INSERT INTO public.packages (
      customer_id,
      name,
      event_type,
      budget,
      guest_count,
      estimated_total,
      currency,
      status,
      generation_method
    ) VALUES (
      v_customer_id,
      p_name,
      p_event_type,
      p_budget,
      p_guest_count,
      p_estimated_total,
      p_currency,
      'selected',
      'automatic'
    ) RETURNING id INTO v_saved_pkg_id;
  END IF;

  -- 3. إدراج خدمات وتفاصيل الباقة المختارة
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_services)
  LOOP
    BEGIN
      v_srv_id := (v_item->>'id')::UUID;
    EXCEPTION WHEN OTHERS THEN
      v_srv_id := NULL;
    END;

    IF v_srv_id IS NOT NULL THEN
      SELECT price INTO v_srv_price FROM public.services WHERE id = v_srv_id;
      IF v_srv_price IS NULL THEN
        v_srv_price := COALESCE((v_item->>'price')::NUMERIC, 0);
      END IF;

      INSERT INTO public.package_items (
        package_id,
        service_id,
        quantity,
        unit_price,
        subtotal
      ) VALUES (
        v_saved_pkg_id,
        v_srv_id,
        1,
        v_srv_price,
        v_srv_price
      );

      v_actual_total := v_actual_total + v_srv_price;
    END IF;
  END LOOP;

  IF v_actual_total > 0 THEN
    UPDATE public.packages SET estimated_total = v_actual_total WHERE id = v_saved_pkg_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'package_id', v_saved_pkg_id,
    'estimated_total', COALESCE(NULLIF(v_actual_total, 0), p_estimated_total),
    'message', 'تم حفظ الباقة المختارة وتفاصيلها بنجاح.'
  );
END;
$$;
