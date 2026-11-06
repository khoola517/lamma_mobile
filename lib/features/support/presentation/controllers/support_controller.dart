import 'package:flutter/material.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../domain/repositories/support_repository.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_category_model.dart';

class SupportController extends ChangeNotifier {
  final SupportRepository repository;
  final List<RealtimeSubscriptionToken> _realtimeTokens = [];

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
      _subscribeToRealtime();
      loadCategories();
      loadComplaints();
    } else {
      _unsubscribeRealtime();
      _complaints = [];
      notifyListeners();
    }
  }

  void _subscribeToRealtime() {
    _unsubscribeRealtime();
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. مزامنة الشكاوى الخاصة بالمستخدم
    _realtimeTokens.add(
      repository.subscribeToUserComplaints(
        userId: userId,
        onData: loadComplaints,
        onResync: loadComplaints,
      ),
    );

    // 2. مزامنة تصنيفات الشكاوى
    _realtimeTokens.add(
      repository.subscribeToComplaintCategories(
        onData: loadCategories,
        onResync: loadCategories,
      ),
    );

    // 3. إعادة المزامنة عند استعادة الاتصال
    _realtimeTokens.add(
      SupabaseRealtimeService.instance.onReconnected(() {
        loadCategories();
        loadComplaints();
      }),
    );
  }

  void _unsubscribeRealtime() {
    for (final token in _realtimeTokens) {
      token.cancel();
    }
    _realtimeTokens.clear();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }
}
