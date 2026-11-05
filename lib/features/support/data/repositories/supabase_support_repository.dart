import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/repositories/support_repository.dart';
import '../models/complaint_model.dart';
import '../models/complaint_category_model.dart';

class SupabaseSupportRepository implements SupportRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  @override
  Future<List<ComplaintCategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('complaint_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final list = (response as List)
          .map((item) =>
              ComplaintCategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return ComplaintCategoryModel.defaultFallbackCategories;
      }
      return list;
    } catch (e) {
      debugPrint('SupabaseSupportRepository getCategories error: $e');
      // خط دفاعي: في حال حدث خطأ شبكة أو لم يتم تطبيق المايجريشن بعد، نرجع القائمة الافتراضية
      return ComplaintCategoryModel.defaultFallbackCategories;
    }
  }

  @override
  Future<List<ComplaintModel>> getMyComplaints() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final response = await _client
          .from('complaints')
          .select('''
            id,
            user_id,
            booking_id,
            category_id,
            subject,
            description,
            status,
            resolution,
            created_at,
            updated_at,
            bookings(booking_code),
            complaint_categories(name_ar, icon)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseSupportRepository getMyComplaints primary query error: $e');
      // خط دفاعي استباقي في حال عدم وجود جدول complaint_categories بعد
      try {
        final fallbackResponse = await _client
            .from('complaints')
            .select('''
              id,
              user_id,
              booking_id,
              subject,
              description,
              status,
              resolution,
              created_at,
              updated_at,
              bookings(booking_code)
            ''')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        return (fallbackResponse as List)
            .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e2) {
        debugPrint('SupabaseSupportRepository fallback getMyComplaints error: $e2');
        return [];
      }
    }
  }

  @override
  Future<void> submitComplaint({
    String? bookingId,
    String? categoryId,
    required String subject,
    required String category,
    required String description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً لتقديم شكوى أو بلاغ');
    }

    final hasValidUuidCategory =
        categoryId != null && categoryId.isNotEmpty && _isValidUuid(categoryId);

    // إذا لم يتوفر معرّف UUID حقيقي للتصنيف، ندمجه بالعنوان لضمان عدم ضياع التصنيف
    final formattedSubject = (!hasValidUuidCategory && category.isNotEmpty && category != 'عام')
        ? '[$category] $subject'
        : subject;

    final data = <String, dynamic>{
      'user_id': user.id,
      if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
      if (hasValidUuidCategory) 'category_id': categoryId,
      'subject': formattedSubject,
      'description': description.trim(),
      'status': 'pending',
    };

    await _client.from('complaints').insert(data);
  }

  bool _isValidUuid(String str) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(str);
  }
}
