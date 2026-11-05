-- ========================================================
-- Migration: 011_service_occasions_and_working_hours.sql
-- Description: Add occasions and working_hours columns to services table and populate with data
-- ========================================================

-- 1. إضافة عمود المناسبات المتاحة (occasions)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'services' 
          AND column_name = 'occasions'
    ) THEN
        ALTER TABLE public.services 
        ADD COLUMN occasions TEXT[] NOT NULL DEFAULT '{}';
    END IF;

    -- 2. إضافة عمود أوقات وساعات الدوام (working_hours) كـ JSONB
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'services' 
          AND column_name = 'working_hours'
    ) THEN
        ALTER TABLE public.services 
        ADD COLUMN working_hours JSONB NOT NULL DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- 3. تحديث الخدمات الموجودة ببيانات المناسبات وأوقات الدوام حسب نوع التصنيف

-- قاعات المناسبات والصالات
UPDATE public.services s
SET 
    occasions = ARRAY['زفاف', 'اجتماع عائلي', 'حفلة تخرج', 'عقد قران', 'مؤتمرات وفعاليات'],
    working_hours = '[
        {"day": "السبت", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأحد", "status": "متاح", "time": "24 ساعة"},
        {"day": "الإثنين", "status": "متاح", "time": "24 ساعة"},
        {"day": "الثلاثاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأربعاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الخميس", "status": "متاح", "time": "24 ساعة"},
        {"day": "الجمعة", "status": "متاح", "time": "24 ساعة"}
    ]'::jsonb
FROM public.categories c
WHERE s.category_id = c.id 
  AND (c.name ILIKE '%قاع%' OR c.name ILIKE '%صال%');

-- استراحات وشاليهات
UPDATE public.services s
SET 
    occasions = ARRAY['اجتماع عائلي', 'حفلات شواء', 'إجازات وعطلات', 'مناسبات خاصة'],
    working_hours = '[
        {"day": "السبت", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأحد", "status": "متاح", "time": "24 ساعة"},
        {"day": "الإثنين", "status": "متاح", "time": "24 ساعة"},
        {"day": "الثلاثاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأربعاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الخميس", "status": "متاح", "time": "24 ساعة"},
        {"day": "الجمعة", "status": "متاح", "time": "24 ساعة"}
    ]'::jsonb
FROM public.categories c
WHERE s.category_id = c.id 
  AND (c.name ILIKE '%استراح%' OR c.name ILIKE '%شاليه%');

-- تصوير ومونتاج
UPDATE public.services s
SET 
    occasions = ARRAY['حفلات زفاف', 'جلسات تصوير خاصة', 'توثيق مؤتمرات', 'تخرج'],
    working_hours = '[
        {"day": "السبت", "status": "متاح", "time": "9:00 ص - 11:00 م"},
        {"day": "الأحد", "status": "متاح", "time": "9:00 ص - 11:00 م"},
        {"day": "الإثنين", "status": "متاح", "time": "9:00 ص - 11:00 م"},
        {"day": "الثلاثاء", "status": "متاح", "time": "9:00 ص - 11:00 م"},
        {"day": "الأربعاء", "status": "متاح", "time": "9:00 ص - 11:00 م"},
        {"day": "الخميس", "status": "متاح", "time": "9:00 ص - 12:00 ص"},
        {"day": "الجمعة", "status": "متاح", "time": "2:00 م - 12:00 ص"}
    ]'::jsonb
FROM public.categories c
WHERE s.category_id = c.id 
  AND (c.name ILIKE '%تصوير%' OR c.name ILIKE '%مونتاج%');

-- الكيك والحلويات
UPDATE public.services s
SET 
    occasions = ARRAY['أعراس ومناسبات', 'أعياد ميلاد', 'ضيافة مؤتمرات', 'حفلات تخرج'],
    working_hours = '[
        {"day": "السبت", "status": "متاح", "time": "8:00 ص - 10:00 م"},
        {"day": "الأحد", "status": "متاح", "time": "8:00 ص - 10:00 م"},
        {"day": "الإثنين", "status": "متاح", "time": "8:00 ص - 10:00 م"},
        {"day": "الثلاثاء", "status": "متاح", "time": "8:00 ص - 10:00 م"},
        {"day": "الأربعاء", "status": "متاح", "time": "8:00 ص - 10:00 م"},
        {"day": "الخميس", "status": "متاح", "time": "8:00 ص - 11:00 م"},
        {"day": "الجمعة", "status": "متاح", "time": "1:00 م - 11:00 م"}
    ]'::jsonb
FROM public.categories c
WHERE s.category_id = c.id 
  AND (c.name ILIKE '%كيك%' OR c.name ILIKE '%حلو%');

-- تنسيق ديكور الحفلات والزهور
UPDATE public.services s
SET 
    occasions = ARRAY['كوش أفراح', 'تنسيق قاعات', 'مداخل واستقبال', 'مسكات عروس'],
    working_hours = '[
        {"day": "السبت", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأحد", "status": "متاح", "time": "24 ساعة"},
        {"day": "الإثنين", "status": "متاح", "time": "24 ساعة"},
        {"day": "الثلاثاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الأربعاء", "status": "متاح", "time": "24 ساعة"},
        {"day": "الخميس", "status": "متاح", "time": "24 ساعة"},
        {"day": "الجمعة", "status": "متاح", "time": "24 ساعة"}
    ]'::jsonb
FROM public.categories c
WHERE s.category_id = c.id 
  AND (c.name ILIKE '%ديكور%' OR c.name ILIKE '%زهر%' OR c.name ILIKE '%ورد%');

