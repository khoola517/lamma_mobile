import 'package:flutter_test/flutter_test.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/reviews/data/models/review_model.dart';
import 'package:khadematy/features/reviews/presentation/controllers/reviews_controller.dart';
import 'package:khadematy/features/reviews/domain/repositories/reviews_repository.dart';

class MockReviewsRepository implements ReviewsRepository {
  List<ReviewModel> reviews = [];

  @override
  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    return reviews;
  }

  @override
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  }) async {
    reviews.add(
      ReviewModel(
        id: 'test-id',
        serviceId: serviceId,
        customerId: 'customer-1',
        customerName: 'أحمد',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
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
  });
}
