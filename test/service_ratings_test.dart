import 'package:flutter_test/flutter_test.dart';
import 'package:khadematy/core/services/supabase_realtime_service.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/reviews/data/models/review_model.dart';
import 'package:khadematy/features/reviews/presentation/controllers/reviews_controller.dart';
import 'package:khadematy/features/reviews/domain/repositories/reviews_repository.dart';

class MockReviewsRepository implements ReviewsRepository {
  List<ReviewModel> reviews = [];
  Set<String> bookedServiceIds = {};
  Map<String, String> serviceBookingMap = {};

  @override
  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    return reviews;
  }

  @override
  Future<bool> hasUserBookedService(String serviceId) async {
    return bookedServiceIds.contains(serviceId);
  }

  @override
  Future<String?> getUserBookingIdForService(String serviceId) async {
    return serviceBookingMap[serviceId];
  }

  @override
  Future<bool> hasUserReviewedService(String serviceId) async {
    return reviews.any((r) => r.serviceId == serviceId);
  }

  @override
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  }) async {
    final validBookingId = bookingId ?? serviceBookingMap[serviceId];
    if (validBookingId == null) {
      throw Exception('عذراً، التقييم متاح فقط للعملاء الذين قاموا بحجز هذه الخدمة مسبقاً.');
    }

    reviews.add(
      ReviewModel(
        id: 'test-id',
        serviceId: serviceId,
        customerId: 'customer-1',
        customerName: 'أحمد',
        bookingId: validBookingId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  RealtimeSubscriptionToken subscribeToServiceReviews({
    required String serviceId,
    required void Function() onData,
    void Function()? onResync,
  }) {
    return const RealtimeSubscriptionToken(
      channelKey: 'test_reviews',
      listenerId: 'test_5',
    );
  }
}

void main() {
  group('Service Rating & Reviews Tests', () {
    test('ServiceItemModel parses rating and reviews_count correctly from Supabase JSON', () {
      final json = {
        'id': 'svc-123',
        'name': 'قاعة الملوك',
        'category': 'قاعات المناسبات',
        'location': 'المكلا',
        'price': 150000,
        'rating': 4.7,
        'reviews_count': 12,
        'image_url': 'https://example.com/img.jpg',
        'capacity': 600,
        'occasions': ['زفاف', 'تخرج'],
        'working_hours': [
          {'day': 'الخميس', 'status': 'متاح', 'time': '24 ساعة'}
        ],
        'provider_profiles': {
          'address': 'حضرموت - المكلا - الديس',
        },
      };

      final model = ServiceItemModel.fromJson(json);

      expect(model.rating, 4.7);
      expect(model.reviewsCount, 12);
      expect(model.capacity, '600');
      expect(model.occasions, ['زفاف', 'تخرج']);
      expect(model.workingHours.length, 1);
      expect(model.workingHours.first['day'], 'الخميس');
      expect(model.address, 'حضرموت - المكلا - الديس');
    });

    test('ServiceItemModel has no static fallback defaults when fields are missing', () {
      final json = {
        'id': 'svc-empty',
        'name': 'خدمة جديدة',
      };

      final model = ServiceItemModel.fromJson(json);

      expect(model.rating, 0.0);
      expect(model.reviewsCount, 0);
      expect(model.location, '');
      expect(model.capacity, isNull);
      expect(model.description, '');
      expect(model.occasions, isEmpty);
      expect(model.workingHours, isEmpty);
      expect(model.address, isNull);
    });

    test('ReviewsController accurately calculates averageRating and totalReviewsCount', () async {
      final repo = MockReviewsRepository();
      repo.reviews = [
        ReviewModel(
          id: '1',
          serviceId: 's1',
          customerId: 'c1',
          customerName: 'محمد',
          rating: 5,
          comment: 'ممتاز جداً',
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: '2',
          serviceId: 's1',
          customerId: 'c2',
          customerName: 'سعيد',
          rating: 4,
          comment: 'جيد ومرتب',
          createdAt: DateTime.now(),
        ),
      ];

      final controller = ReviewsController(repository: repo);
      await controller.loadServiceReviews('s1');

      expect(controller.totalReviewsCount, 2);
      expect(controller.averageRating, 4.5);
    });

    test('ReviewsController returns 0.0 averageRating when there are no reviews', () async {
      final repo = MockReviewsRepository();
      repo.reviews = [];

      final controller = ReviewsController(repository: repo);
      await controller.loadServiceReviews('s2');

      expect(controller.totalReviewsCount, 0);
      expect(controller.averageRating, 0.0);
    });

    test('Reviews restriction: Only user who booked service can submit review', () async {
      final repo = MockReviewsRepository();
      repo.bookedServiceIds.add('service-booked');
      repo.serviceBookingMap['service-booked'] = 'booking-123';

      final controller = ReviewsController(repository: repo);

      // 1. User has booking -> Can review successfully
      final canReviewId = await controller.checkUserBookingEligibility('service-booked');
      expect(canReviewId, 'booking-123');

      final success = await controller.submitReview(
        serviceId: 'service-booked',
        bookingId: canReviewId,
        rating: 5,
        comment: 'خدمة ممتازة وتجربة رائعة',
      );
      expect(success, isTrue);
      expect(controller.reviews.length, 1);
      expect(controller.reviews.first.bookingId, 'booking-123');

      // 2. User has NOT booked -> Submission fails and error is set
      final unbookedEligible = await controller.checkUserBookingEligibility('service-not-booked');
      expect(unbookedEligible, isNull);

      final failedSuccess = await controller.submitReview(
        serviceId: 'service-not-booked',
        rating: 4,
        comment: 'محاولة تقييم دون حجز',
      );
      expect(failedSuccess, isFalse);
      expect(controller.error, contains('التقييم متاح فقط للعملاء الذين قاموا بحجز هذه الخدمة'));
    });
  });
}
