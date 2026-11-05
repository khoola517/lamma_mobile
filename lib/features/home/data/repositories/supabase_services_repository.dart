import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/category_model.dart';
import '../models/service_item_model.dart';
import '../../domain/repositories/services_repository.dart';

class SupabaseServicesRepository implements ServicesRepository {
  final SupabaseClient _client;

  SupabaseServicesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ServiceItemModel>> getAllServices() async {
    final userId = _client.auth.currentUser?.id;

    // Fetch active services with categories and service images
    final response = await _client
        .from('services')
        .select('*, categories(name), service_images(image_url), provider_profiles(business_name, address)')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    Set<String> userFavorites = {};
    if (userId != null) {
      try {
        final favs = await _client
            .from('favorites')
            .select('service_id')
            .eq('user_id', userId);
        userFavorites = (favs as List)
            .map((f) => f['service_id'] as String)
            .toSet();
      } catch (e) {
        // إذا حدث خطأ في استعلام المفضلة نتجاوزه حتى لا يتعطل تحميل الخدمات
      }
    }

    return (response as List).map((e) {
      final model = ServiceItemModel.fromJson(e as Map<String, dynamic>);
      return model.copyWith(isFavorite: userFavorites.contains(model.id));
    }).toList();
  }

  @override
  Future<List<ServiceItemModel>> getServicesByCategoryId(String categoryId) async {
    final userId = _client.auth.currentUser?.id;

    // Fetch active services specifically belonging to this category using the foreign key
    final response = await _client
        .from('services')
        .select('*, categories(name), service_images(image_url), provider_profiles(business_name, address)')
        .eq('category_id', categoryId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    Set<String> userFavorites = {};
    if (userId != null) {
      try {
        final favs = await _client
            .from('favorites')
            .select('service_id')
            .eq('user_id', userId);
        userFavorites = (favs as List)
            .map((f) => f['service_id'] as String)
            .toSet();
      } catch (e) {
        // إذا حدث خطأ في استعلام المفضلة نتجاوزه
      }
    }

    return (response as List).map((e) {
      final model = ServiceItemModel.fromJson(e as Map<String, dynamic>);
      return model.copyWith(isFavorite: userFavorites.contains(model.id));
    }).toList();
  }

  @override
  Future<List<ServiceItemModel>> getServicesByCategory(String category) async {
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegex.hasMatch(category)) {
      return getServicesByCategoryId(category);
    }
    final all = await getAllServices();
    return all
        .where((s) => s.category == category || s.categoryId == category)
        .toList();
  }

  @override
  Future<ServiceItemModel?> getServiceById(String id) async {
    final userId = _client.auth.currentUser?.id;

    final response = await _client
        .from('services')
        .select('*, categories(name), service_images(image_url), provider_profiles(business_name, address)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    bool isFav = false;
    if (userId != null) {
      final fav = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('service_id', id)
          .maybeSingle();
      isFav = fav != null;
    }

    final model = ServiceItemModel.fromJson(response);
    return model.copyWith(isFavorite: isFav);
  }

  @override
  Future<List<ServiceItemModel>> searchServices(
    String query, {
    String? category,
  }) async {
    final all = await getAllServices();
    final lowerQuery = query.toLowerCase();

    return all.where((s) {
      final matchesQuery = s.title.toLowerCase().contains(lowerQuery) ||
          s.location.toLowerCase().contains(lowerQuery) ||
          s.description.toLowerCase().contains(lowerQuery);

      if (category == null || category.isEmpty || category == 'الكل') {
        return matchesQuery;
      }
      return matchesQuery && s.category == category;
    }).toList();
  }

  @override
  Future<void> toggleFavorite(String serviceId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يرجى تسجيل الدخول لحفظ الخدمة في المفضلة.');
    }

    final existing = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('service_id', serviceId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('service_id', serviceId);
    } else {
      await _client.from('favorites').insert({
        'user_id': userId,
        'service_id': serviceId,
      });
    }
  }

  @override
  Future<List<ServiceItemModel>> getFavoriteServices() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    // 1. Fetch user favorite records ordered by newest first
    final favRows = await _client
        .from('favorites')
        .select('service_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final serviceIds = (favRows as List)
        .map((f) => f['service_id'] as String)
        .toList();

    if (serviceIds.isEmpty) {
      return [];
    }

    // 2. Fetch service details for these IDs
    final response = await _client
        .from('services')
        .select('*, categories(name), service_images(image_url), provider_profiles(business_name, address)')
        .inFilter('id', serviceIds);

    final List<ServiceItemModel> servicesList = (response as List).map((e) {
      return ServiceItemModel.fromJson(e as Map<String, dynamic>)
          .copyWith(isFavorite: true);
    }).toList();

    // 3. Preserve the favorite addition order (newest favorite first)
    final orderMap = {
      for (int i = 0; i < serviceIds.length; i++) serviceIds[i]: i
    };
    servicesList.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999;
      final orderB = orderMap[b.id] ?? 999;
      return orderA.compareTo(orderB);
    });

    return servicesList;
  }

  @override
  Future<bool> isFavorite(String serviceId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final existing = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('service_id', serviceId)
        .maybeSingle();

    return existing != null;
  }
}
