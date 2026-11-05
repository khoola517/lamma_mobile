class ComplaintCategoryModel {
  final String id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? icon;
  final bool requiresBooking;
  final String defaultPriority;
  final int sortOrder;
  final bool isActive;

  const ComplaintCategoryModel({
    required this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.icon,
    this.requiresBooking = false,
    this.defaultPriority = 'medium',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ComplaintCategoryModel.fromJson(Map<String, dynamic> json) {
    return ComplaintCategoryModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      icon: json['icon'] as String?,
      requiresBooking: json['requires_booking'] as bool? ?? false,
      defaultPriority: json['default_priority'] as String? ?? 'medium',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
      'requires_booking': requiresBooking,
      'default_priority': defaultPriority,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  /// قائمة التصنيفات الافتراضية الاحتياطية عند انقطاع الاتصال
  static List<ComplaintCategoryModel> get defaultFallbackCategories => const [
        ComplaintCategoryModel(
          id: 'booking_issue',
          code: 'booking_issue',
          nameAr: 'مشكلة في الحجز',
          requiresBooking: true,
          defaultPriority: 'high',
          sortOrder: 1,
        ),
        ComplaintCategoryModel(
          id: 'service_mismatch',
          code: 'service_mismatch',
          nameAr: 'عدم مطابقة مواصفات الخدمة',
          requiresBooking: true,
          defaultPriority: 'high',
          sortOrder: 2,
        ),
        ComplaintCategoryModel(
          id: 'payment_refund',
          code: 'payment_refund',
          nameAr: 'مشكلة دفع أو استرجاع',
          requiresBooking: false,
          defaultPriority: 'urgent',
          sortOrder: 3,
        ),
        ComplaintCategoryModel(
          id: 'delay_or_conduct',
          code: 'delay_or_conduct',
          nameAr: 'تأخر أو سوء تعامل',
          requiresBooking: true,
          defaultPriority: 'medium',
          sortOrder: 4,
        ),
        ComplaintCategoryModel(
          id: 'technical_issue',
          code: 'technical_issue',
          nameAr: 'مشكلة تقنية بالتطبيق',
          requiresBooking: false,
          defaultPriority: 'medium',
          sortOrder: 5,
        ),
        ComplaintCategoryModel(
          id: 'other',
          code: 'other',
          nameAr: 'أخرى / استفسار عام',
          requiresBooking: false,
          defaultPriority: 'low',
          sortOrder: 6,
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplaintCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
