# وثيقة المعمارية والتوثيق الشامل لتطبيق خِدمتي (Khidmati)

تم بناء وتطوير تطبيق **خِدمتي** كمنظومة متكاملة لحجز وإدارة خدمات المناسبات والأفراح، وفق معايير **Clean Architecture** مع نمط **Feature-First Structure**، متطابقاً بنسبة 100% مع الهوية البصرية وتصاميم **Stitch** المعتمدة (Project ID: `14752670688673387415`).

---

## 1. الهوية البصرية ونظام التصميم (Design System)

تم استخراج وتطبيق الهوية البصرية الملكية الفاخرة بدقة متناهية:
* **اللون الأساسي (Primary Burgundy):** `#651C32` (مع درجاته: الداكن `#481323`، الفاتح `#F4E7EB`، والناعم `#FAF3F5`).
* **الألوان الثانوية والذهبية (Champagne & Gold):** `#C8A96B` و `#F8CA27` و `#DE9B04`.
* **الخلفيات والأسطح (Surfaces & Backgrounds):** خلفية دافئة كريمية `#F7F3EC` وأسطح بيضاء نقية `#FFFFFF`.
* **النصوص (Typography):** خط **Cairo** العربي المتناسق لكافة العناوين والنصوص والأرقام، مع دعم كامل لاتجاه **RTL** من اليمين إلى اليسار.

---

## 2. معمارية المشروع وهيكل المجلدات (Clean Architecture - Feature First)

تم تنظيم المشروع داخل مجلد `lib/` وفق التقسيم التالي:

```text
lib/
├── main.dart                                   # نقطة انطلاق التطبيق وإعدادات شريط النظام
├── app/
│   ├── app.dart                               # ويدجت التطبيق الرئيسية وتطبيق الثيم واللغة
│   ├── di/
│   │   └── injection.dart                     # حقن الاعتماديات وتسجيل مزودي الحالة (Providers)
│   ├── routes/
│   │   └── app_routes.dart                    # نظام التوجيه والتنقل بين كافة الشاشات
│   └── theme/
│       └── app_theme.dart                     # الثيم المركزي وضبط الألوان والخطوط والأزرار
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                    # أكواد الألوان الدقيقة المستخرجة من Stitch
│   │   ├── app_typography.dart                # أحجام وأوزان خط Cairo المعتمدة
│   │   ├── app_strings.dart                   # النصوص والثوابت العربية لجميع الواجهات
│   │   └── app_assets.dart                    # روابط الصور والوسائط الخاصة بالشاشات
│   ├── utils/
│   │   ├── responsive.dart                    # كلاس Responsive التكيفي لجميع مقاسات الشاشات
│   │   └── currency_formatter.dart            # منسق العملات والأسعار (ر.ي و $)
│   └── widgets/
│       ├── custom_button.dart                 # زر موحد يدعم الحالات الأولية والثانوية والتحميل
│       ├── custom_text_field.dart             # حقل إدخال يدعم RTL وإظهار/إخفاء كلمة المرور
│       ├── service_card.dart                  # بطاقة الخدمة مع تقليب الصور وزر الإعجاب والتقييم
│       ├── empty_state_view.dart              # ويدجت مخصصة للبيانات الفارغة
│       ├── error_state_view.dart              # ويدجت مخصصة لمعالجة الأخطاء وإعادة المحاولة
│       └── loading_view.dart                  # مؤشر تحميل مخصص وفق الهوية
└── features/
    ├── onboarding/                            # ميزة الشاشات الترحيبية
    │   └── presentation/screens/
    │       └── onboarding_screen.dart         # الشاشات الترحيبية الثلاث ومؤشر التقدم
    ├── auth/                                  # ميزة المصادقة والحسابات
    │   ├── data/models/
    │   │   └── user_model.dart                # نموذج بيانات المستخدم
    │   ├── domain/repositories/
    │   │   └── auth_repository.dart           # مستودع المصادقة والعقد البرمجي
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_controller.dart       # إدارة حالة تسجيل الدخول وإنشاء الحساب
    │       └── screens/
    │           ├── login_screen.dart          # شاشة تسجيل الدخول
    │           └── register_screen.dart       # شاشة إنشاء حساب جديد
    ├── main_nav/                              # شريط التنقل السفلي الموحد
    │   └── presentation/screens/
    │       └── main_navigation_screen.dart    # القاعدة التنقلية لـ 5 تبويبات رئيسية
    ├── home/                                  # ميزة الشاشة الرئيسية
    │   ├── data/models/
    │   │   ├── category_model.dart            # نموذج التصنيفات
    │   │   └── service_item_model.dart        # نموذج تفاصيل الخدمات والقاعات
    │   ├── domain/repositories/
    │   │   └── services_repository.dart       # مستودع جلب الخدمات والبحث وتفضيل العناصر
    │   └── presentation/
    │       ├── controllers/
    │       │   └── home_controller.dart       # إدارة حالة الرئيسية والتصنيفات
    │       └── screens/
    │           └── home_screen.dart           # الشاشة الرئيسية بأقسامها وتصنيفاتها
    ├── explore/                               # ميزة الاستكشاف والبحث المتقدم
    │   └── presentation/screens/
    │       └── explore_screen.dart            # شاشة البحث مع الفلاتر الفورية
    ├── service_details/                       # ميزة تفاصيل الخدمة / القاعة
    │   └── presentation/screens/
    │       └── service_details_screen.dart    # تفاصيل القاعة، معرض الصور، المميزات، والسعر
    ├── smart_planning/                        # ميزة التخطيط الذكي وتخصيص الباقات
    │   ├── data/models/
    │   │   └── smart_plan_models.dart         # نماذج الخطة، توزيع الميزانية، وتخصيص الخدمات
    │   ├── domain/repositories/
    │   │   └── smart_planning_repository.dart # مستودع توليد الخطة بالذكاء الاصطناعي
    │   └── presentation/
    │       ├── controllers/
    │       │   └── smart_planning_controller.dart # إدارة حالة المدخلات، وتعديل وتخصيص الباقة
    │       └── screens/
    │           ├── smart_planning_input_screen.dart # إدخال بيانات المناسبة والتقويم التفاعلي
    │           ├── smart_plan_result_screen.dart    # عرض الخطة المقترحة والباقات الثلاث
    │           └── package_customization_screen.dart # إضافة/استبعاد الخدمات وحساب السعر لحظياً
    ├── bookings/                              # ميزة الحجوزات والطلبات
    │   ├── data/models/
    │   │   └── booking_model.dart             # نموذج الحجز وحالاته ومراحل التتبع
    │   └── presentation/
    │       ├── controllers/
    │       │   └── bookings_controller.dart   # إدارة وتصفية الحجوزات (الكل / انتظار / مكتملة)
    │       └── screens/
    │           ├── booking_date_screen.dart   # اختيار التاريخ، الفترة، وطريقة الدفع
    │           ├── booking_success_screen.dart# نجاح الطلب مع كود الحجز وزر التوجه للطلبات
    │           └── bookings_list_screen.dart  # قائمة طلباتي مع مسار تتبع المراحل (Stepper)
    ├── favorites/                             # ميزة المفضلة
    │   └── presentation/
    │       ├── controllers/
    │       │   └── favorites_controller.dart  # إدارة العناصر المحفوظة
    │       └── screens/
    │           └── favorites_screen.dart      # عرض المفضلة مع إمكانية الحذف السريع
    ├── notifications/                         # ميزة الإشعارات والتنبيهات
    │   └── presentation/
    │       ├── controllers/
    │       │   └── notifications_controller.dart # إدارة الإشعارات وتحديد المقروء
    │       └── screens/
    │           └── notifications_screen.dart  # قائمة الإشعارات وتحديثات الحجوزات
    ├── reviews/                               # ميزة التقييمات والتعليقات
    │   ├── data/
    │   │   ├── models/review_model.dart       # نموذج بيانات التقييم والمراجعة
    │   │   └── repositories/
    │   │       └── supabase_reviews_repository.dart # مستودع Supabase الحقيقي
    │   ├── domain/repositories/
    │   │   └── reviews_repository.dart        # عقد مستودع التقييمات
    │   └── presentation/
    │       ├── controllers/reviews_controller.dart # إدارة حالة التقييمات وإضافتها
    │       └── widgets/
    │           ├── review_item_card.dart      # بطاقة عرض تعليق العميل
    │           ├── add_review_bottom_sheet.dart # نافذة منبثقة لتقييم النجوم والتعليق
    │           └── reviews_section_widget.dart # قسم التقييمات المدمج في تفاصيل الخدمة
    └── support/                               # ميزة الشكاوى وخدمة العملاء
        ├── data/
        │   ├── models/complaint_model.dart    # نموذج بيانات الشكاوى والبلاغات
        │   └── repositories/
        │       └── supabase_support_repository.dart # مستودع Supabase الحقيقي
        ├── domain/repositories/
        │   └── support_repository.dart        # عقد مستودع الشكاوى والدعم
        └── presentation/
            ├── controllers/support_controller.dart # إدارة حالة البلاغات وإرسالها
            └── screens/
                └── support_screen.dart        # شاشة مركز المساعدة ورفع ومتابعة الشكاوى
```

---

## 3. التجاوب مع أحجام الشاشات (Responsive Architecture)

تم تلبية المتطلب رقم (13) بإنشاء كلاس تكيفي موحد `Responsive` في `lib/core/utils/responsive.dart`:
* يوفر دوال فحص الشاشة: `isMobile`, `isTablet`, `isDesktop`.
* يوفر محدد القياسات والتباعد التكيفي: `screenPadding`, `gridColumns`.
* يوفر `ResponsiveContainer` لحصر المحتوى بعرض أنيق ومريح حتى على الشاشات العريضة والحواسيب.
* يوفر `ResponsiveLayout` لبناء عناصر مختلفة بحسب نوع الجهاز.
* إضافة `extension` على `BuildContext` تمكن من استدعاء `context.isMobile` و `context.responsive` في أي مكان.

---

## 4. تدفق تجربة المستخدم (User Experience Flow)

1. **الترحيب (Onboarding):** 3 شاشات تبرز مزايا التطبيق (خدمات شاملة، موثوقية مقدمي الخدمة، وتخطيط ذكي) مع زر "تخطي" و "التالي" و "ابدأ الآن".
2. **المصادقة (Auth):** تسجيل الدخول بحقلين وتذكرني، مع شاشة إنشاء حساب تتضمن التحقق من صحة المدخلات.
3. **الرئيسية (Home):** ترحيب علوي، إشعارات، مربع بحث، عروض ترويجية متحركة، شبكة تصنيفات أفقية، وبطاقات مميزة لكل قسم (قاعات، مصورين، كيك، كوشات، منشدين، استراحات) مع إمكانية استعراض الصور بزرين سريعين داخل البطاقة.
4. **التخطيط الذكي (AI Smart Planner):**
   * إدخال نوع المناسبة، عدد الضيوف، الميزانية، المدينة، والخدمات المطلوبة مع تقويم تفاعلي.
   * حساب الخطة وتوزيع الميزانية التقديري مع إبراز 3 باقات (اقتصادية، متوسطة "الأكثر اختياراً"، فاخرة).
   * شاشة **تخصيص الباقة** التفاعلية: يمكن للمستخدم تفعيل أو استبعاد أي خدمة (تصوير، ديكور، كيك، ورد، صوتيات) مع تحديث السعر الإجمالي في الأسفل بشكل فوري ولحظي.
5. **تأكيد الحجز (Booking):** اختيار التاريخ والفترة (صباحية/مسائية)، إدخال ملاحظات خاصة، والحصول على كود حجز فريد (`#KH-84920`).
6. **متابعة الطلبات (My Bookings):** تبويبات لتصفية الحجوزات (الكل، قيد الانتظار، المكتملة) مع مسار تتبع بصري (Stepper) يوضح مرحلة الطلب.
7. **المفضلة والحساب:** استعراض الخدمات المحفوظة وإدارة الملف الشخصي والإعدادات.

---

## 5. إدارة الحالة وجودة الكود (State Management & Clean Code)

* استخدام **Provider** مع `ChangeNotifier` مفصول لكل ميزة.
* معالجة الحالات الأربع الأساسية: **Loading**, **Success**, **Empty**, **Error**.
* عزل منطق الأعمال (Business Logic) ومصادر البيانات (Data Sources/Repositories) عن واجهات العرض (UI).
* دعم كامل للـ Null Safety والتعامل الآمن مع القيم الاختيارية.
