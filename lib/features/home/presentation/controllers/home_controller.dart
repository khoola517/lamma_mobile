import 'package:flutter/material.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_item_model.dart';
import '../../data/repositories/supabase_services_repository.dart';
import '../../domain/repositories/services_repository.dart';

enum HomeStatus { initial, loading, success, error }

class HomeController extends ChangeNotifier {
  final ServicesRepository _repository;
  final List<RealtimeSubscriptionToken> _realtimeTokens = [];

  HomeController({ServicesRepository? repository})
      : _repository = repository ?? SupabaseServicesRepository() {
    _initRealtime();
  }

  void _initRealtime() {
    // 1. الاستماع لتحديثات التصنيفات لحظياً عبر المستودع
    _realtimeTokens.add(
      _repository.subscribeToCategories(
        onData: _reloadCategories,
        onResync: loadHomeData,
      ),
    );

    // 2. الاستماع لتحديثات الخدمات لحظياً (إضافة، تعديل، إيقاف، حذف) عبر المستودع
    _realtimeTokens.add(
      _repository.subscribeToServices(
        onData: _reloadServices,
        onResync: loadHomeData,
      ),
    );

    // 3. إعادة المزامنة عند استعادة الاتصال
    _realtimeTokens.add(
      SupabaseRealtimeService.instance.onReconnected(() {
        loadHomeData();
      }),
    );
  }

  Future<void> _reloadCategories() async {
    try {
      final updated = await _repository.getCategories();
      _categories = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime reload categories error: $e');
    }
  }

  Future<void> _reloadServices() async {
    try {
      final updated = await _repository.getAllServices();
      _allServices = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime reload services error: $e');
    }
  }

  HomeStatus _status = HomeStatus.initial;
  List<CategoryModel> _categories = [];
  List<ServiceItemModel> _allServices = [];
  String? _errorMessage;

  HomeStatus get status => _status;
  List<CategoryModel> get categories => _categories;
  List<ServiceItemModel> get allServices => _allServices;
  String? get errorMessage => _errorMessage;

  List<ServiceItemModel> get venues => _allServices
      .where((s) => s.category.contains('قاع') || s.category == 'قاعة')
      .toList();

  List<ServiceItemModel> get photographers => _allServices
      .where((s) =>
          s.category.contains('تصوير') ||
          s.category.contains('صور') ||
          s.category == 'مصور/ة')
      .toList();

  List<ServiceItemModel> get cakes => _allServices
      .where((s) =>
          s.category.contains('كيك') ||
          s.category.contains('حلوي') ||
          s.category == 'كيك')
      .toList();

  List<ServiceItemModel> get kosha => _allServices
      .where((s) =>
          s.category.contains('كوش') ||
          s.category.contains('ديكور') ||
          s.category == 'كوشات')
      .toList();

  List<ServiceItemModel> get flowers => _allServices
      .where((s) =>
          s.category.contains('زهر') ||
          s.category.contains('ورد') ||
          s.category.contains('هدايا') ||
          s.category == 'بوكيهات')
      .toList();

  List<ServiceItemModel> get singers => _allServices
      .where((s) =>
          s.category.contains('منشد') ||
          s.category.contains('موسيق') ||
          s.category == 'منشد/ة')
      .toList();

  List<ServiceItemModel> get restHouses => _allServices
      .where((s) =>
          s.category.contains('استراح') ||
          s.category.contains('شاليه') ||
          s.category == 'استراحة')
      .toList();

  Future<void> loadHomeData() async {
    _status = HomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getAllServices(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _allServices = results[1] as List<ServiceItemModel>;
      _status = HomeStatus.success;
    } catch (e, stack) {
      debugPrint('HomeController Error loading home data: $e');
      debugPrint(stack.toString());
      _status = HomeStatus.error;
      final rawError = e.toString().replaceAll('Exception: ', '');
      if (rawError.contains('SocketException') ||
          rawError.contains('ClientException') ||
          rawError.contains('Failed host lookup') ||
          rawError.contains('Network is unreachable') ||
          rawError.contains('Connection refused') ||
          rawError.contains('HandshakeException')) {
        _errorMessage = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت وإعادة المحاولة.';
      } else if (rawError.contains('JWT') || rawError.contains('token') || rawError.contains('401')) {
        _errorMessage = 'انتهت صلاحية جلسة الدخول، يرجى تسجيل الدخول مجدداً.';
      } else {
        _errorMessage = 'فشل في تحميل بيانات الشاشة الرئيسية: $rawError';
      }
    }
    notifyListeners();
  }

  Future<bool> toggleFavorite(String serviceId) async {
    final index = _allServices.indexWhere((s) => s.id == serviceId);
    final currentStatus = index != -1 ? _allServices[index].isFavorite : false;
    final newStatus = !currentStatus;

    // تحديث فوري وسريع للواجهة
    if (index != -1) {
      _allServices[index] = _allServices[index].copyWith(
        isFavorite: newStatus,
      );
      notifyListeners();
    }

    try {
      if (newStatus) {
        await _repository.addFavorite(serviceId);
      } else {
        await _repository.removeFavorite(serviceId);
      }
      return newStatus;
    } catch (e) {
      // تراجع فوري عند حدوث خطأ
      if (index != -1) {
        _allServices[index] = _allServices[index].copyWith(
          isFavorite: currentStatus,
        );
        notifyListeners();
      }
      rethrow;
    }
  }

  void updateFavoriteStatus(String serviceId, bool isFavorite) {
    final index = _allServices.indexWhere((s) => s.id == serviceId);
    if (index != -1 && _allServices[index].isFavorite != isFavorite) {
      _allServices[index] = _allServices[index].copyWith(
        isFavorite: isFavorite,
      );
      notifyListeners();
    }
  }

  Future<List<ServiceItemModel>> getServicesByCategoryId(String categoryId) async {
    return _repository.getServicesByCategoryId(categoryId);
  }

  @override
  void dispose() {
    for (final token in _realtimeTokens) {
      token.cancel();
    }
    _realtimeTokens.clear();
    super.dispose();
  }
}
