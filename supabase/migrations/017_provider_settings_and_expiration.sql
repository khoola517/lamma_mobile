-- ==============================================================================
-- Migration: 017_provider_settings_and_expiration.sql
-- Description: 
-- 1. Adds 'settings' JSONB column to public.provider_profiles
-- 2. Creates RPC 'update_provider_settings' for easy authenticated settings management
-- 3. Creates automated function 'check_and_flag_expired_bookings' to identify
--    pending bookings that have exceeded the provider's response deadline (default 24h)
-- ==============================================================================

-- 1. إضافة عمود الإعدادات لملف مزود الخدمة
ALTER TABLE public.provider_profiles
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{
  "new_order_notifications": true,
  "order_updates_notifications": true,
  "sound_alerts": true,
  "weekly_digest": false,
  "default_response_hours": 24
}'::jsonb;

-- تحديث أي سجلات سابقة خالية من الإعدادات
UPDATE public.provider_profiles
SET settings = '{
  "new_order_notifications": true,
  "order_updates_notifications": true,
  "sound_alerts": true,
  "weekly_digest": false,
  "default_response_hours": 24
}'::jsonb
WHERE settings IS NULL;

-- 2. دالة آمنة ومريحة لتحديث إعدادات المزود
CREATE OR REPLACE FUNCTION public.update_provider_settings(p_settings JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_updated_settings JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE public.provider_profiles
    SET 
        settings = COALESCE(settings, '{}'::jsonb) || p_settings,
        updated_at = now()
    WHERE user_id = v_user_id
    RETURNING settings INTO v_updated_settings;

    RETURN v_updated_settings;
END;
$$;

-- منح صلاحيات التنفيذ للمستخدمين المسجلين
GRANT EXECUTE ON FUNCTION public.update_provider_settings(JSONB) TO authenticated;

-- 3. دالة فحص وتنبيه الحجوزات المنتهية مهلتها
CREATE OR REPLACE FUNCTION public.check_and_flag_expired_bookings()
RETURNS TABLE (
    booking_id UUID,
    booking_code TEXT,
    hours_elapsed NUMERIC,
    deadline_hours INT,
    provider_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id AS booking_id,
        b.booking_code,
        ROUND(EXTRACT(EPOCH FROM (now() - b.created_at)) / 3600.0, 1) AS hours_elapsed,
        COALESCE((pp.settings->>'default_response_hours')::INT, 24) AS deadline_hours,
        pp.id AS provider_id
    FROM public.bookings b
    JOIN public.booking_items bi ON bi.booking_id = b.id
    JOIN public.services s ON s.id = bi.service_id
    JOIN public.provider_profiles pp ON pp.id = s.provider_id
    WHERE b.status = 'pending'
      AND b.created_at < (now() - (COALESCE((pp.settings->>'default_response_hours')::INT, 24) || ' hours')::INTERVAL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_and_flag_expired_bookings() TO authenticated;

