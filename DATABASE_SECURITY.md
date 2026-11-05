# دليل الأمان وسياسات حماية البيانات (DATABASE SECURITY)
**التقرير الأمني الميداني، تدقيق سياسات الوصول (RLS)، وضوابط الحماية في مشروع خِدمتي (Khadematy)**

---

## 1. التقرير الأمني الميداني لحالة قاعدة البيانات الحية

تم إجراء تدقيق أمني مباشر على قاعدة البيانات السحابية الحية في Supabase (المشروع `khadematy`، المعرف `lynrgiiseawlulwpdesv`). يلخص هذا القسم الوضع الأمني الفعلي للمشروع مقارنة بالمعايير المقترحة.

### 1.1 حالة أمان الصفوف (Row Level Security - RLS) الحالية على الخادم
كشف الفحص المباشر لجدول `pg_tables` واستعلامات موجه الأمان (Supabase Security Advisor) عن النتائج التالية:

| نطاق الجداول | حالة RLS الفعلية | مستوى الخطورة | الإجراء الفعلي المطبق |
|---|---|---|---|
| جدول `notifications` | **مفعل (Enabled)** | آمن (Secure) | سياسات وصول دقيقة + مشغل منع تلاعب + تقييد صلاحيات الأعمدة. |
| **15 جدولاً أخرى** (`profiles`, `services`, `bookings`, ...) | ⚠️ **غير مفعل (Disabled)** | **حرج (Critical)** | الصفوف متاحة للقراءة والتعديل المباشر لمن يملك مفتاح `anon`. |

### 1.2 تنبيه الأمان الحرج (Critical Security Advisory)
أصدر مستشار الأمان في Supabase التنبيه التالي:
> **RLS is disabled on 15 public tables:**
> الجداول الـ 15 معرضة بالكامل للاستعلام المباشر عبر مكتبات العميل باستخدام المفتاح العام (`anon key`) أو حسابات المستخدمين المسجلين (`authenticated`).
> **تنبيه:** تم تصميم ملف `005_rls_policies.sql` في مستودع المشروع ليحل هذه المشكلة جذرياً، ولكنه لم يُطبّق بعد على قاعدة البيانات الحية منعاً لتعطيل مسارات العمل التجريبية قبل اكتمال ضبط صلاحيات واجهات التطبيق.

---

## 2. السياسات الأمنية المنفذة فعلياً على الخادم الحي

### جدول `public.notifications` (النموذج الأمني المكتمل)
تم تأمين جدول الإشعارات بنجاح وفق ترحيل `007_secure_notifications_rls.sql`، وهو النموذج الموصى بتعميمه على باقي الجداول:

#### 1. سياسات RLS النشطة في `pg_policies`:
- **سياسة القراءة (`notifications_select_own`):**
  ```sql
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
  ```
  *الأثر الأمني:* لا يمكن لأي مستخدم استرجاع أو استراق النظر على إشعارات مستخدم آخر، حتى لو أرسل استعلاماً مخصصاً بالمعرف الخاص به.

- **سياسة التحديث (`notifications_update_own`):**
  ```sql
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));
  ```
  *الأثر الأمني:* يقتصر حق التحديث على سجلات المستخدم الخاصة به حصراً.

#### 2. تقييد الصلاحيات على مستوى الجدول والأعمدة (Column-Level Grants):
- تم سحب كافة الصلاحيات الموروثة تماماً:
  ```sql
  REVOKE ALL ON TABLE public.notifications FROM anon, authenticated;
  ```
- تمت إعادة منح الحد الأدنى المشروع فقط لدور `authenticated`:
  ```sql
  GRANT SELECT ON public.notifications TO authenticated;
  GRANT UPDATE (is_read) ON public.notifications TO authenticated;
  ```
  *الأثر الأمني:* يُمنع أي مستخدم من إدراج (`INSERT`) أو حذف (`DELETE`) أي إشعار مباشرة عبر واجهة API؛ كما يُمنع العميل برمجياً من تعديل أي عمود بخلاف `is_read`.

#### 3. مشغل مناعة البيانات التلقائي (`trg_enforce_notification_immutability`):
- دالة `enforce_notification_immutability()` تفحص عند أي محاولة تعديل ما إذا كان هناك أي اختلاف في الحقول:
  `id`, `user_id`, `title`, `body`, `type`, `related_booking_id`, `created_at`.
- في حال تعديل أي حقل بخلاف `is_read` يتم إطلاق استثناء فوري وإلغاء المعاملة.

---

## 3. تدقيق سياسات الأمان المجهزة في المشروع (`005_rls_policies.sql`)

يحتوي ملف الترحيل `005_rls_policies.sql` على منظومة متكاملة من سياسات RLS لكافة الجداول الـ 15 المتبقية. فيما يلي تفصيل هذه السياسات تمهيداً لاعتمادها:

### 3.1 جدول `profiles`
- `profiles_select`: مسموح للمستخدم بقراءة ملفه الخاص `id = auth.uid()`، أو للمشرف `is_admin()`.
- `profiles_update`: مسموح بتعديل الحساب الشخصي فقط، مع حماية حقل `role` عبر المشغل `protect_profile_role`.
- `profiles_delete`: مقتصر حصراً على المشرف العام `is_admin()`.

### 3.2 جدول `provider_profiles`
- `provider_profiles_select`: مسموح للعامة بقراءة ملفات المزودين المعتمدين فقط (`status = 'approved'`)، بينما يرى المزود ملفه حتى لو كان معلقاً، ويرى الأدمن كافة الملفات.
- `provider_profiles_insert`: مقتصر على صاحب الحساب نفسه مع تقييد الحالة الأولية إلى `pending`.
- `provider_profiles_update`: للمزود لتعديل بياناته العامة، ولا يمكنه تغيير `status` إلى `approved`.
- `provider_profiles_delete`: مقتصر على المشرف.

### 3.3 جدول `services` و `service_images`
- `services_select`: مسموح لجميع المستخدمين بقراءة الخدمات المفعلة (`status = 'active'`)، ومسموح للمزود بقراءة خدماته كافة مهما كانت حالتها.
- `services_insert`: مسموح حصراً للمزود المعتمد (`provider_id = get_my_provider_id()`).
- `services_update` / `delete`: مسموح لمزود الخدمة المالك فقط أو المشرف.

### 3.4 جدول `bookings` و `booking_items`
- `bookings_select`: مسموح للعميل صاحب الحجز (`customer_id = auth.uid()`)، أو لمقدم الخدمة إذا كان الحجز يتضمن إحدى خدماته عبر:
  ```sql
  EXISTS (
    SELECT 1 FROM public.booking_items bi
    JOIN public.services s ON s.id = bi.service_id
    WHERE bi.booking_id = bookings.id 
      AND s.provider_id = public.get_my_provider_id()
  )
  ```
- `bookings_insert`: يفضل قفل الإدراج المباشر واعتماد دالة `create_booking_atomic` لضمان الذرية.
- `bookings_update`: مقيد بالقواعد المنصوص عليها في مشغل `validate_booking_update`.
- `booking_items_update`: مقيد بمشغل `restrict_booking_item_update` لمنع تعديل الأسعار أو الكميات.

### 3.5 جداول `reviews` و `complaints` و `favorites`
- `reviews_insert`: مسموح للعميل الذي لديه حجز مكتمل للخدمة.
- `favorites_all`: مسموح للمستخدم فقط بإدارة مفضلته الخاصة (`user_id = auth.uid()`).
- `complaints_select`: مسموح لمقدم الشكوى أو الموظف المكلف بها أو المشرف.

---

## 4. أمان الدوال المخزنة والمشغلات (Stored Procedures & Triggers Hardening)

تعتمد قاعدة بيانات خِدمتي على مبادئ أمنية متقدمة في كتابة الدوال:

### 4.1 عزل مسار البحث (Search Path Hijacking Protection)
جميع الدوال المصرحة بصلاحية `SECURITY DEFINER` مزودة صراحة بضبط المسار:
```sql
SET search_path = public, pg_temp
```
*الأثر الأمني:* يمنع هذا السطر ثغرات حقن الكائنات المؤقتة الخبيثة (Schema Hijacking Attacks) التي يمكن للمهاجم من خلالها استبدال دوال قياسية بكائنات في مخططه الخاص لتنفيذ أوامر بصلاحيات الدالة المعرفة (`postgres`).

### 4.2 كسر حلقات التكرار المفرغة (Breaking RLS Recursion)
- تم تصميم دالة `is_admin()` ودالة `get_my_provider_id()` لتعمل كـ `SECURITY DEFINER` ومستقرة `STABLE`.
- هذا التصميم يمنع حدوث خطأ التكرار اللانهائي (Infinite Recursion) عند استعلام جداول `profiles` داخل سياسات RLS الخاصة بها.

### 4.3 حماية الأدوار ومنع تصعيد الصلاحيات (Role Escalation Guard)
مشغل `protect_profile_role` على جدول `profiles`:
```sql
IF NEW.role IS DISTINCT FROM OLD.role THEN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'غير مصرح: لا تملك صلاحية تعديل دور الحساب.';
  END IF;
END IF;
```
*الأثر الأمني:* يضمن ألا يستطيع أي عميل إرسال طلب تحديث لتغيير دوره من `customer` إلى `admin` أو `provider` مباشرة عبر واجهة Supabase REST API.

### 4.4 تجميد وحماية الأسعار ومنع التلاعب بالمدفوعات
- دالة `create_booking_atomic` **لا تثق نهائياً** في الأسعار أو الإجماليات المرسلة من تطبيق الهاتف أو المتصفح.
- تستعلم الدالة عن السعر الرسمي المعتمد من جدول `services` داخل قاعدة البيانات مباشرة، وتضرب السعر في الكمية وتجمع المجموع الإجمالي في متغير داخلي معزول قبل إدراجه في جدول `bookings` و `booking_items`.

---

## 5. خطة التفعيل الآمن لسياسات RLS (Remediation Roadmap)

لتفعيل RLS على الجداول الـ 15 المتبقية دون التسبب في انقطاع الخدمة أو أخطاء صلاحيات في التطبيق:

### المرحلة 1: التدقيق المسبق للواجهات
التأكد من أن جميع استعلامات قراءة الكتالوج العام (التصنيفات والخدمات) متوافقة مع قراءة المستخدم المسجل (`authenticated`)، أو منح صلاحية `anon` للخدمات العامة النشطة.

### المرحلة 2: تطبيق تفعيل RLS التدريجي
يتم تنفيذ التفعيل على مرحلتين:
1. تفعيل RLS على جداول البيانات الحساسة أولاً (`profiles`, `bookings`, `booking_items`, `complaints`).
2. تفعيل RLS على جداول المحتوى المعروض (`categories`, `services`, `service_images`).

### كود المعالجة الموصى به:
```sql
-- 1. تفعيل RLS على الجداول
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
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;

-- 2. تطبيق سياسات الوصول من ملف 005_rls_policies.sql
```
*(ملاحظة: وفقاً لتعليمات المستخدم الصارمة، لم يتم تنفيذ أي أمر تغييري على قاعدة البيانات الحية، وتم توثيق الكود والخطوات بالكامل ليتسنى لفريق العمل مراجعته وتنفيذه في الوقت المناسب).*
