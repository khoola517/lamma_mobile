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
  Future<List<ServiceItemModel>> getFavoriteServices();
  Future<bool> isFavorite(String serviceId);
}
