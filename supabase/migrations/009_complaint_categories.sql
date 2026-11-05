-- ========================================================
-- Migration: 009_complaint_categories.sql
-- Description: Dynamic Complaint Categories Table and Link to Complaints
-- ========================================================

-- 1. إنشاء جدول تصنيفات الشكاوى (complaint_categories)
CREATE TABLE IF NOT EXISTS public.complaint_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name_ar TEXT NOT NULL,
    name_en TEXT,
    icon TEXT,
    requires_booking BOOLEAN NOT NULL DEFAULT false,
    default_priority TEXT NOT NULL DEFAULT 'medium' CHECK (default_priority IN ('low', 'medium', 'high', 'urgent')),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. تفعيل مشغّل تحديث الوقت التلقائي
DROP TRIGGER IF EXISTS trg_complaint_categories_updated_at ON public.complaint_categories;
CREATE TRIGGER trg_complaint_categories_updated_at
BEFORE UPDATE ON public.complaint_categories
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3. إضافة حقل category_id إلى جدول complaints كـ Foreign Key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'complaints' 
          AND column_name = 'category_id'
    ) THEN
        ALTER TABLE public.complaints 
        ADD COLUMN category_id UUID REFERENCES public.complaint_categories(id) ON DELETE SET NULL;
    END IF;
END $$;

-- فهرس لتسريع استعلامات الربط والفلترة
CREATE INDEX IF NOT EXISTS idx_complaints_category_id ON public.complaints(category_id);

-- 4. تفعيل سياسات الأمان على مستوى الصف (RLS)
ALTER TABLE public.complaint_categories ENABLE ROW LEVEL SECURITY;

-- السماح لجميع المستخدمين (المسجلين والزوار) بقراءة التصنيفات المفعلة
DROP POLICY IF EXISTS "complaint_categories_select" ON public.complaint_categories;
CREATE POLICY "complaint_categories_select" ON public.complaint_categories
FOR SELECT TO public
USING (is_active = true OR public.is_admin());

-- السماح لمدير المنصة فقط بإضافة وتعديل وحذف التصنيفات
DROP POLICY IF EXISTS "complaint_categories_admin_all" ON public.complaint_categories;
CREATE POLICY "complaint_categories_admin_all" ON public.complaint_categories
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 5. إدخال التصنيفات الافتراضية الأولية (Seed Initial Categories)
INSERT INTO public.complaint_categories (code, name_ar, name_en, icon, requires_booking, default_priority, sort_order, is_active)
VALUES
    ('booking_issue', 'مشكلة في الحجز', 'Booking Issue', 'event_busy', true, 'high', 1, true),
    ('service_mismatch', 'عدم مطابقة مواصفات الخدمة', 'Service Not as Described', 'assignment_late', true, 'high', 2, true),
    ('payment_refund', 'مشكلة دفع أو استرجاع', 'Payment or Refund Issue', 'payments', false, 'urgent', 3, true),
    ('delay_or_conduct', 'تأخر أو سوء تعامل', 'Delay or Misconduct', 'hourglass_bottom', true, 'medium', 4, true),
    ('technical_issue', 'مشكلة تقنية بالتطبيق', 'Technical Issue', 'phonelink_erase', false, 'medium', 5, true),
    ('other', 'أخرى / استفسار عام', 'Other / General Inquiry', 'help_outline', false, 'low', 6, true)
ON CONFLICT (code) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    icon = EXCLUDED.icon,
    requires_booking = EXCLUDED.requires_booking,
    default_priority = EXCLUDED.default_priority,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active;
