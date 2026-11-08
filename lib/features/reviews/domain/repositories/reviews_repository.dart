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

  /// يتحقق مما إذا كان المستخدم الحالي لديه حجز فعلي (غير ملغي) لهذه الخدمة
  Future<bool> hasUserBookedService(String serviceId);

  /// يجلب معرّف الحجز الخاص بالمستخدم لهذه الخدمة إن وجد
  Future<String?> getUserBookingIdForService(String serviceId);

  /// يتحقق مما إذا كان المستخدم قد قيّم هذه الخدمة مسبقاً
  Future<bool> hasUserReviewedService(String serviceId);

  RealtimeSubscriptionToken subscribeToServiceReviews({
    required String serviceId,
    required void Function() onData,
    void Function()? onResync,
  });
}
