import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum ComplaintStatus {
  pending,
  inReview,
  resolved,
  closed,
}

class ComplaintModel {
  final String id;
  final String userId;
  final String? bookingId;
  final String? bookingCode;
  final String? categoryId;
  final String? categoryName;
  final String subject;
  final String category;
  final String description;
  final ComplaintStatus status;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ComplaintModel({
    required this.id,
    required this.userId,
    this.bookingId,
    this.bookingCode,
    this.categoryId,
    this.categoryName,
    required this.subject,
    this.category = 'عام',
    required this.description,
    this.status = ComplaintStatus.pending,
    this.resolution,
    required this.createdAt,
    this.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    String? bCode;
    if (json['bookings'] is Map) {
      bCode = json['bookings']['booking_code'] as String?;
    }

    String? catName;
    if (json['complaint_categories'] is Map) {
      catName = json['complaint_categories']['name_ar'] as String?;
    }

    return ComplaintModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      bookingCode: bCode,
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      subject: json['subject'] as String? ?? '',
      category: catName ?? json['category'] as String? ?? 'عام',
      description: json['description'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      resolution: json['resolution'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'category_id': categoryId,
      'subject': subject,
      'category': category,
      'description': description,
      'status': statusToString(status),
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static ComplaintStatus parseStatus(String? s) {
    switch (s) {
      case 'in_review':
        return ComplaintStatus.inReview;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      case 'pending':
      default:
        return ComplaintStatus.pending;
    }
  }

  static String statusToString(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.inReview:
        return 'in_review';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.closed:
        return 'closed';
      case ComplaintStatus.pending:
        return 'pending';
    }
  }

  String get statusArabic {
    switch (status) {
      case ComplaintStatus.pending:
        return 'قيد الانتظار';
      case ComplaintStatus.inReview:
        return 'قيد المراجعة';
      case ComplaintStatus.resolved:
        return 'تم الحل بنجاح';
      case ComplaintStatus.closed:
        return 'مغلقة';
    }
  }

  Color get statusColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.warning;
      case ComplaintStatus.inReview:
        return AppColors.brandGold;
      case ComplaintStatus.resolved:
        return AppColors.success;
      case ComplaintStatus.closed:
        return AppColors.textTertiary;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.warningContainer;
      case ComplaintStatus.inReview:
        return AppColors.champagneLight;
      case ComplaintStatus.resolved:
        return AppColors.successContainer;
      case ComplaintStatus.closed:
        return AppColors.surfaceSection;
    }
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
