-- =========================================================================
-- Migration 015: قصر التقييمات حصرياً على العملاء الذين قاموا بحجز الخدمة
-- Khadematy App - Verified Reviews Security Policy
-- =========================================================================

-- 1. دالة أمنية للتحقق من أن العميل لديه حجز فعلي غير ملغي لهذه الخدمة
CREATE OR REPLACE FUNCTION public.user_has_booked_service(p_customer_id UUID, p_service_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.bookings b
        JOIN public.booking_items bi ON bi.booking_id = b.id
        WHERE b.customer_id = p_customer_id
          AND bi.service_id = p_service_id
          AND b.status != 'cancelled'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. تحديث سياسة الإدراج لجدول التقييمات reviews
-- السماح بالإدراج فقط للعميل المصادق عليه والذي يمتلك حجزاً فعلياً للخدمة
DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT TO authenticated
WITH CHECK (
    customer_id = auth.uid() 
    AND public.user_has_booked_service(auth.uid(), service_id)
);

-- 3. السماح بتحديث تقييم المستخدم الخاص به فقط
DROP POLICY IF EXISTS "reviews_update" ON public.reviews;
CREATE POLICY "reviews_update" ON public.reviews FOR UPDATE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin())
WITH CHECK (customer_id = auth.uid() OR public.is_admin());

