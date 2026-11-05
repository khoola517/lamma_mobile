import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_item_model.dart';
import '../../data/repositories/supabase_services_repository.dart';
import '../../domain/repositories/services_repository.dart';

enum HomeStatus { initial, loading, success, error }

class HomeController extends ChangeNotifier {
  final ServicesRepository _repository;

  HomeController({ServicesRepository? repository})
      : _repository = repository ?? SupabaseServicesRepository();

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

  Future<void> toggleFavorite(String serviceId) async {
    await _repository.toggleFavorite(serviceId);
    final index = _allServices.indexWhere((s) => s.id == serviceId);
    if (index != -1) {
      _allServices[index] = _allServices[index].copyWith(
        isFavorite: !_allServices[index].isFavorite,
      );
      notifyListeners();
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
}
