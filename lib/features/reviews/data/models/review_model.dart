class ReviewModel {
  final String id;
  final String serviceId;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String? bookingId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    String name = 'مستخدم خِدمتي';
    String? avatar;

    if (json['customer'] is Map) {
      final customer = json['customer'] as Map<String, dynamic>;
      name = (customer['full_name'] as String?)?.trim().isNotEmpty == true
          ? customer['full_name'] as String
          : name;
      avatar = customer['avatar_url'] as String?;
    } else if (json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      name = (profile['full_name'] as String?)?.trim().isNotEmpty == true
          ? profile['full_name'] as String
          : name;
      avatar = profile['avatar_url'] as String?;
    }

    return ReviewModel(
      id: json['id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      customerName: name,
      customerAvatar: avatar,
      bookingId: json['booking_id'] as String?,
      rating: ((json['rating'] ?? 5) as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'customer_id': customerId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgoArabic {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? "شهر" : "أشهر"}';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? "أسبوع" : "أسابيع"}';
    } else if (diff.inDays >= 1) {
      return diff.inDays == 1 ? 'أمس' : 'منذ ${diff.inDays} أيام';
    } else if (diff.inHours >= 1) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inMinutes >= 1) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
