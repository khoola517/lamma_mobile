-- ========================================================
-- Migration: 010_service_ratings_and_reviews_count.sql
-- Description: Add rating & reviews_count columns to services table with automatic sync trigger from reviews
-- ========================================================

-- 1. إضافة حقلي التقييم وعدد التقييمات إلى جدول الخدمات
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'services' 
          AND column_name = 'rating'
    ) THEN
        ALTER TABLE public.services 
        ADD COLUMN rating NUMERIC(3,1) NOT NULL DEFAULT 0.0 CHECK (rating >= 0.0 AND rating <= 5.0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'services' 
          AND column_name = 'reviews_count'
    ) THEN
        ALTER TABLE public.services 
        ADD COLUMN reviews_count INTEGER NOT NULL DEFAULT 0 CHECK (reviews_count >= 0);
    END IF;
END $$;

-- إنشاء فهرس لتسريع الترتيب والفلترة حسب الأعلى تقييماً والأكثر طلباً
CREATE INDEX IF NOT EXISTS idx_services_rating_reviews 
ON public.services(rating DESC, reviews_count DESC);

-- 2. تحديث أولي للخدمات الحالية بناءً على بيانات التقييمات الموجودة
UPDATE public.services s
SET 
    rating = COALESCE((
        SELECT ROUND(AVG(r.rating)::numeric, 1)
        FROM public.reviews r
        WHERE r.service_id = s.id
    ), 0.0),
    reviews_count = COALESCE((
        SELECT COUNT(*)::integer
        FROM public.reviews r
        WHERE r.service_id = s.id
    ), 0);

-- 3. دالة حساب وتحديث متوسط التقييم وعدد المراجعات للخدمة
CREATE OR REPLACE FUNCTION public.sync_service_rating_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_target_service_id UUID;
BEGIN
    -- تحديد معرف الخدمة المتأثرة حسب نوع العملية
    IF TG_OP = 'DELETE' THEN
        v_target_service_id := OLD.service_id;
    ELSE
        v_target_service_id := NEW.service_id;
    END IF;

    -- تحديث الخدمة المستهدفة
    IF v_target_service_id IS NOT NULL THEN
        UPDATE public.services
        SET 
            rating = COALESCE((
                SELECT ROUND(AVG(rating)::numeric, 1)
                FROM public.reviews
                WHERE service_id = v_target_service_id
            ), 0.0),
            reviews_count = COALESCE((
                SELECT COUNT(*)::integer
                FROM public.reviews
                WHERE service_id = v_target_service_id
            ), 0),
            updated_at = now()
        WHERE id = v_target_service_id;
    END IF;

    -- في حال تعديل التقييم ونقله لخدمة أخرى (حالة نادرة)، نحدث الخدمة السابقة أيضاً
    IF TG_OP = 'UPDATE' AND OLD.service_id IS DISTINCT FROM NEW.service_id THEN
        IF OLD.service_id IS NOT NULL THEN
            UPDATE public.services
            SET 
                rating = COALESCE((
                    SELECT ROUND(AVG(rating)::numeric, 1)
                    FROM public.reviews
                    WHERE service_id = OLD.service_id
                ), 0.0),
                reviews_count = COALESCE((
                    SELECT COUNT(*)::integer
                    FROM public.reviews
                    WHERE service_id = OLD.service_id
                ), 0),
                updated_at = now()
            WHERE id = OLD.service_id;
        END IF;
    END IF;

    RETURN NULL;
END;
$$;

-- 4. ربط المشغّل بجدول reviews ليعمل تلقائياً عند الإضافة أو التعديل أو الحذف
DROP TRIGGER IF EXISTS trg_sync_service_rating_stats ON public.reviews;
CREATE TRIGGER trg_sync_service_rating_stats
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.sync_service_rating_stats();

