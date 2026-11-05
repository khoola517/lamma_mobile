import 'package:flutter/material.dart';
import '../../../home/data/models/service_item_model.dart';
import '../../../home/data/repositories/supabase_services_repository.dart';
import '../../../home/domain/repositories/services_repository.dart';

class FavoritesController extends ChangeNotifier {
  final ServicesRepository _repository;
  List<ServiceItemModel> _favoriteServices = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool? _lastAuthStatus;

  FavoritesController({ServicesRepository? repository})
      : _repository = repository ?? SupabaseServicesRepository();

  List<ServiceItemModel> get favoriteServices => _favoriteServices;
  bool get isLoading => _isLoading;
  bool get isEmpty => _favoriteServices.isEmpty;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String serviceId) {
    return _favoriteServices.any((s) => s.id == serviceId);
  }

  void onAuthChanged(bool isAuthenticated) {
    if (_lastAuthStatus != isAuthenticated) {
      _lastAuthStatus = isAuthenticated;
      if (isAuthenticated) {
        loadFavorites();
      } else {
        _favoriteServices = [];
        _errorMessage = null;
        notifyListeners();
      }
    }
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favoriteServices = await _repository.getFavoriteServices();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String serviceId) async {
    final index = _favoriteServices.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;

    final removedItem = _favoriteServices[index];
    _favoriteServices.removeAt(index);
    notifyListeners();

    try {
      await _repository.toggleFavorite(serviceId);
    } catch (e) {
      // Revert if API call fails
      _favoriteServices.insert(index, removedItem);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> toggleFavorite(ServiceItemModel service) async {
    final wasFav = isFavorite(service.id);
    final index = _favoriteServices.indexWhere((s) => s.id == service.id);

    if (wasFav) {
      _favoriteServices.removeWhere((s) => s.id == service.id);
    } else {
      _favoriteServices.insert(0, service.copyWith(isFavorite: true));
    }
    notifyListeners();

    try {
      await _repository.toggleFavorite(service.id);
      return !wasFav;
    } catch (e) {
      // Revert
      if (wasFav && index != -1) {
        _favoriteServices.insert(index, service.copyWith(isFavorite: true));
      } else {
        _favoriteServices.removeWhere((s) => s.id == service.id);
      }
      notifyListeners();
      rethrow;
    }
  }
}
