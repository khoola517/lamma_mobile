import '../../data/models/review_model.dart';

abstract class ReviewsRepository {
  Future<List<ReviewModel>> getServiceReviews(String serviceId);
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  });
}
