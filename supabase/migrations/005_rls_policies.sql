-- ========================================================
-- Migration: 005_rls_policies.sql
-- Description: Complete Row Level Security (RLS) policies for all 16 tables
-- ========================================================

-- تفعيل RLS على كافة الجداول الـ 16
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.package_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 1. جدول profiles
-- ==========================================
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT TO authenticated
USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE TO authenticated
USING (id = auth.uid() OR public.is_admin())
WITH CHECK (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "profiles_delete" ON public.profiles;
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 2. جدول provider_profiles
-- ==========================================
DROP POLICY IF EXISTS "provider_profiles_select" ON public.provider_profiles;
CREATE POLICY "provider_profiles_select" ON public.provider_profiles FOR SELECT TO authenticated
USING (status = 'approved' OR user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "provider_profiles_insert" ON public.provider_profiles;
CREATE POLICY "provider_profiles_insert" ON public.provider_profiles FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "provider_profiles_update" ON public.provider_profiles;
CREATE POLICY "provider_profiles_update" ON public.provider_profiles FOR UPDATE TO authenticated
USING (user_id = auth.uid() OR public.is_admin())
WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "provider_profiles_delete" ON public.provider_profiles;
CREATE POLICY "provider_profiles_delete" ON public.provider_profiles FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 3. جدول provider_applications
-- ==========================================
DROP POLICY IF EXISTS "applications_select" ON public.provider_applications;
CREATE POLICY "applications_select" ON public.provider_applications FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "applications_insert" ON public.provider_applications;
CREATE POLICY "applications_insert" ON public.provider_applications FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "applications_update" ON public.provider_applications;
CREATE POLICY "applications_update" ON public.provider_applications FOR UPDATE TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "applications_delete" ON public.provider_applications;
CREATE POLICY "applications_delete" ON public.provider_applications FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 4. جدول categories
-- ==========================================
DROP POLICY IF EXISTS "categories_select" ON public.categories;
CREATE POLICY "categories_select" ON public.categories FOR SELECT TO authenticated
USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "categories_admin_all" ON public.categories;
CREATE POLICY "categories_admin_all" ON public.categories FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ==========================================
-- 5. جدول services
-- ==========================================
DROP POLICY IF EXISTS "services_select" ON public.services;
CREATE POLICY "services_select" ON public.services FOR SELECT TO authenticated
USING (
  status = 'active' OR 
  provider_id = public.get_my_provider_id() OR 
  public.is_admin()
);

DROP POLICY IF EXISTS "services_insert" ON public.services;
CREATE POLICY "services_insert" ON public.services FOR INSERT TO authenticated
WITH CHECK (
  provider_id = public.get_my_provider_id() OR 
  public.is_admin()
);

DROP POLICY IF EXISTS "services_update" ON public.services;
CREATE POLICY "services_update" ON public.services FOR UPDATE TO authenticated
USING (
  provider_id = public.get_my_provider_id() OR 
  public.is_admin()
)
WITH CHECK (
  provider_id = public.get_my_provider_id() OR 
  public.is_admin()
);

DROP POLICY IF EXISTS "services_delete" ON public.services;
CREATE POLICY "services_delete" ON public.services FOR DELETE TO authenticated
USING (
  provider_id = public.get_my_provider_id() OR 
  public.is_admin()
);

-- ==========================================
-- 6. جدول service_images
-- ==========================================
DROP POLICY IF EXISTS "service_images_select" ON public.service_images;
CREATE POLICY "service_images_select" ON public.service_images FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "service_images_insert" ON public.service_images;
CREATE POLICY "service_images_insert" ON public.service_images FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = service_id AND (s.provider_id = public.get_my_provider_id() OR public.is_admin())
  )
);

DROP POLICY IF EXISTS "service_images_delete" ON public.service_images;
CREATE POLICY "service_images_delete" ON public.service_images FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = service_id AND (s.provider_id = public.get_my_provider_id() OR public.is_admin())
  )
);

-- ==========================================
-- 7. جدول service_availability
-- ==========================================
DROP POLICY IF EXISTS "service_availability_select" ON public.service_availability;
CREATE POLICY "service_availability_select" ON public.service_availability FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "service_availability_manage" ON public.service_availability;
CREATE POLICY "service_availability_manage" ON public.service_availability FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = service_id AND (s.provider_id = public.get_my_provider_id() OR public.is_admin())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = service_id AND (s.provider_id = public.get_my_provider_id() OR public.is_admin())
  )
);

-- ==========================================
-- 8. جدول packages
-- ==========================================
DROP POLICY IF EXISTS "packages_select" ON public.packages;
CREATE POLICY "packages_select" ON public.packages FOR SELECT TO authenticated
USING (customer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "packages_insert" ON public.packages;
CREATE POLICY "packages_insert" ON public.packages FOR INSERT TO authenticated
WITH CHECK (customer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "packages_update" ON public.packages;
CREATE POLICY "packages_update" ON public.packages FOR UPDATE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "packages_delete" ON public.packages;
CREATE POLICY "packages_delete" ON public.packages FOR DELETE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin());

-- ==========================================
-- 9. جدول package_items
-- ==========================================
DROP POLICY IF EXISTS "package_items_select" ON public.package_items;
CREATE POLICY "package_items_select" ON public.package_items FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.packages p WHERE p.id = package_id AND (p.customer_id = auth.uid() OR public.is_admin()))
);

DROP POLICY IF EXISTS "package_items_insert" ON public.package_items;
CREATE POLICY "package_items_insert" ON public.package_items FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM public.packages p WHERE p.id = package_id AND (p.customer_id = auth.uid() OR public.is_admin()))
);

DROP POLICY IF EXISTS "package_items_delete" ON public.package_items;
CREATE POLICY "package_items_delete" ON public.package_items FOR DELETE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.packages p WHERE p.id = package_id AND (p.customer_id = auth.uid() OR public.is_admin()))
);

-- ==========================================
-- 10. جدول bookings
-- ==========================================
DROP POLICY IF EXISTS "bookings_select" ON public.bookings;
CREATE POLICY "bookings_select" ON public.bookings FOR SELECT TO authenticated
USING (
  customer_id = auth.uid() OR 
  public.is_admin() OR
  EXISTS (
    SELECT 1 FROM public.booking_items bi
    JOIN public.services s ON s.id = bi.service_id
    WHERE bi.booking_id = bookings.id AND s.provider_id = public.get_my_provider_id()
  )
);

DROP POLICY IF EXISTS "bookings_insert" ON public.bookings;
CREATE POLICY "bookings_insert" ON public.bookings FOR INSERT TO authenticated
WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "bookings_update" ON public.bookings;
CREATE POLICY "bookings_update" ON public.bookings FOR UPDATE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin())
WITH CHECK (customer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "bookings_delete" ON public.bookings;
CREATE POLICY "bookings_delete" ON public.bookings FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 11. جدول booking_items
-- ==========================================
DROP POLICY IF EXISTS "booking_items_select" ON public.booking_items;
CREATE POLICY "booking_items_select" ON public.booking_items FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_items.booking_id AND b.customer_id = auth.uid()) OR
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = booking_items.service_id AND s.provider_id = public.get_my_provider_id()
  ) OR
  public.is_admin()
);

DROP POLICY IF EXISTS "booking_items_insert" ON public.booking_items;
CREATE POLICY "booking_items_insert" ON public.booking_items FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_items.booking_id AND b.customer_id = auth.uid()) OR
  public.is_admin()
);

DROP POLICY IF EXISTS "booking_items_update" ON public.booking_items;
CREATE POLICY "booking_items_update" ON public.booking_items FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = booking_items.service_id AND s.provider_id = public.get_my_provider_id()
  ) OR
  public.is_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.services s
    WHERE s.id = booking_items.service_id AND s.provider_id = public.get_my_provider_id()
  ) OR
  public.is_admin()
);

DROP POLICY IF EXISTS "booking_items_delete" ON public.booking_items;
CREATE POLICY "booking_items_delete" ON public.booking_items FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 12. جدول favorites
-- ==========================================
DROP POLICY IF EXISTS "favorites_owner" ON public.favorites;
CREATE POLICY "favorites_owner" ON public.favorites FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ==========================================
-- 13. جدول reviews
-- ==========================================
DROP POLICY IF EXISTS "reviews_select" ON public.reviews;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT TO authenticated
WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "reviews_update" ON public.reviews;
CREATE POLICY "reviews_update" ON public.reviews FOR UPDATE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "reviews_delete" ON public.reviews;
CREATE POLICY "reviews_delete" ON public.reviews FOR DELETE TO authenticated
USING (customer_id = auth.uid() OR public.is_admin());

-- ==========================================
-- 14. جدول complaints
-- ==========================================
DROP POLICY IF EXISTS "complaints_select" ON public.complaints;
CREATE POLICY "complaints_select" ON public.complaints FOR SELECT TO authenticated
USING (user_id = auth.uid() OR assigned_to = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "complaints_insert" ON public.complaints;
CREATE POLICY "complaints_insert" ON public.complaints FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "complaints_update" ON public.complaints;
CREATE POLICY "complaints_update" ON public.complaints FOR UPDATE TO authenticated
USING (public.is_admin() OR assigned_to = auth.uid());

DROP POLICY IF EXISTS "complaints_delete" ON public.complaints;
CREATE POLICY "complaints_delete" ON public.complaints FOR DELETE TO authenticated
USING (public.is_admin());

-- ==========================================
-- 15. جدول notifications
-- ==========================================
DROP POLICY IF EXISTS "notifications_owner" ON public.notifications;
CREATE POLICY "notifications_owner" ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ==========================================
-- 16. جدول booking_status_history
-- ==========================================
DROP POLICY IF EXISTS "history_select" ON public.booking_status_history;
CREATE POLICY "history_select" ON public.booking_status_history FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_id AND b.customer_id = auth.uid()) OR
  EXISTS (
    SELECT 1 FROM public.booking_items bi
    JOIN public.services s ON s.id = bi.service_id
    WHERE bi.booking_id = booking_status_history.booking_id AND s.provider_id = public.get_my_provider_id()
  ) OR
  public.is_admin()
);

