import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/review_model.dart';

abstract class ReviewsRepository {
  Future<List<ReviewModel>> getServiceReviews(String serviceId);
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  });

  RealtimeSubscriptionToken subscribeToServiceReviews({
    required String serviceId,
    required void Function() onData,
    void Function()? onResync,
  });
}
