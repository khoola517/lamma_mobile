import 'package:flutter/material.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../data/models/review_model.dart';

class ReviewsController extends ChangeNotifier {
  final ReviewsRepository repository;

  ReviewsController({required this.repository});

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _activeServiceId;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get activeServiceId => _activeServiceId;

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return double.parse((total / _reviews.length).toStringAsFixed(1));
  }

  int get totalReviewsCount => _reviews.length;

  Future<void> loadServiceReviews(String serviceId) async {
    _activeServiceId = serviceId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await repository.getServiceReviews(serviceId);
    } catch (e) {
      _error = 'تعذر تحميل التقييمات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await repository.submitReview(
        serviceId: serviceId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      // Reload reviews
      _reviews = await repository.getServiceReviews(serviceId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'تعذر إرسال التقييم: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
