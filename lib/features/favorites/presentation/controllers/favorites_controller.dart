import 'package:flutter/material.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../../home/data/models/service_item_model.dart';
import '../../../home/data/repositories/supabase_services_repository.dart';
import '../../../home/domain/repositories/services_repository.dart';

class FavoritesController extends ChangeNotifier {
  final ServicesRepository _repository;
  List<ServiceItemModel> _favoriteServices = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool? _lastAuthStatus;
  final List<RealtimeSubscriptionToken> _realtimeTokens = [];

  FavoritesController({ServicesRepository? repository})
      : _repository = repository ?? SupabaseServicesRepository();

  List<ServiceItemModel> get favoriteServices => _favoriteServices;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isEmpty => _favoriteServices.isEmpty;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String serviceId) {
    return _favoriteIds.contains(serviceId);
  }

  void seedFavorites(Iterable<String> ids) {
    if (!_isInitialized) {
      _favoriteIds.addAll(ids);
      notifyListeners();
    }
  }

  void onAuthChanged(bool isAuthenticated) {
    if (_lastAuthStatus != isAuthenticated) {
      _lastAuthStatus = isAuthenticated;
      if (isAuthenticated) {
        _subscribeToFavoritesRealtime();
        loadFavorites();
      } else {
        _unsubscribeRealtime();
        _favoriteServices = [];
        _favoriteIds.clear();
        _isInitialized = false;
        _errorMessage = null;
        notifyListeners();
      }
    }
  }

  void _subscribeToFavoritesRealtime() {
    _unsubscribeRealtime();
    if (!SupabaseConfig.hasClient) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeTokens.add(
      _repository.subscribeToFavorites(
        userId: userId,
        onData: () => loadFavorites(silent: true),
        onResync: () => loadFavorites(silent: true),
      ),
    );

    _realtimeTokens.add(
      SupabaseRealtimeService.instance.onReconnected(() {
        loadFavorites(silent: true);
      }),
    );
  }

  void _unsubscribeRealtime() {
    for (final token in _realtimeTokens) {
      token.cancel();
    }
    _realtimeTokens.clear();
  }

  Future<void> loadFavorites({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final items = await _repository.getFavoriteServices();
      _favoriteServices = items;
      _favoriteIds.clear();
      for (final item in items) {
        _favoriteIds.add(item.id);
      }
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String serviceId) async {
    final index = _favoriteServices.indexWhere((s) => s.id == serviceId);
    final removedItem = index != -1 ? _favoriteServices[index] : null;

    // 1. التحديث الفوري محلياً (Optimistic UI)
    if (index != -1) {
      _favoriteServices.removeAt(index);
    }
    _favoriteIds.remove(serviceId);
    notifyListeners();

    try {
      // 2. الحذف الصريح من السحابة بدون الوقوع في خطأ الـ Toggle
      await _repository.removeFavorite(serviceId);
    } catch (e) {
      // التراجع عند الفشل
      if (removedItem != null && index != -1) {
        _favoriteServices.insert(index, removedItem);
      }
      _favoriteIds.add(serviceId);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> toggleFavorite(ServiceItemModel service) async {
    final wasFav = isFavorite(service.id);
    final index = _favoriteServices.indexWhere((s) => s.id == service.id);

    // 1. التحديث الفوري محلياً (Optimistic UI)
    if (wasFav) {
      _favoriteIds.remove(service.id);
      _favoriteServices.removeWhere((s) => s.id == service.id);
    } else {
      _favoriteIds.add(service.id);
      _favoriteServices.insert(0, service.copyWith(isFavorite: true));
    }
    notifyListeners();

    try {
      // 2. استدعاء السحابة المناسب بناءً على الحالة
      if (wasFav) {
        await _repository.removeFavorite(service.id);
      } else {
        await _repository.addFavorite(service.id);
      }
      return !wasFav;
    } catch (e) {
      // التراجع عند الفشل
      if (wasFav) {
        _favoriteIds.add(service.id);
        if (index != -1) {
          _favoriteServices.insert(index, service.copyWith(isFavorite: true));
        }
      } else {
        _favoriteIds.remove(service.id);
        _favoriteServices.removeWhere((s) => s.id == service.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  void addFavoriteLocally(ServiceItemModel service) {
    _favoriteIds.add(service.id);
    if (!_favoriteServices.any((s) => s.id == service.id)) {
      _favoriteServices.insert(0, service.copyWith(isFavorite: true));
    }
    notifyListeners();
  }

  void removeFavoriteLocally(String serviceId) {
    _favoriteIds.remove(serviceId);
    _favoriteServices.removeWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }
}
