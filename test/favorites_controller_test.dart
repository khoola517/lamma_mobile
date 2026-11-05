import 'package:flutter_test/flutter_test.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/home/domain/repositories/services_repository.dart';
import 'package:khadematy/features/favorites/presentation/controllers/favorites_controller.dart';

class MockTestServicesRepository implements ServicesRepository {
  final List<ServiceItemModel> _services = [
    const ServiceItemModel(
      id: 'srv_1',
      title: 'قاعة الفخامة',
      category: 'قاعات',
      location: 'المكلا',
      price: 100000,
      rating: 4.8,
      imageUrl: 'https://example.com/1.jpg',
      isFavorite: true,
    ),
    const ServiceItemModel(
      id: 'srv_2',
      title: 'استديو تصوير',
      category: 'تصوير',
      location: 'المكلا',
      price: 50000,
      rating: 4.9,
      imageUrl: 'https://example.com/2.jpg',
      isFavorite: false,
    ),
  ];

  @override
  Future<List<ServiceItemModel>> getFavoriteServices() async {
    return _services.where((s) => s.isFavorite).toList();
  }

  @override
  Future<bool> isFavorite(String serviceId) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    return index != -1 && _services[index].isFavorite;
  }

  @override
  Future<void> toggleFavorite(String serviceId) async {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index != -1) {
      _services[index] = _services[index].copyWith(
        isFavorite: !_services[index].isFavorite,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockTestServicesRepository repository;
  late FavoritesController controller;

  setUp(() {
    repository = MockTestServicesRepository();
    controller = FavoritesController(repository: repository);
  });

  test('loadFavorites loads favorited services from repository', () async {
    expect(controller.favoriteServices.isEmpty, true);

    await controller.loadFavorites();

    expect(controller.favoriteServices.length, 1);
    expect(controller.favoriteServices.first.id, 'srv_1');
    expect(controller.isFavorite('srv_1'), true);
    expect(controller.isFavorite('srv_2'), false);
  });

  test('removeFavorite removes service optimistically', () async {
    await controller.loadFavorites();
    expect(controller.favoriteServices.length, 1);

    await controller.removeFavorite('srv_1');
    expect(controller.favoriteServices.isEmpty, true);
    expect(controller.isFavorite('srv_1'), false);
  });

  test('toggleFavorite adds service if not favorited', () async {
    await controller.loadFavorites();
    const newService = ServiceItemModel(
      id: 'srv_2',
      title: 'استديو تصوير',
      category: 'تصوير',
      location: 'المكلا',
      price: 50000,
      rating: 4.9,
      imageUrl: 'https://example.com/2.jpg',
    );

    final isFav = await controller.toggleFavorite(newService);
    expect(isFav, true);
    expect(controller.isFavorite('srv_2'), true);
    expect(controller.favoriteServices.length, 2);
  });

  test('onAuthChanged clears favorites when logged out and reloads when logged in', () async {
    await controller.loadFavorites();
    expect(controller.favoriteServices.length, 1);

    // Logout
    controller.onAuthChanged(false);
    expect(controller.favoriteServices.isEmpty, true);

    // Login
    controller.onAuthChanged(true);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(controller.favoriteServices.length, 1);
  });
}
