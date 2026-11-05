# توثيق قاعدة بيانات مشروع خِدمتي (Khadematy)
**الحالة الفعلية لقاعدة البيانات الحية المربوطة والمقارنة الفنية مع ملفات الترحيل (SQL Migrations)**

---

## 1. نظرة عامة وتفاصيل الاتصال الحي

تم إجراء فحص حي ومباشر لقاعدة البيانات السحابية لمشروع **خِدمتي (Khadematy)** عبر واجهة Supabase Management API. يوثق هذا الملف البنية الكاملة والواقعية لقاعدة البيانات، مع تفصيل الفروق الدقيقة بين ملفات المخطط المحلي (SQL Migrations) والحالة المنفذة فعلياً على الخادم السحابي.

### بيانات البيئة والمشروع المعتمد:
- **اسم المشروع في Supabase:** `khadematy`
- **معرّف المشروع (Project Ref):** `lynrgiiseawlulwpdesv`
- **المنطقة (Region):** `eu-central-1` (فرانكفورت)
- **محرك قاعدة البيانات:** PostgreSQL 17.11 (`17.11.0.003`)
- **حالة الخدمة:** `ACTIVE_HEALTHY`
- **تنبيه التوافق والالتزام:** تم الالتزام التام بعدم استخدام أو قراءة أي بيانات من مشروع `areej-perfumes`، واقتصر الفحص حصراً وبأمان على مشروع `khadematy`.

---

## 2. نتائج الفحص والمقارنة الحية (Schema Drift & Audit)

### 2.1 الجداول المنفذة فعلياً في Supabase
يحتوي المخطط العام (`public`) على الخادم الحي على **16 جدولاً رئيسياً**، تم التحقق من وجودها وعدد الصفوف المحفوظة فيها حالياً:

| # | اسم الجدول (Table Name) | عدد الصفوف الحالية (Rows) | حالة RLS الفعلية على الخادم | المصدر التأسيسي |
|---|---|---|---|---|
| 1 | `profiles` | 5 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 2 | `provider_profiles` | 2 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` + تعديل مباشر |
| 3 | `provider_applications` | 1 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 4 | `categories` | 6 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 5 | `services` | 23 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 6 | `service_images` | 13 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 7 | `service_availability` | 0 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 8 | `packages` | 11 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 9 | `package_items` | 36 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 10 | `bookings` | 18 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 11 | `booking_items` | 27 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 12 | `favorites` | 3 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 13 | `reviews` | 1 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` + تعديل مباشر |
| 14 | `complaints` | 0 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |
| 15 | `notifications` | 14 |  مفعل (Enabled) | `001_core_schema.sql` + `007` |
| 16 | `booking_status_history` | 21 | ⚠️ غير مفعل (Disabled) | `001_core_schema.sql` |

### 2.2 سجل الترحيلات الرسمي (`supabase_migrations.schema_migrations`)
عند الاستعلام عن جدول تتبع الترحيلات السحابي، وُجد أنه يسجل **4 ملفات ترحيل رسمية فقط**:
1. `20261010110043_001_core_schema` (إنشاء الجداول الـ 16 الأساسية والفهارس الأولية).
2. `20261010110745_002_security_helpers` (دوال المساعدة الأمنية `is_admin`, `get_my_provider_id`, `set_updated_at`).
3. `20261016073851_006_atomic_booking_rpc` (دالة الحجز الذري الأولى).
4. `20261016152853_004_smart_planning_rpc` (دالة التخطيط الذكي للباقات).

### 2.3 الاختلافات الجوهرية المكتشفة بين الملفات والخادم الحي (Differences & Discrepancies)

1. **فروق في الأعمدة (Schema Columns Differences):**
   - **جدول `provider_profiles`:** يحتوي في الخادم الفعلي على عمود إضافي `category` من نوع `TEXT` (يقبل NULL)، وهو **غير موجود** في ملف التأسيس `001_core_schema.sql`. تمت إضافته يدوياً أو عبر واجهة Supabase لدعم تصنيف مزود الخدمة العام.
   - **جدول `reviews`:** يحتوي في الخادم الفعلي على عمود إضافي `provider_reply` من نوع `TEXT` (يقبل NULL)، وهو **غير موجود** في ملف `001_core_schema.sql`. تمت إضافته لدعم رد مقدم الخدمة على تقييمات العملاء.

2. **اختلاف حالة أمان الصفوف (RLS Discrepancy):**
   - ملف `005_rls_policies.sql` في مجلد المشروع يحتوي على أوامر تفعيل RLS لكافة الجداول الـ 16 وأكثر من 30 سياسة أمان، **لكنه لم يُنفذ بالكامل على الخادم الحي**، أو تم تعطيل RLS لاحقاً لتسهيل الاختبارات الأولية.
   - الجدول الوحيد المفعل عليه RLS فعلياً على الخادم هو `public.notifications` (وفق ترحيل `007_secure_notifications_rls.sql`).
   - الجداول الـ 15 الأخرى تعمل حالياً بحالة `rowsecurity = false`. تم توثيق تفاصيل المخاطر والحلول الموصى بها في ملف [DATABASE_SECURITY.md](file:///d:/khadematy/DATABASE_SECURITY.md).

3. **التشغيل المباشر للمشغلات والأتمتة (Out-of-Band Triggers Execution):**
   - على الرغم من أن ملفات `003_triggers_and_automation.sql` و `007_secure_notifications_rls.sql` و `008_booking_notifications_automation.sql` غير مسجلة في جدول `schema_migrations`، إلا أن فحص قواميس النظام (`information_schema.routines` و `information_schema.triggers`) أثبت أن **كافة المشغلات والدوال الواردة فيها منفذة وتعمل بنجاح على الخادم الحي** (مما يؤكد أنه تم تنفيذها يدوياً عبر محرر SQL في Supabase Dashboard).

---

## 3. التوثيق التفصيلي لجداول قاعدة البيانات (16 جدولاً)

---

### 3.1 جدول `profiles` (بيانات المستخدمين وحساباتهم)
- **الوظيفة:** الامتداد لجدول المصادقة المركزي `auth.users`، يحفظ الملف الشخصي للعملاء ومقدمي الخدمات والمديرين، ويتحكم بحالة تفعيل الحساب ودوره في المنصة.
- **المفتاح الأساسي:** `id` (UUID - يرتبط بـ `auth.users.id`).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | - | PRIMARY KEY | مرجع إلى `auth.users(id)` مع حذف متتالي `ON DELETE CASCADE` |
| `full_name` | `TEXT` | لا (NO) | - | NOT NULL | الاسم الكامل للمستخدم |
| `email` | `TEXT` | لا (NO) | - | NOT NULL | البريد الإلكتروني للمستخدم |
| `phone` | `TEXT` | نعم (YES) | NULL | - | رقم الهاتف المحمول للتواصل |
| `avatar_url` | `TEXT` | نعم (YES) | NULL | - | رابط الصورة الشخصية |
| `role` | `TEXT` | لا (NO) | `'customer'` | `CHECK (role IN ('customer', 'provider', 'admin'))` | نوع حساب المستخدم وصلاحياته |
| `is_active` | `BOOLEAN` | لا (NO) | `true` | - | حالة تفعيل الحساب |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ ووقت إنشاء الحساب |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ آخر تحديث |

- **المشغلات الفعالة (Triggers):**
  - `trg_profiles_updated_at`: تحديث `updated_at` تلقائياً عبر `set_updated_at()`.
  - `trg_protect_profile_role`: منع تغيير `role` من قبل المستخدم نفسه عبر `protect_profile_role()`؛ التعديل مقتصر على الأدمن.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.2 جدول `provider_profiles` (ملفات مقدمي الخدمات)
- **الوظيفة:** يحفظ بيانات السجل المهني والتجاري لمزود الخدمة المعتمد، مثل الاسم التجاري والشعار والعنوان وتصنيف النشاط.
- **المفتاح الأساسي:** `id` (UUID - مولد تلقائياً عبر `gen_random_uuid()`).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد لملف المزود |
| `user_id` | `UUID` | لا (NO) | - | UNIQUE, NOT NULL | مرجع فريد إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `business_name` | `TEXT` | لا (NO) | - | NOT NULL | اسم النشاط التجاري أو المهني |
| `description` | `TEXT` | نعم (YES) | NULL | - | نبذة تعريفية عن المزود وخدماته |
| `logo_url` | `TEXT` | نعم (YES) | NULL | - | رابط شعار النشاط التجاري |
| `address` | `TEXT` | نعم (YES) | NULL | - | العنوان الفعلي أو المدينة |
| `status` | `TEXT` | لا (NO) | `'pending'` | `CHECK (status IN ('pending', 'approved', 'rejected', 'suspended'))` | حالة اعتماد المزود من إدارة المنصة |
| `approved_at` | `TIMESTAMPTZ` | نعم (YES) | NULL | - | تاريخ ووقت اعتماد الإدارة للحساب |
| `category` | `TEXT` | نعم (YES) | NULL | *حقل حي إضافي* | مجال نشاط المزود العام |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإنشاء |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ آخر تحديث |

- **المشغلات الفعالة:** `trg_provider_profiles_updated_at` لتحديث `updated_at`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.3 جدول `provider_applications` (طلبات انضمام مقدمي الخدمات)
- **الوظيفة:** إدارة طلبات انضمام المستخدمين الراغبين في التحول إلى مزودي خدمات، مع حفظ أسباب الرفض وسجل مراجعة الإدارة.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف طلب الانضمام |
| `user_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `business_name` | `TEXT` | لا (NO) | - | NOT NULL | الاسم التجاري المقترح |
| `description` | `TEXT` | نعم (YES) | NULL | - | تفاصيل الخدمات والنشاط |
| `phone` | `TEXT` | نعم (YES) | NULL | - | رقم الهاتف المخصص للعمل |
| `address` | `TEXT` | نعم (YES) | NULL | - | العنوان المقترح للنشاط |
| `status` | `TEXT` | لا (NO) | `'pending'` | `CHECK (status IN ('pending', 'approved', 'rejected'))` | حالة دراسة الطلب |
| `reviewed_by` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `profiles(id)` (المشرف) مع `ON DELETE SET NULL` |
| `reviewed_at` | `TIMESTAMPTZ` | نعم (YES) | NULL | - | تاريخ مراجعة الطلب |
| `rejection_reason` | `TEXT` | نعم (YES) | NULL | - | سبب الرفض إن وجد لتوجيه المتقدم |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ تقديم الطلب |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التحديث |

- **المشغلات الفعالة:** `trg_provider_applications_updated_at`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.4 جدول `categories` (تصنيفات الخدمات)
- **الوظيفة:** التصنيفات الأساسية المنظمة للخدمات في المنصة (مثل: قاعات، ضيافة وبوفيه، تصوير، كوش وزينة، صوتيات وإضاءة).
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للتصنيف |
| `name` | `TEXT` | لا (NO) | - | NOT NULL | اسم التصنيف المعروض |
| `description` | `TEXT` | نعم (YES) | NULL | - | وصف تفصيلي للتصنيف ومحتوياته |
| `image_url` | `TEXT` | نعم (YES) | NULL | - | صورة أو أيقونة التصنيف |
| `is_active` | `BOOLEAN` | لا (NO) | `true` | - | حالة ظهور التصنيف للعملاء |
| `sort_order` | `INTEGER` | لا (NO) | `0` | - | ترتيب الظهور في واجهات التطبيق |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإنشاء |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التحديث |

- **المشغلات الفعالة:** `trg_categories_updated_at`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.5 جدول `services` (الخدمات المعروضة)
- **الوظيفة:** صلب منصة خِدمتي؛ يمثل الخدمات الفردية التي يعرضها مقدمو الخدمات، متضمنة التسعير، السعة الاستيعابية، والميزات.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للخدمة |
| `provider_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `provider_profiles(id)` مع `ON DELETE RESTRICT` (لحماية الحجوزات التاريخية) |
| `category_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `categories(id)` مع `ON DELETE RESTRICT` |
| `name` | `TEXT` | لا (NO) | - | NOT NULL | عنوان أو اسم الخدمة |
| `description` | `TEXT` | نعم (YES) | NULL | - | وصف الخدمة وشروطها ومواصفاتها |
| `price` | `NUMERIC` | لا (NO) | - | `CHECK (price >= 0)` | السعر الأساسي للخدمة (12,2) |
| `currency` | `TEXT` | لا (NO) | `'YER'` | NOT NULL | عملة التسعير (الريال اليمني) |
| `image_url` | `TEXT` | نعم (YES) | NULL | - | الصورة البارزة الرئيسية |
| `location` | `TEXT` | نعم (YES) | NULL | - | الموقع الجغرافي أو قاعة/مكتب تقديم الخدمة |
| `capacity` | `INTEGER` | نعم (YES) | NULL | `CHECK (capacity IS NULL OR capacity > 0)` | أقصى سعة حضور (للصالات والبوفيهات) |
| `features` | `TEXT[]` | نعم (YES) | `'{}'::text[]` | مصفوفة نصوص | الميزات الخاصة (تكييف، مصف سيارات، شاشات...) |
| `occasions` | `TEXT[]` | لا (NO) | `'{}'::text[]` | مصفوفة نصوص | المناسبات المتاحة الملائمة للخدمة (زفاف، تخرج...) (011) |
| `working_hours` | `JSONB` | لا (NO) | `'[]'::jsonb` | كائن JSON | مواعيد وأيام وساعات الدوام للخدمة (011) |
| `status` | `TEXT` | لا (NO) | `'active'` | `CHECK (status IN ('active', 'inactive', 'pending'))` | حالة توفر الخدمة للطلب |
| `rating` | `NUMERIC` | لا (NO) | `0.0` | `CHECK (rating >= 0.0 AND rating <= 5.0)` | متوسط التقييم الفعلي (محدث تلقائياً عبر مشغل التقييمات) (010) |
| `reviews_count` | `INTEGER` | لا (NO) | `0` | `CHECK (reviews_count >= 0)` | إجمالي عدد تقييمات الخدمة (010) |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإنشاء |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التحديث |

- **الفهارس المخصصة:**
  - `idx_services_provider_status` على `(provider_id, status)` لسرعة استعلام لوحة المزود.
  - `idx_services_category_status_price` على `(category_id, status, price)` لتسريع الفرز والتصفية وخوارزمية التخطيط الذكي.
  - `idx_services_rating_reviews` على `(rating DESC, reviews_count DESC)` لترتيب الخدمات حسب الأعلى تقييماً والأكثر طلباً.
- **المشغلات الفعالة:** `trg_services_updated_at`، و `trg_sync_service_rating_stats` (مربوط على جدول `reviews`).
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.6 جدول `service_images` (معرض صور الخدمات)
- **الوظيفة:** يتيح للمزود رفع عدة صور لكل خدمة لعرض تفاصيلها ونماذج الأعمال السابقة.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف الصورة |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE CASCADE` |
| `image_url` | `TEXT` | لا (NO) | - | NOT NULL | رابط الصورة المرفوعة في التخزين |
| `sort_order` | `INTEGER` | لا (NO) | `0` | - | ترتيب عرض الصورة |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإضافة |

- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.7 جدول `service_availability` (إدارة التوفر الزمني واستثناءات المزود)
- **الوظيفة:** تمكين المزود من حجب أيام أو فترات زمنية محددة يدوياً لمنع حجزها، وتوثيق استثناءات التوفر.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف سجل التوفر |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE CASCADE` |
| `available_date` | `DATE` | لا (NO) | - | NOT NULL | التاريخ المستهدف |
| `time_slot` | `TEXT` | لا (NO) | `'evening'` | `CHECK (time_slot IN ('morning', 'evening', 'full_day'))` | الفترة الزمنية المقفلة أو المحددة |
| `start_time` | `TIME` | نعم (YES) | NULL | - | وقت البدء الدقيق إن وُجد |
| `end_time` | `TIME` | نعم (YES) | NULL | - | وقت الانتهاء الدقيق إن وُجد |
| `is_available` | `BOOLEAN` | لا (NO) | `true` | - | إذا كانت `false` تعتبر الخدمة محجوبة للتاريخ والفترة |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التسجيل |

- **القيود والفهارس الفريدة:**
  - `unique_service_date_slot` قيد فريد يمنع تكرار السجل لنفس الخدمة والتاريخ والفترة `UNIQUE(service_id, available_date, time_slot)`.
  - `idx_service_avail_date_slot` على `(service_id, available_date, time_slot)` لضمان سرعة الفحص التزامني.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.8 جدول `packages` (الباقات المخصصة والمقترحة)
- **الوظيفة:** تخزين الباقات التي تم إنشاؤها عبر التخطيط الذكي (`generate_smart_package`) أو باقات المناسبات المجهزة مسبقاً، مع ربطها بميزانية وعدد حضور المناسبة.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للباقة |
| `customer_id` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` (قد تكون باقة عامة إذا كانت NULL) |
| `name` | `TEXT` | لا (NO) | - | NOT NULL | اسم الباقة (اقتصادية، متوازنة، فاخرة VIP) |
| `event_type` | `TEXT` | لا (NO) | - | NOT NULL | نوع المناسبة (زفاف، مؤتمر، تخرج...) |
| `budget` | `NUMERIC` | لا (NO) | - | `CHECK (budget >= 0)` | الميزانية المستهدفة للعميل |
| `guest_count` | `INTEGER` | لا (NO) | - | `CHECK (guest_count > 0)` | عدد الحضور المقدر للمناسبة |
| `estimated_total` | `NUMERIC` | لا (NO) | - | `CHECK (estimated_total >= 0)` | المجموع الإجمالي الفعلي لتكلفة خدمات الباقة |
| `currency` | `TEXT` | لا (NO) | `'YER'` | NOT NULL | عملة التقدير |
| `status` | `TEXT` | لا (NO) | `'suggested'` | `CHECK (status IN ('suggested', 'selected', 'expired'))` | حالة الباقة (مقترحة، اختارها العميل، منتهية) |
| `generation_method` | `TEXT` | لا (NO) | `'automatic'` | NOT NULL | طريقة التوليد (`automatic` أو `manual`) |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ توليد الباقة |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التحديث |

- **المشغلات الفعالة:** `trg_packages_updated_at`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.9 جدول `package_items` (عناصر وخدمات الباقة)
- **الوظيفة:** جدول وسيط يربط الباقة بمجموعة الخدمات التي تم تجميعها داخلها مع تثبيت السعر المقدر لكل خدمة لحظة التوليد.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف عنصر الباقة |
| `package_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `packages(id)` مع `ON DELETE CASCADE` |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE RESTRICT` |
| `quantity` | `INTEGER` | لا (NO) | `1` | `CHECK (quantity > 0)` | الكمية المطلوبة |
| `unit_price` | `NUMERIC` | لا (NO) | - | `CHECK (unit_price >= 0)` | سعر الوحدة لحظة التوليد |
| `subtotal` | `NUMERIC` | لا (NO) | - | `CHECK (subtotal >= 0)` | المجموع الجزئي (`quantity * unit_price`) |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإضافة |

- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.10 جدول `bookings` (الحجوزات الفعلية والطلبات المجمعة)
- **الوظيفة:** الجدول المالي والإجرائي المركزي؛ يمثل طلب الحجز الرئيسي الذي يقدمه العميل لمناسبته، سواء كان مبنياً على باقة أو خدمات مختارة فردياً.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للحجز |
| `booking_code` | `TEXT` | لا (NO) | - | UNIQUE, NOT NULL | كود الحجز البشري الفريد مثل `KH-26-10005` |
| `customer_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE RESTRICT` (لحماية السجل المالي) |
| `package_id` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `packages(id)` مع `ON DELETE SET NULL` |
| `event_type` | `TEXT` | لا (NO) | - | NOT NULL | نوع الفعالية أو المناسبة |
| `event_date` | `DATE` | لا (NO) | - | NOT NULL | تاريخ إقامة المناسبة |
| `time_slot` | `TEXT` | لا (NO) | `'evening'` | `CHECK (time_slot IN ('morning', 'evening', 'full_day'))` | الفترة الزمنية للمناسبة |
| `event_location` | `TEXT` | نعم (YES) | NULL | - | موقع المناسبة التفصيلي أو المدينة |
| `guest_count` | `INTEGER` | نعم (YES) | NULL | `CHECK (guest_count IS NULL OR guest_count > 0)` | عدد الحضور الفعلي المسجل |
| `budget` | `NUMERIC` | نعم (YES) | NULL | - | الميزانية التقديرية المرصودة |
| `total_amount` | `NUMERIC` | لا (NO) | - | `CHECK (total_amount >= 0)` | إجمالي قيمة الحجز الفعلي المحسوبة بدقة |
| `status` | `TEXT` | لا (NO) | `'pending'` | `CHECK (status IN ('pending', 'partially_accepted', 'confirmed', 'attention_needed', 'in_progress', 'completed', 'cancelled'))` | الحالة الشاملة للطلب عبر آلة الحالات (State Machine) |
| `notes` | `TEXT` | نعم (YES) | NULL | - | ملاحظات وتوصيات خاصة من العميل |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ ووقت تسجيل الحجز |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ آخر تعديل |

- **الفهارس والقيود:**
  - `bookings_booking_code_key` قيد فريد لكود الحجز.
  - `idx_bookings_customer_status` على `(customer_id, status)` لاسترجاع طلبات العميل بسرعة.
  - `idx_bookings_date_slot_status` على `(event_date, time_slot, status)` للتحقق السريع من تعارضات المواعيد.
- **المشغلات الفعالة:**
  - `trg_set_booking_code`: توليد الكود التسلسلي تلقائياً قبل الإدراج.
  - `trg_validate_booking_update`: تدقيق صحة انتقال الحالات ومنع التعديل غير المصرح.
  - `trg_bookings_updated_at`: تحديث `updated_at`.
  - `trg_log_booking_status_change`: تدوين أي تحول في الحالة في جدول الأرشيف.
  - `trg_booking_status_notifications`: إرسال إشعارات فورية للطرفين عند تبدل الحالة.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.11 جدول `booking_items` (عناصر وخدمات الحجز وردود المزودين)
- **الوظيفة:** تفصيل الخدمات المكونة للحجز؛ يتيح لكل مزود خدمة استلام إشعار بالخدمة التابعة له، والموافقة أو الرفض بشكل مستقل، مع تجميد السعر الرسمي لحظة الحجز.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد لعنصر الحجز |
| `booking_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `bookings(id)` مع `ON DELETE CASCADE` |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE RESTRICT` |
| `quantity` | `INTEGER` | لا (NO) | `1` | `CHECK (quantity > 0)` | الكمية المطلوبة من الخدمة |
| `unit_price` | `NUMERIC` | لا (NO) | - | `CHECK (unit_price >= 0)` | السعر الرسمي المعتمد لحظة الحجز (تجميد السعر) |
| `subtotal` | `NUMERIC` | لا (NO) | - | `CHECK (subtotal >= 0)` | المجموع الجزئي |
| `item_status` | `TEXT` | لا (NO) | `'pending'` | `CHECK (item_status IN ('pending', 'accepted', 'rejected'))` | حالة رد المزود على هذا البند |
| `rejection_reason` | `TEXT` | نعم (YES) | NULL | - | سبب اعتذار المزود إن رفض |
| `responded_at` | `TIMESTAMPTZ` | نعم (YES) | NULL | - | توقيت رد المزود بالقبول أو الرفض |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ تسجيل العنصر |

- **الفهارس والمشغلات:**
  - `idx_booking_items_booking` على `(booking_id)` لجلب عناصر الحجز.
  - `idx_booking_items_service_status` على `(service_id, item_status)` لفحص التعارضات السريع.
  - `trg_check_booking_slot_conflict`: منع الحجز المزدوج قبل الإدراج أو التحديث.
  - `trg_restrict_booking_item_update`: تقييد المزود بحيث لا يعدل سوى حالة القبول والرفض والسبب فقط.
  - `trg_on_booking_item_status_change`: تحديث حالة الحجز الرئيسي تلقائياً وإخطار العميل فور اكتمال الموافقات أو وجود رفض.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.12 جدول `favorites` (قائمة المفضلة)
- **الوظيفة:** حفظ الخدمات التي أبدى المستخدم إعجابه بها للرجوع إليها لاحقاً.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف السجل |
| `user_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE CASCADE` |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ الإضافة للمفضلة |

- **القيود والفهارس الفريدة:**
  - `unique_user_favorite`: قيد فريد يمنع تكرار تفضيل نفس الخدمة من نفس المستخدم `UNIQUE(user_id, service_id)`.
  - `idx_favorites_user_service` على `(user_id, service_id)`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.13 جدول `reviews` (التقييمات والآراء)
- **الوظيفة:** حفظ تقييمات العملاء للخدمات من 1 إلى 5 نجوم مع تعليقاتهم وردود المزودين، وربطها بالحجز الفعلي للتحقق من الموثوقية.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للتقييم |
| `customer_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `service_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `services(id)` مع `ON DELETE CASCADE` |
| `booking_id` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `bookings(id)` مع `ON DELETE SET NULL` للتحقق من مصداقية التجربة |
| `rating` | `SMALLINT` | لا (NO) | - | `CHECK (rating >= 1 AND rating <= 5)` | عدد النجوم (1 إلى 5) |
| `comment` | `TEXT` | نعم (YES) | NULL | - | رأي العميل المكتوب |
| `provider_reply` | `TEXT` | نعم (YES) | NULL | *حقل حي إضافي* | رد مزود الخدمة المعتمد على التقييم |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التقييم |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ التحديث |

- **الفهارس والمشغلات:**
  - `idx_reviews_service_rating` على `(service_id, rating)` لحساب متوسط التقييمات سريعاً.
  - `trg_reviews_updated_at` لتحديث `updated_at`.
  - `trg_sync_service_rating_stats` لتحديث متوسط التقييم `rating` وعدد التقييمات `reviews_count` في جدول `services` تلقائياً عند أي إدراج أو تعديل أو حذف.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.14 جدول `complaints` (الشكاوى والنزاعات)
- **الوظيفة:** إدارة شكاوى المستخدمين بخصوص الحجوزات أو مقدمي الخدمات ومتابعة مسار معالجتها من قبل فريق الدعم والإدارة.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف الشكوى |
| `user_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `booking_id` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `bookings(id)` مع `ON DELETE SET NULL` |
| `subject` | `TEXT` | لا (NO) | - | NOT NULL | عنوان أو موضوع الشكوى |
| `description` | `TEXT` | لا (NO) | - | NOT NULL | تفاصيل الشكوى والوقائع |
| `status` | `TEXT` | لا (NO) | `'pending'` | `CHECK (status IN ('pending', 'in_review', 'resolved', 'closed'))` | حالة متابعة الشكوى |
| `assigned_to` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `profiles(id)` (الموظف المسؤول) مع `ON DELETE SET NULL` |
| `resolution` | `TEXT` | نعم (YES) | NULL | - | القرار المتخذ أو الحل المطبق |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ تقديم الشكوى |
| `updated_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ تحديث الشكوى |

- **المشغلات الفعالة:** `trg_complaints_updated_at`.
- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

### 3.15 جدول `notifications` (الإشعارات الحية)
- **الوظيفة:** قناة التواصل اللحظية مع العميل ومقدم الخدمة؛ يحفظ التنبيهات الخاصة بتحديثات الحجز وتنبيهات القبول والرفض، ومجهز للبث الحي عبر Supabase Realtime.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | المعرف الفريد للإشعار |
| `user_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `profiles(id)` مع `ON DELETE CASCADE` |
| `title` | `TEXT` | لا (NO) | - | NOT NULL | عنوان التنبيه |
| `body` | `TEXT` | لا (NO) | - | NOT NULL | نص ومحتوى الإشعار |
| `type` | `TEXT` | لا (NO) | - | NOT NULL | نوع الإشعار (`booking_created`, `booking_confirmed`, `new_booking_request`...) |
| `related_booking_id` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `bookings(id)` مع `ON DELETE SET NULL` |
| `is_read` | `BOOLEAN` | لا (NO) | `false` | NOT NULL | حالة القراءة |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | تاريخ ووقت الإرسال |

- **الفهارس والمشغلات:**
  - `idx_notifications_user_read_created` على `(user_id, is_read, created_at DESC)` لسرعة استعلام شارة الإشعارات غير المقروءة.
  - `trg_enforce_notification_immutability`: مشغل أمني صارم يمنع تعديل أي حقل من محتوى الإشعار أو هويته، ويسمح فقط بتعديل `is_read`.
- **حالة RLS الفعلية:** **مفعلة (Enabled)**.
  - سياسة `notifications_select_own`: تسمح للمستخدم المسجل بقراءة إشعاراته حصراً (`user_id = auth.uid()`).
  - سياسة `notifications_update_own`: تسمح للمستخدم بتحديث إشعاراته فقط (لتعديل `is_read`).

---

### 3.16 جدول `booking_status_history` (سجل تتبع ومراجعة حالات الحجز)
- **الوظيفة:** سجل تدقيق تاريخي غير قابل للتعديل (Audit Trail)؛ يسجل كل تحول في حالة الحجز مع معرف من أجرى التحويل، والتوقيت، وملاحظات التغيير.
- **المفتاح الأساسي:** `id` (UUID).

| اسم العمود | نوع البيانات | يقبل NULL | القيمة الافتراضية | القيود والشروط | المفاتيح الأجنبية / الوظيفة |
|---|---|---|---|---|---|
| `id` | `UUID` | لا (NO) | `gen_random_uuid()` | PRIMARY KEY | معرف سجل الحالة |
| `booking_id` | `UUID` | لا (NO) | - | NOT NULL | مرجع إلى `bookings(id)` مع `ON DELETE CASCADE` |
| `old_status` | `TEXT` | نعم (YES) | NULL | - | الحالة السابقة قبل التغيير (تكون NULL عند الإنشاء الأول) |
| `new_status` | `TEXT` | لا (NO) | - | NOT NULL | الحالة الجديدة المعتمدة |
| `changed_by` | `UUID` | نعم (YES) | NULL | - | مرجع إلى `profiles(id)` مع `ON DELETE SET NULL` (المستخدم أو المشرف أو النظام) |
| `note` | `TEXT` | نعم (YES) | NULL | - | إيضاحات سبب التعديل أو نوع الإجراء |
| `created_at` | `TIMESTAMPTZ` | لا (NO) | `now()` | - | توقيت تسجيل التغيير |

- **حالة RLS الفعلية:** غير مفعلة (Disabled).

---

## 4. توثيق الدوال والمشغلات والفهارس المنفذة فعلياً

### 4.1 قائمة الدوال المخزنة الحية (15 دالة في المخطط `public`)

| اسم الدالة (Function Name) | نوعها | صلاحية الأمان | الغرض والوظيفة البرمجية |
|---|---|---|---|
| `check_booking_slot_conflict` | Trigger | `SECURITY DEFINER` | فحص ومنع التعارض المزدوج للخدمة مع قفل سجل الخدمة `FOR UPDATE`. |
| `create_booking_atomic` | RPC (Function) | `SECURITY DEFINER` | إنشاء الحجز وعناصره وإشعاراته وسجل حالته في معاملة ذرية متماسكة. |
| `enforce_notification_immutability` | Trigger | `SECURITY DEFINER` | منع التلاعب في نصوص أو تواريخ الإشعارات، وقصر التعديل على `is_read`. |
| `generate_smart_package` | RPC (Function) | `SECURITY DEFINER` | محرك التخطيط الذكي وتوليد 3 باقات متوافقة مع الميزانية والتاريخ والسعة. |
| `get_my_provider_id` | Helper | `SECURITY DEFINER` | استرجاع معرف ملف المزود المعتمد للمستخدم المسجل الحالي. |
| `handle_new_user` | Trigger | `SECURITY DEFINER` | مشغل على `auth.users` ينشئ ملفاً في `profiles` مع قفل الدور على `customer`. |
| `is_admin` | Helper | `SECURITY DEFINER` | فحص هل المستخدم الحالي يمتلك دور `admin` وحسابه نشط، لكسر حلقات RLS المفرغة. |
| `log_booking_status_change` | Trigger | `SECURITY DEFINER` | مشغل يسجل التغيرات في حالات الحجز تلقائياً في `booking_status_history`. |
| `on_booking_item_status_change` | Trigger | `SECURITY DEFINER` | مشغل يحسب ردود المزودين على بنود الحجز ويحدث حالة الحجز الكلي وإشعار العميل. |
| `on_booking_status_change_notifications` | Trigger | `SECURITY DEFINER` | مشغل يولد إشعارات للعميل والمزودين عند إلغاء أو إكمال الحجز. |
| `protect_profile_role` | Trigger | `SECURITY DEFINER` | منع تصعيد الصلاحيات ومنع المستخدم من ترقية دوره إلى `admin` أو `provider`. |
| `restrict_booking_item_update` | Trigger | `SECURITY DEFINER` | تقييد صلاحية المزود على `booking_items` بالرد بالقبول أو الرفض وتجميد السعر. |
| `set_booking_code` | Trigger | `SECURITY INVOKER` | توليد كود الحجز المتسلسل بصيغة `KH-YY-XXXXX` قبل حفظ السجل. |
| `set_updated_at` | Trigger | `SECURITY INVOKER` | تحديث حقل `updated_at` بالوقت الحالي `now()` قبل كل عملية تعديل. |
| `validate_booking_update` | Trigger | `SECURITY DEFINER` | التحقق من قواعد آلة حالات الحجز ومنع تعديل البيانات الحساسة بعد التأكيد. |

---

### 4.2 الفحص المعمق للدوال الاستراتيجية

#### 1. دالة التخطيط الذكي للباقات: `generate_smart_package`
- **المعاملات المدخلة:**
  - `p_customer_id UUID`: معرف العميل صاحب الطلب.
  - `p_event_type TEXT`: نوع المناسبة (زفاف، حفل، اجتماع عمل...).
  - `p_budget NUMERIC`: الميزانية الإجمالية المحددة من العميل.
  - `p_guest_count INTEGER`: عدد الحضور المتوقع.
  - `p_category_ids UUID[]`: مصفوفة معرّفات التصنيفات المطلوبة (قاعة، ضيافة، تصوير...).
  - `p_event_date DATE`: تاريخ إقامة الفعالية.
  - `p_time_slot TEXT DEFAULT 'evening'`: الفترة الزمنية المختارة.
- **آلية العمل وخوارزمية التوليد:**
  1. **التحقق المبدئي:** التأكد من صلاحية الميزانية وعدد الحضور وتمرير تصنيف واحد على الأقل.
  2. **فحص التوفر وحساب الحد الأدنى للميزانية:**
     - تدور الدالة على كل تصنيف مطلوب، وتستعلم عن أقل خدمة سعراً تحقق الشروط:
       - أن تكون الخدمة نشطة `status = 'active'` ومقدمها معتمداً `pp.status = 'approved'`.
       - أن تسع عدد الحضور `capacity IS NULL OR capacity >= p_guest_count`.
       - ألا تكون محجوبة يدوياً في `service_availability` لنفس التاريخ والفترة.
       - ألا تكون محجوزة بحجز نشط متزامن في جدول `bookings` و `booking_items`.
     - إذا تعذر وجود أي خدمة متاحة لأحد التصنيفات المطلوبة، ترجع الدالة خطأ فورياً يحدد التصنيفات غير المتاحة (`SERVICES_UNAVAILABLE`).
     - تحسب مجموع أقل الأسعار المتاحة؛ فإذا كانت الميزانية المدخلة أقل من هذا المجموع، ترجع خطأ صريحاً يوضح الحد الأدنى المطلوب للميزانية (`INSUFFICIENT_BUDGET`).
  3. **توليد الباقات الثلاث:**
     تنشئ الدالة 3 سجلات في جدول `packages`:
     - **الباقة الاقتصادية (Economy):** تختار أرخص خدمة متاحة في كل تصنيف (`ORDER BY s.price ASC LIMIT 1`).
     - **الباقة المتوازنة (Balanced - الأكثر طلباً):** تقسم الميزانية بالتساوي على عدد التصنيفات (`v_cat_budget = budget / count`)، وتختار الخدمة الأقرب سعراً لحصة التصنيف (`ORDER BY abs(s.price - v_cat_budget) ASC LIMIT 1`).
     - **الباقة الفاخرة (VIP):** تختار أعلى الخدمات جودة وسعراً المتاحة في كل تصنيف (`ORDER BY s.price DESC LIMIT 1`).
  4. **ربط الخدمات بالباقات:**
     - تدرج الخدمات المختارة في جدول `package_items` بالكمية وسعر الوحدة والمجموع.
     - تحدث المجموع المقدر النهائي `estimated_total` لكل باقة في جدول `packages`.
  5. **المخرجات:**
     - كائن JSONB متكامل يرجع معرفات الباقات الثلاث مع إجمالي تكلفة كل باقة (`economy_package_id`, `balanced_package_id`, `vip_package_id`).

---

#### 2. دالة الحجز الذري: `create_booking_atomic`
- **المعاملات المدخلة:**
  - `p_event_type`, `p_event_date`, `p_time_slot`, `p_service_ids UUID[]`, `p_package_id`, `p_event_location`, `p_guest_count`, `p_budget`, `p_notes`, `p_customer_id`.
- **المزايا الفنية ومنع السباق والتعارض (Race Conditions & Double Bookings):**
  1. **التحقق من الهوية:** تستخلص هوية العميل من جلسة المصادقة `auth.uid()` وتتأكد من وجود حسابه وتفعيله في `profiles`.
  2. **منع التعليق التزامني (Deadlock Prevention):** ترتب معرفات الخدمات أبجدياً وتزيل التكرار:
     ```sql
     SELECT array_agg(DISTINCT id ORDER BY id) INTO v_sorted_ids FROM unnest(p_service_ids) AS id;
     ```
  3. **قفل الصفوف الصارم (Row-Level Lock):**
     - تستخدم `PERFORM 1 FROM public.services WHERE id = v_srv_id FOR UPDATE;` لقفل كل خدمة قبل حجزها لمنع أي معاملة متزامنة أخرى من حجز نفس الخدمة في نفس اللحظة.
  4. **فحص التوفر المزدوج:**
     - تتأكد من أن الخدمة نشطة والمزود معتمد والسعة كافية.
     - تتأكد من عدم وجود حجب في `service_availability`.
     - تتأكد من عدم وجود حجز نشط متزامن لنفس التاريخ والفترة (`pending`, `confirmed`, `in_progress`...).
  5. **تجميد السعر وحساب الإجمالي من قاعدة البيانات:**
     - تقرأ السعر المعتمد المخزن في جدول `services` وتجمعه داخلياً؛ لا تثق في أي أسعار ممررة من واجهة العميل لمنع أي تلاعب في المبالغ.
  6. **الإنشاء المتكامل:**
     - تدرج الحجز في `bookings`، وتولد الكود `booking_code`.
     - تدرج الخدمات في `booking_items` مع تجميد السعر والكمية.
     - تسجل العملية في `booking_status_history`.
     - تنشئ إشعاراً فورياً للعميل وإشعاراً مخصصاً لكل مزود خدمة تم حجز خدمته في جدول `notifications`.

---

#### 3. مشغل منع الحجز المزدوج: `check_booking_slot_conflict`
- يرتبط بجدول `booking_items` قبل الإدراج أو التحديث (`BEFORE INSERT OR UPDATE OF service_id, item_status`).
- يمثل خط الدفاع الثاني لحماية البيانات؛ حتى لو تمت محاولة إضافة بند حجز خارج دالة `create_booking_atomic` (مثلاً عبر لوحة التحكم أو واجهة التطبيق مباشرة)، يقوم المشغل بقفل الخدمة وفحص التاريخ والفترة المتطابقة أو الكاملة (`full_day`)، ويرفض المعاملة تلقائياً إذا وُجد تعارض نشط.

---

## 5. أمثلة عملية توضيحية لتدفق البيانات والعلاقات

يوضح المثال الافتراضي التالي دورة حياة حجز مناسبة زفاف بين عميل ومقدمي خدمات:

### الخطوة 1: العميل ومزود الخدمة في `profiles` و `provider_profiles`
- **حساب العميل:**
  - `id`: `c1111111-1111-1111-1111-111111111111`
  - `full_name`: "أحمد علي باوزير"
  - `role`: `customer`
- **حساب مزود الخدمة (قاعات الأفراح):**
  - في `profiles`: `id = p2222222-2222-2222-2222-222222222222`، `full_name`: "سالم اليافعي"، `role`: `provider`
  - في `provider_profiles`: `id = pp333333-3333-3333-3333-333333333333`، `business_name`: "قصر التاج الملكي للأفراح"، `status`: `approved`.

### الخطوة 2: تسجيل الخدمات في `services`
- **خدمة القاعة:**
  - `id`: `s4444444-4444-4444-4444-444444444444`
  - `provider_id`: `pp333333-3333-3333-3333-333333333333`
  - `category_id`: معرف تصنيف القاعات
  - `name`: "القاعة الملكية الكبرى"
  - `price`: `350000.00` ريال يمني
  - `capacity`: 500 ضيف
  - `status`: `active`

### الخطوة 3: التخطيط الذكي وإنشاء الباقة في `packages` و `package_items`
- يستدعي التطبيق `generate_smart_package` بميزانية 600,000 ريال لـ 300 ضيف بتاريخ `2026-11-20`.
- يتم إنشاء الباقة المتوازنة في `packages`:
  - `id`: `pkg55555-5555-5555-5555-555555555555`
  - `name`: "باقة متوازنة (الأكثر طلباً)"
  - `estimated_total`: `520000.00` ريال
- يتم إدراج الخدمات في `package_items`:
  - السجل 1: `service_id` = القاعة الملكية، `unit_price` = `350000.00`
  - السجل 2: `service_id` = بوفيه الأمانة، `unit_price` = `170000.00`

### الخطوة 4: تثبيت الحجز في `bookings` و `booking_items`
- يستدعي العميل دالة `create_booking_atomic` لاختيار الباقة:
  - يُنشأ سجل في `bookings`:
    - `id`: `b6666666-6666-6666-6666-666666666666`
    - `booking_code`: `KH-26-10012`
    - `customer_id`: `c1111111-1111-1111-1111-111111111111`
    - `package_id`: `pkg55555-5555-5555-5555-555555555555`
    - `total_amount`: `520000.00`
    - `status`: `pending`
  - يُنشأ سجل لكل خدمة في `booking_items`:
    - عنصر القاعة الملكية: `item_status = 'pending'`, `unit_price = 350000.00`
    - عنصر البوفيه: `item_status = 'pending'`, `unit_price = 170000.00`
  - يُنشأ سجل تدقيق في `booking_status_history`:
    - `old_status = NULL`, `new_status = 'pending'`, `note = 'إنشاء طلب الحجز المبدئي...'`
  - يُنشأ 3 إشعارات في `notifications`:
    - إشعار للعميل: "تم استلام طلب حجزك بنجاح برقم KH-26-10012".
    - إشعار لمزود القاعة: "لديك طلب حجز جديد للقاعة الملكية الكبرى".
    - إشعار لمزود البوفيه: "لديك طلب حجز جديد لبوفيه الأمانة".

### الخطوة 5: ردود المزودين وانعكاس الحالة التلقائي
- يفتح مزود القاعة تطبيقه ويوافق على الحجز: يتم تحديث `booking_items` للعنصر الأول إلى `item_status = 'accepted'`.
- يعمل المشغل `trg_on_booking_item_status_change`:
  - تصبح حالة الحجز الرئيسي `partially_accepted` لأن عنصر البوفيه لا يزال `pending`.
- يوافق مزود البوفيه: يتم تحديث العنصر الثاني إلى `accepted`.
- يعمل المشغل مجدداً ويكتشف قبول كافة العناصر (`accepted_items = total_items`):
  - يتم تحويل حالة الحجز تلقائياً إلى `confirmed`.
  - يتم إرسال إشعار فوري للعميل: "تم تأكيد حجزك بالكامل!".
  - يتم تسجيل الانتقال في `booking_status_history`.
