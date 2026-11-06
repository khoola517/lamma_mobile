import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_item_model.dart';

abstract class ServicesRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<ServiceItemModel>> getAllServices();
  Future<List<ServiceItemModel>> getServicesByCategory(String category);
  Future<List<ServiceItemModel>> getServicesByCategoryId(String categoryId);
  Future<ServiceItemModel?> getServiceById(String id);
  Future<List<ServiceItemModel>> searchServices(String query,
      {String? category});
  Future<void> toggleFavorite(String serviceId);
  Future<void> addFavorite(String serviceId);
  Future<void> removeFavorite(String serviceId);
  Future<List<ServiceItemModel>> getFavoriteServices();
  Future<bool> isFavorite(String serviceId);

  RealtimeSubscriptionToken subscribeToCategories({
    required void Function() onData,
    void Function()? onResync,
  });

  RealtimeSubscriptionToken subscribeToServices({
    required void Function() onData,
    void Function()? onResync,
  });

  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  });
}
