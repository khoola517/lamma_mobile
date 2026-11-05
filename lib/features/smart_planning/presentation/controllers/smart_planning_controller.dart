import 'package:flutter/material.dart';
import '../../../home/data/models/category_model.dart';
import '../../data/models/smart_plan_models.dart';
import '../../data/repositories/supabase_smart_planning_repository.dart';
import '../../domain/repositories/smart_planning_repository.dart';

enum SmartPlanStatus { initial, loading, success, error }

class SmartPlanningController extends ChangeNotifier {
  final SmartPlanningRepository _repository;

  SmartPlanningController({SmartPlanningRepository? repository})
      : _repository = repository ?? SupabaseSmartPlanningRepository() {
    _request = SmartPlanRequest(
      eventDate: DateTime.now().add(const Duration(days: 14)),
      budget: 500000,
      guestsCount: 50,
      location: 'المكلا',
    );
  }

  SmartPlanStatus _status = SmartPlanStatus.initial;
  late SmartPlanRequest _request;
  SmartPlanResult? _result;
  String? _errorMessage;

  // Categories fetched from Supabase
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;

  // Selected package
  String _selectedPackageId = 'pkg_std';

  // State for saved package in Supabase (persisted after selection)
  String? _savedPackageId;
  bool _isSavingPackage = false;
  String? _saveSuccessMessage;

  // Customizable services list and total price
  List<CustomizableServiceItem> _customizableServices = [];
  num _customPackageTotal = 500000;

  SmartPlanStatus get status => _status;
  SmartPlanRequest get request => _request;
  SmartPlanResult? get result => _result;
  String? get errorMessage => _errorMessage;
  List<CategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String get selectedPackageId => _selectedPackageId;
  String? get savedPackageId => _savedPackageId;
  bool get isSavingPackage => _isSavingPackage;
  String? get saveSuccessMessage => _saveSuccessMessage;

  PackageOption? get selectedPackage {
    if (_result == null) return null;
    return _result!.packages.firstWhere(
      (p) => p.id == _selectedPackageId,
      orElse: () => _result!.packages.first,
    );
  }

  List<CustomizableServiceItem> get customizableServices =>
      _customizableServices;
  num get customPackageTotal => _customPackageTotal;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    _isLoadingCategories = true;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
    } catch (_) {
      // Fallback if needed
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void updateEventType(String type) {
    _request = _request.copyWith(eventType: type);
    notifyListeners();
  }

  void updateGuestsCount(int count) {
    _request = _request.copyWith(guestsCount: count);
    notifyListeners();
  }

  void updateBudget(num budget) {
    _request = _request.copyWith(budget: budget);
    notifyListeners();
  }

  void updateLocation(String location) {
    _request = _request.copyWith(location: location);
    notifyListeners();
  }

  void updateDate(DateTime date) {
    _request = _request.copyWith(eventDate: date);
    notifyListeners();
  }

  void toggleRequestedService(String service) {
    final list = List<String>.from(_request.requestedServices);
    if (list.contains(service)) {
      list.remove(service);
    } else {
      list.add(service);
    }
    _request = _request.copyWith(requestedServices: list);
    notifyListeners();
  }

  void selectPackage(String packageId) {
    _selectedPackageId = packageId;
    if (_result != null) {
      if (_result!.packageServicesMap.containsKey(packageId)) {
        _customizableServices =
            List.from(_result!.packageServicesMap[packageId]!);
      }
      _recalculateTotal();
    }
    notifyListeners();
  }

  Future<bool> generatePlan() async {
    _status = SmartPlanStatus.loading;
    _errorMessage = null;
    // عند إنشاء خطة: لا يتم حفظ أي بيانات في قاعدة البيانات (Read-Only Preview)
    _savedPackageId = null;
    _saveSuccessMessage = null;
    notifyListeners();

    try {
      _result = await _repository.generatePlan(_request);
      final defaultPkg = _result!.packages.firstWhere(
        (p) => p.isFeatured,
        orElse: () => _result!.packages.first,
      );
      _selectedPackageId = defaultPkg.id;

      if (_result!.packageServicesMap.containsKey(defaultPkg.id)) {
        _customizableServices =
            List.from(_result!.packageServicesMap[defaultPkg.id]!);
      } else {
        _customizableServices = List.from(_result!.customizableServices);
      }

      _recalculateTotal();
      _status = SmartPlanStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = SmartPlanStatus.error;
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _errorMessage =
          msg.isNotEmpty ? msg : 'تعذر إنشاء الخطة الذكية، يرجى المحاولة لاحقاً';
      notifyListeners();
      return false;
    }
  }

  /// حفظ الباقة المختارة مع كامل تفاصيلها وخدماتها في قاعدة البيانات
  Future<String?> saveSelectedPackage({String? customerId}) async {
    if (_result == null) return null;
    final pkg = selectedPackage;
    if (pkg == null) return null;

    _isSavingPackage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedId = await _repository.saveSelectedPackage(
        request: _request,
        package: pkg,
        services: _customizableServices,
        existingPackageId: _savedPackageId,
        customerId: customerId,
      );
      _savedPackageId = savedId;
      _saveSuccessMessage = 'تم حفظ ${pkg.name} مع تفاصيلها بنجاح';
      _isSavingPackage = false;
      notifyListeners();
      return savedId;
    } catch (e) {
      _isSavingPackage = false;
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      _errorMessage = msg.isNotEmpty ? msg : 'تعذر حفظ الباقة المختارة';
      notifyListeners();
      rethrow;
    }
  }

  void toggleCustomService(String serviceId) {
    final index = _customizableServices.indexWhere((s) => s.id == serviceId);
    if (index != -1) {
      final item = _customizableServices[index];
      _customizableServices[index] =
          item.copyWith(isIncluded: !item.isIncluded);
      _recalculateTotal();
      notifyListeners();
    }
  }

  void _recalculateTotal() {
    num total = 0;
    for (var s in _customizableServices) {
      if (s.isIncluded) {
        total += s.price;
      }
    }
    _customPackageTotal = total;
  }
}

