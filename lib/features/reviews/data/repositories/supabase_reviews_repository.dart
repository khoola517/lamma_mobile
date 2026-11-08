import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../models/review_model.dart';

class SupabaseReviewsRepository implements ReviewsRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  @override
  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('''
            id,
            service_id,
            customer_id,
            booking_id,
            rating,
            comment,
            created_at,
            profiles(full_name, avatar_url)
          ''')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseReviewsRepository getServiceReviews error: $e');
      return [];
    }
  }

  @override
  Future<String?> getUserBookingIdForService(String serviceId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. استعلام الربط المباشر بين bookings و booking_items للتأكد من حجز هذه الخدمة
      final response = await _client
          .from('bookings')
          .select('id, status, booking_items!inner(service_id)')
          .eq('customer_id', user.id)
          .eq('booking_items.service_id', serviceId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['id'] as String?;
      }
    } catch (e) {
      debugPrint('SupabaseReviewsRepository getUserBookingIdForService error: $e');
    }

    // 2. فحص احتياطي عبر الاستعلام من booking_items وحجوزات العميل
    try {
      final myBookings = await _client
          .from('bookings')
          .select('id')
          .eq('customer_id', user.id)
          .neq('status', 'cancelled');

      if (myBookings.isNotEmpty) {
        final bookingIds = myBookings
            .map((b) => b['id'] as String)
            .toList();

        final items = await _client
            .from('booking_items')
            .select('booking_id')
            .eq('service_id', serviceId)
            .inFilter('booking_id', bookingIds)
            .limit(1);

        if (items.isNotEmpty) {
          return items.first['booking_id'] as String?;
        }
      }
    } catch (e) {
      debugPrint('SupabaseReviewsRepository fallback check error: $e');
    }

    return null;
  }

  @override
  Future<bool> hasUserBookedService(String serviceId) async {
    final bookingId = await getUserBookingIdForService(serviceId);
    return bookingId != null;
  }

  @override
  Future<bool> hasUserReviewedService(String serviceId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('reviews')
          .select('id')
          .eq('service_id', serviceId)
          .eq('customer_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('SupabaseReviewsRepository hasUserReviewedService error: $e');
      return false;
    }
  }

  @override
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً لإضافة تقييم وتعليق');
    }

    // التحقق الصارم من أن المستخدم قام بحجز الخدمة بالفعل
    String? resolvedBookingId = bookingId;
    if (resolvedBookingId == null || resolvedBookingId.isEmpty) {
      resolvedBookingId = await getUserBookingIdForService(serviceId);
    }

    if (resolvedBookingId == null || resolvedBookingId.isEmpty) {
      throw Exception('عذراً، التقييم متاح فقط للعملاء الذين قاموا بحجز هذه الخدمة مسبقاً.');
    }

    // إذا كان العميل قد قيّم الخدمة مسبقاً، يتم تحديث التقييم القائم بدلاً من التكرار
    final alreadyReviewed = await hasUserReviewedService(serviceId);
    if (alreadyReviewed) {
      await _client
          .from('reviews')
          .update({
            'booking_id': resolvedBookingId,
            'rating': rating,
            'comment': comment.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('service_id', serviceId)
          .eq('customer_id', user.id);
      return;
    }

    await _client.from('reviews').insert({
      'service_id': serviceId,
      'customer_id': user.id,
      'booking_id': resolvedBookingId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  @override
  RealtimeSubscriptionToken subscribeToServiceReviews({
    required String serviceId,
    required void Function() onData,
    void Function()? onResync,
  }) {
    return SupabaseRealtimeService.instance.subscribeToReviews(
      serviceId: serviceId,
      onData: (_) => onData(),
      onResync: onResync,
    );
  }
}
