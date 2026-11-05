-- ========================================================
-- Seed File: seed_demo_data.sql
-- Description: بيانات تجريبية آمنة ومتوافقة مع مخطط خِدمتي (Idempotent)
-- ========================================================

-- 1. التأكد من التصنيفات الأساسية الستة
INSERT INTO public.categories (name, description, sort_order, image_url, is_active)
VALUES 
    ('قاعات المناسبات', 'أفخم قاعات وصالات الأعراس والمؤتمرات', 1, 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=400&q=80', true),
    ('تنسيق وديكور الحفلات', 'كوشات ملكية وديكورات عصرية للمناسبات', 2, 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=400&q=80', true),
    ('الكيك والحلويات', 'قوالب كيك مخصصة وحلويات فاخرة للأعراس', 3, 'https://images.unsplash.com/photo-1535141192574-5d4897c13136?auto=format&fit=crop&w=400&q=80', true),
    ('تنسيق الزهور والهدايا', 'مسكات عرائس وبوكيهات وتنسيق ورود طبيعية', 4, 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=400&q=80', true),
    ('تصوير ومونتاج', 'تصوير فوتوغرافي وسينمائي بأحدث الكاميرات', 5, 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?auto=format&fit=crop&w=400&q=80', true),
    ('استراحات وشاليهات', 'استراحات عائلية وشاليهات مميزة للجمعات', 6, 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=400&q=80', true)
ON CONFLICT DO NOTHING;

-- 2. إدخال الخدمات التجريبية المرتبطة بمقدم الخدمة المعتمد
DO $$
DECLARE
    v_provider_id UUID;
    v_cat_venues UUID;
    v_cat_decor UUID;
    v_cat_cakes UUID;
    v_cat_flowers UUID;
    v_cat_photo UUID;
    v_cat_chalets UUID;
BEGIN
    -- جلب أول مقدم خدمة معتمد
    SELECT id INTO v_provider_id FROM public.provider_profiles WHERE status = 'approved' LIMIT 1;
    
    -- جلب معرفات التصنيفات
    SELECT id INTO v_cat_venues FROM public.categories WHERE name = 'قاعات المناسبات' LIMIT 1;
    SELECT id INTO v_cat_decor FROM public.categories WHERE name = 'تنسيق وديكور الحفلات' LIMIT 1;
    SELECT id INTO v_cat_cakes FROM public.categories WHERE name = 'الكيك والحلويات' LIMIT 1;
    SELECT id INTO v_cat_flowers FROM public.categories WHERE name = 'تنسيق الزهور والهدايا' LIMIT 1;
    SELECT id INTO v_cat_photo FROM public.categories WHERE name = 'تصوير ومونتاج' LIMIT 1;
    SELECT id INTO v_cat_chalets FROM public.categories WHERE name = 'استراحات وشاليهات' LIMIT 1;

    IF v_provider_id IS NOT NULL THEN
        -- قاعات
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, capacity, location, image_url, features, status)
        SELECT v_provider_id, v_cat_venues, 'صالة الديار الكبرى للمناسبات VIP (تجريبي)', 'صالة فخمة تتسع لـ 500 شخص مع أرقى التجهيزات الصوتية والضوئية', 450000, 'YER', 500, 'صنعاء - بيت بوس', 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80', ARRAY['تكييف مركزي', 'شاشات عرض عملاقة', 'جناح خاص للعروس'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'صالة الديار الكبرى للمناسبات VIP (تجريبي)');

        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, capacity, location, image_url, features, status)
        SELECT v_provider_id, v_cat_venues, 'صالة المراسيم الملكية VIP (تجريبي)', 'صالة فندقية فاخرة تتسع لـ 450 شخص مع كوشة وإضاءات ليزر متطورة وخدمة ضيافة متكاملة', 380000, 'YER', 450, 'صنعاء - شارع الستين', 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80', ARRAY['تكييف مركزي', 'جناح للعروس', 'طاقم إشراف متكامل'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'صالة المراسيم الملكية VIP (تجريبي)');

        -- ديكور
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, location, image_url, features, status)
        SELECT v_provider_id, v_cat_decor, 'الأندلس لتنسيق الكوش الملكية (تجريبي)', 'كوشة عروس فخمة مع ممر مضيء وخلفية ورد طبيعي وتوزيعات إضاءة فريدة مخصصة للصور التذكارية', 220000, 'YER', 'صنعاء - حدة', 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80', ARRAY['ورد طبيعي فاخر', 'ممر مضيء', 'كراسي VIP'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'الأندلس لتنسيق الكوش الملكية (تجريبي)');

        -- كيك
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, location, image_url, features, status)
        SELECT v_provider_id, v_cat_cakes, 'كيكة الزفاف الملكية 4 أدوار (تجريبي)', 'كيكة زفاف هرمية 4 أدوار بنكهة الفانيلا الفرنسية وشوكولاتة بلجيكية فاخرة مع زهور سكرية يدوية', 85000, 'YER', 'صنعاء - الأصبحي', 'https://images.unsplash.com/photo-1535141192574-5d4897c13136?auto=format&fit=crop&w=800&q=80', ARRAY['حشوة فاخرة', 'توصيل مبرد'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'كيكة الزفاف الملكية 4 أدوار (تجريبي)');

        -- زهور
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, location, image_url, features, status)
        SELECT v_provider_id, v_cat_flowers, 'مسكة عروس توليب وجوري هولندي (تجريبي)', 'مسكة عروس كلاسيكية من الورد الجوري الأبيض والتوليب الهولندي الفاخر مع شريط ساتان حريري', 35000, 'YER', 'صنعاء - الصافية', 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&w=800&q=80', ARRAY['ورد طبيعي هولندي', 'تثبيت احترافي'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'مسكة عروس توليب وجوري هولندي (تجريبي)');

        -- تصوير
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, location, image_url, features, status)
        SELECT v_provider_id, v_cat_photo, 'بكج تصوير سينمائي 4K مع ألبوم إيطالي (تجريبي)', 'تغطية كاملة للحفل بكاميرتين سينمائيتين مع درون، وفيديو برومو تشويقي وألبوم حراري إيطالي 30 صفحة', 150000, 'YER', 'المكلا - حي السلام', 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?auto=format&fit=crop&w=800&q=80', ARRAY['تصوير 4K', 'طاقم نسائي', 'ألبوم إيطالي'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'بكج تصوير سينمائي 4K مع ألبوم إيطالي (تجريبي)');

        -- استراحات
        INSERT INTO public.services (provider_id, category_id, name, description, price, currency, capacity, location, image_url, features, status)
        SELECT v_provider_id, v_cat_chalets, 'شاليه الواحة الملكي VIP (تجريبي)', 'استراحة وشاليه فخم بمسبح مغلق وقسمين للرجال والنساء ومسطحات خضراء وجلسات خارجية راقية', 120000, 'YER', 120, 'صنعاء - عصر', 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80', ARRAY['مسبح مغلق', 'مسطحات خضراء', 'مجالس تراثية'], 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.services WHERE name = 'شاليه الواحة الملكي VIP (تجريبي)');

    END IF;
END $$;
