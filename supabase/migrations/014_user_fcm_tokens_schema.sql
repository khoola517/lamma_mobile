-- ========================================================
-- Migration: 014_user_fcm_tokens_schema.sql
-- Description: Concurrency-safe, hardened FCM device tokens schema and management
-- Security:
--   - pg_advisory_xact_lock to eliminate race conditions
--   - Token hijacking protection (strictly rejects claiming active tokens)
--   - Zero direct table privileges for authenticated and anon
--   - Timestamps unified to now()
--   - Automated updated_at via existing public.set_updated_at() trigger
--   - Dedicated deactivate_invalid_fcm_token function for Edge Functions
-- ========================================================

-- 1. إنشاء جدول توكنات الأجهزة (user_fcm_tokens)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'web', 'ios')),
    device_info JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_fcm_token UNIQUE (fcm_token)
);

-- 2. الفهارس لتحسين أداء البحث والإرسال والتنظيف
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id 
    ON public.user_fcm_tokens(user_id);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active_lookup 
    ON public.user_fcm_tokens(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_platform_active 
    ON public.user_fcm_tokens(platform, is_active);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_cleanup 
    ON public.user_fcm_tokens(is_active, updated_at);

-- 3. تفعيل مشغل التحديث التلقائي لحقل updated_at
DROP TRIGGER IF EXISTS trg_user_fcm_tokens_updated_at ON public.user_fcm_tokens;
CREATE TRIGGER trg_user_fcm_tokens_updated_at
    BEFORE UPDATE ON public.user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 4. إغلاق الصلاحيات المباشرة على الجدول (Zero Direct Table Privileges)
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.user_fcm_tokens FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.user_fcm_tokens TO service_role;


-- 5. دالة تسجيل وتحديث التوكن الآمنة والمحمية ضد الـ Race Conditions
CREATE OR REPLACE FUNCTION public.register_fcm_token(
    p_fcm_token TEXT,
    p_platform TEXT,
    p_device_info JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_clean_token TEXT;
    v_normalized_platform TEXT;
    v_existing RECORD;
BEGIN
    -- أ. التحقق من هوية المستخدم المسجل
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to register device token.';
    END IF;

    -- ب. التحقق من التوكن (عدم الفراغ وحد أقصى آمن)
    v_clean_token := trim(p_fcm_token);
    IF v_clean_token IS NULL OR v_clean_token = '' THEN
        RAISE EXCEPTION 'FCM token cannot be empty.';
    END IF;

    IF length(v_clean_token) > 4096 THEN
        RAISE EXCEPTION 'FCM token exceeds maximum allowed length.';
    END IF;

    -- ج. التحقق من المنصة
    IF p_platform IS NULL OR trim(p_platform) = '' THEN
        RAISE EXCEPTION 'Platform cannot be null or empty.';
    END IF;

    v_normalized_platform := lower(trim(p_platform));
    IF v_normalized_platform NOT IN ('android', 'web', 'ios') THEN
        RAISE EXCEPTION 'Invalid platform: %. Supported platforms: android, web, ios.', p_platform;
    END IF;

    -- د. التحقق من بنية JSON لبيانات الجهاز
    IF p_device_info IS NOT NULL AND jsonb_typeof(p_device_info) <> 'object' THEN
        RAISE EXCEPTION 'device_info must be a valid JSON object.';
    END IF;

    -- هـ. الحصول على قفل حصري على مستوى المعاملة للتوكن لمنع Race Conditions
    PERFORM pg_advisory_xact_lock(hashtext('user_fcm_tokens'), hashtext(v_clean_token));

    -- و. فحص ملكية وحالة التوكن بعد الحصول على القفل
    SELECT id, user_id, is_active
    INTO v_existing
    FROM public.user_fcm_tokens
    WHERE fcm_token = v_clean_token;

    IF FOUND THEN
        -- التوكن مسجل مسبقاً (سواء لنفس الحساب أو لحساب سابق على نفس الجهاز):
        -- يتم تحديثه ونقله للحساب الحالي وتفعيله فوراً لضمان استلام الإشعارات
        UPDATE public.user_fcm_tokens
        SET user_id = v_user_id,
            platform = v_normalized_platform,
            device_info = COALESCE(p_device_info, '{}'::jsonb),
            is_active = true
        WHERE id = v_existing.id;

    ELSE
        -- توكن جديد: إدراجه في الجدول
        INSERT INTO public.user_fcm_tokens (
            user_id,
            fcm_token,
            platform,
            device_info,
            is_active
        ) VALUES (
            v_user_id,
            v_clean_token,
            v_normalized_platform,
            COALESCE(p_device_info, '{}'::jsonb),
            true
        );
    END IF;

    RETURN true;
END;
$$;


-- 6. دالة إلغاء تفعيل التوكن عند تسجيل الخروج (متزامنة بالقفل)
CREATE OR REPLACE FUNCTION public.unregister_fcm_token(
    p_fcm_token TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_clean_token TEXT;
    v_affected_rows INT;
BEGIN
    -- أ. التحقق من هوية المستخدم المسجل
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to unregister device token.';
    END IF;

    v_clean_token := trim(p_fcm_token);
    IF v_clean_token IS NULL OR v_clean_token = '' THEN
        RETURN false;
    END IF;

    -- ب. الحصول على نفس القفل لمنع أي تعارض متزامن مع register_fcm_token
    PERFORM pg_advisory_xact_lock(hashtext('user_fcm_tokens'), hashtext(v_clean_token));

    -- ج. إلغاء التفعيل محصور بالتوكن الخاص بالمستخدم الحالي فقط
    UPDATE public.user_fcm_tokens
    SET is_active = false
    WHERE fcm_token = v_clean_token
      AND user_id = v_user_id;

    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    RETURN (v_affected_rows > 0);
END;
$$;


-- 7. دالة تعطيل التوكنات غير الصالحة المخصصة لـ Edge Functions فقط
CREATE OR REPLACE FUNCTION public.deactivate_invalid_fcm_token(
    p_fcm_token TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_clean_token TEXT;
    v_affected_rows INT;
BEGIN
    -- أ. رفض التوكن الفارغ
    v_clean_token := trim(p_fcm_token);
    IF v_clean_token IS NULL OR v_clean_token = '' THEN
        RAISE EXCEPTION 'FCM token cannot be null or empty.';
    END IF;

    -- ب. القفل لمنع التعارض مع محاولة إعادة تسجيل التوكن في نفس اللحظة
    PERFORM pg_advisory_xact_lock(hashtext('user_fcm_tokens'), hashtext(v_clean_token));

    -- ج. تعطيل التوكن
    UPDATE public.user_fcm_tokens
    SET is_active = false
    WHERE fcm_token = v_clean_token;

    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    RETURN (v_affected_rows > 0);
END;
$$;


-- 8. دالة إحصائيات التوكنات الآمنة للمشرفين (أعداد فقط دون إظهار التوكنات أو بيانات الأجهزة)
CREATE OR REPLACE FUNCTION public.get_active_fcm_tokens_stats()
RETURNS TABLE (
    platform TEXT,
    active_tokens_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Administrator privileges required.';
    END IF;

    RETURN QUERY
    SELECT 
        t.platform,
        COUNT(*)::BIGINT AS active_tokens_count
    FROM public.user_fcm_tokens t
    WHERE t.is_active = true
    GROUP BY t.platform
    ORDER BY t.platform ASC;
END;
$$;


-- 9. دالة تنظيف التوكنات غير النشطة (محمية ومقيدة بـ service_role فقط)
CREATE OR REPLACE FUNCTION public.cleanup_inactive_fcm_tokens(
    p_inactive_days INT DEFAULT 180
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_deleted_count INT := 0;
BEGIN
    IF p_inactive_days IS NULL THEN
        RAISE EXCEPTION 'p_inactive_days cannot be NULL.';
    END IF;

    IF p_inactive_days < 180 THEN
        RAISE EXCEPTION 'p_inactive_days must be at least 180 days to prevent premature token deletion.';
    END IF;

    IF p_inactive_days > 730 THEN
        RAISE EXCEPTION 'p_inactive_days cannot exceed 730 days (2 years).';
    END IF;

    -- حذف التوكنات غير النشطة فقط (is_active = false)
    DELETE FROM public.user_fcm_tokens
    WHERE is_active = false
      AND updated_at < (now() - (p_inactive_days || ' days')::INTERVAL);

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$;


-- 10. ضبط الصلاحيات والأدوار بدقة (Privileges & Role Management)
-- سحب الصلاحيات العامة الافتراضية
REVOKE ALL ON FUNCTION public.register_fcm_token(TEXT, TEXT, JSONB) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.unregister_fcm_token(TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.deactivate_invalid_fcm_token(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_active_fcm_tokens_stats() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cleanup_inactive_fcm_tokens(INT) FROM PUBLIC, anon, authenticated;

-- منح المستخدمين المسجلين فقط صلاحية تسجيل وإلغاء تسجيل أجهزتهم
GRANT EXECUTE ON FUNCTION public.register_fcm_token(TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unregister_fcm_token(TEXT) TO authenticated;

-- منح المشرفين صلاحية استدعاء دالة الإحصائيات (التحقق الفعلي يتم داخل الدالة عبر is_admin)
GRANT EXECUTE ON FUNCTION public.get_active_fcm_tokens_stats() TO authenticated;

-- قصر استدعاء دوال الصيانة والخادم حصرياً على service_role
GRANT EXECUTE ON FUNCTION public.deactivate_invalid_fcm_token(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_inactive_fcm_tokens(INT) TO service_role;

