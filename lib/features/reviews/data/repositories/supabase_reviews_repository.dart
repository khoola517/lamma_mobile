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

    await _client.from('reviews').insert({
      'service_id': serviceId,
      'customer_id': user.id,
      if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
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
