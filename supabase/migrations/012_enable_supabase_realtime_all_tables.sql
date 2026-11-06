-- ========================================================
-- Migration: 012_enable_supabase_realtime_all_tables.sql
-- Description: Complete bidirectional Supabase Realtime publication setup
--              for Lamma (Customer App, Provider Dashboard & Admin Dashboard)
-- ========================================================

-- 1. Ensure supabase_realtime publication exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

-- 2. Add required tables to supabase_realtime publication safely and idempotently
DO $$
DECLARE
  tbl_name TEXT;
  target_tables TEXT[] := ARRAY[
    'categories',
    'services',
    'service_availability',
    'service_images',
    'bookings',
    'booking_items',
    'booking_status_history',
    'notifications',
    'favorites',
    'provider_profiles',
    'provider_applications',
    'reviews',
    'complaints',
    'profiles'
  ];
BEGIN
  FOREACH tbl_name IN ARRAY target_tables LOOP
    -- Check if table exists in public schema
    IF EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = tbl_name
    ) THEN
      -- Check if table is not already in supabase_realtime publication
      IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = tbl_name
      ) THEN
        EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;', tbl_name);
        RAISE NOTICE 'Added table % to supabase_realtime publication.', tbl_name;
      ELSE
        RAISE NOTICE 'Table % is already in supabase_realtime publication.', tbl_name;
      END IF;
    END IF;
  END LOOP;
END $$;

-- 3. Set REPLICA IDENTITY FULL on all Realtime tables
-- This ensures that UPDATE and DELETE events include full row data and old record values,
-- which is necessary for clients to extract record IDs, user_ids, and provider_ids on DELETE/UPDATE.
ALTER TABLE IF EXISTS public.categories REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.services REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.service_availability REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.service_images REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.bookings REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.booking_items REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.booking_status_history REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.notifications REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.favorites REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.provider_profiles REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.provider_applications REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.reviews REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.complaints REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.profiles REPLICA IDENTITY FULL;

-- 4. Verify RLS remains enabled on all tables (Strict Security Compliance)
ALTER TABLE IF EXISTS public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.booking_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.booking_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.provider_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;

-- 5. Documentation Comment
COMMENT ON PUBLICATION supabase_realtime IS 
  'Central publication for Lamma Realtime synchronization across Customer, Provider, and Admin platforms.';

