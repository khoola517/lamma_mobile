import 'package:flutter/material.dart';
import '../../domain/repositories/support_repository.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_category_model.dart';

class SupportController extends ChangeNotifier {
  final SupportRepository repository;

  SupportController({required this.repository}) {
    loadCategories();
  }

  List<ComplaintCategoryModel> _categories = [];
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;
  String? _error;

  List<ComplaintCategoryModel> get categories => _categories;
  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  int get pendingCount =>
      _complaints.where((c) => c.status == ComplaintStatus.pending || c.status == ComplaintStatus.inReview).length;

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      final fetched = await repository.getCategories();
      _categories = fetched;
    } catch (e) {
      debugPrint('SupportController loadCategories error: $e');
      if (_categories.isEmpty) {
        _categories = ComplaintCategoryModel.defaultFallbackCategories;
      }
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadComplaints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _complaints = await repository.getMyComplaints();
    } catch (e) {
      _error = 'تعذر تحميل الشكاوى: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitComplaint({
    String? bookingId,
    String? categoryId,
    required String subject,
    required String category,
    required String description,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await repository.submitComplaint(
        bookingId: bookingId,
        categoryId: categoryId,
        subject: subject,
        category: category,
        description: description,
      );
      _complaints = await repository.getMyComplaints();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'تعذر إرسال الشكوى: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void onAuthChanged(bool isAuthenticated) {
    if (isAuthenticated) {
      loadCategories();
      loadComplaints();
    } else {
      _complaints = [];
      notifyListeners();
    }
  }
}
