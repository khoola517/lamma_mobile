// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khadematy/app/routes/app_routes.dart';
import 'package:khadematy/core/widgets/empty_state_view.dart';
import 'package:khadematy/core/widgets/loading_view.dart';
import 'package:khadematy/features/home/data/models/category_model.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/home/domain/repositories/services_repository.dart';
import 'package:khadematy/features/home/presentation/controllers/home_controller.dart';
import 'package:khadematy/features/home/presentation/screens/home_screen.dart';
import 'package:khadematy/features/home/presentation/screens/category_services_screen.dart';
import 'package:khadematy/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:khadematy/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khadematy/core/services/supabase_realtime_service.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final Uint8List _transparentImage = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServicesRepository implements ServicesRepository {
  final Map<String, List<ServiceItemModel>> servicesPerCategory;

  _FakeServicesRepository({required this.servicesPerCategory});

  @override
  Future<List<CategoryModel>> getCategories() async {
    return const [
      CategoryModel(
        id: 'cat_venues_1',
        title: 'قاعات المناسبات',
        imageUrl: '',
      ),
      CategoryModel(
        id: 'cat_decor_2',
        title: 'تنسيق ديكور الحفلات',
        imageUrl: '',
      ),
    ];
  }

  @override
  Future<List<ServiceItemModel>> getAllServices() async {
    return servicesPerCategory.values.expand((element) => element).toList();
  }

  @override
  Future<List<ServiceItemModel>> getServicesByCategoryId(
      String categoryId) async {
    return servicesPerCategory[categoryId] ?? [];
  }

  @override
  Future<List<ServiceItemModel>> getServicesByCategory(String category) async {
    return servicesPerCategory[category] ?? [];
  }

  @override
  Future<ServiceItemModel?> getServiceById(String id) async {
    for (final list in servicesPerCategory.values) {
      for (final s in list) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  @override
  Future<List<ServiceItemModel>> searchServices(String query,
      {String? category}) async {
    return [];
  }

  @override
  Future<void> toggleFavorite(String serviceId) async {}

  @override
  Future<void> addFavorite(String serviceId) async {}

  @override
  Future<void> removeFavorite(String serviceId) async {}

  @override
  Future<List<ServiceItemModel>> getFavoriteServices() async {
    return [];
  }

  @override
  Future<bool> isFavorite(String serviceId) async {
    return false;
  }

  @override
  RealtimeSubscriptionToken subscribeToCategories({
    required void Function() onData,
    void Function()? onResync,
  }) {
    return const RealtimeSubscriptionToken(
      channelKey: 'test_categories',
      listenerId: 'test_1',
    );
  }

  @override
  RealtimeSubscriptionToken subscribeToServices({
    required void Function() onData,
    void Function()? onResync,
  }) {
    return const RealtimeSubscriptionToken(
      channelKey: 'test_services',
      listenerId: 'test_2',
    );
  }

  @override
  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  }) {
    return const RealtimeSubscriptionToken(
      channelKey: 'test_favorites',
      listenerId: 'test_3',
    );
  }
}

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationItem>> getMyNotifications() async => [];
  @override
  Stream<List<NotificationItem>> getNotificationsStream() => const Stream.empty();
  @override
  Future<void> markAsRead(String notificationId) async {}
  @override
  Future<void> markAllAsRead() async {}

  @override
  RealtimeSubscriptionToken subscribeToUserNotifications({
    required String userId,
    required void Function(Map<String, dynamic> record, PostgresChangeEvent event) onData,
    void Function()? onResync,
  }) {
    return const RealtimeSubscriptionToken(
      channelKey: 'test_notifications',
      listenerId: 'test_4',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  const cat1 = CategoryModel(
    id: 'cat_venues_1',
    title: 'قاعات المناسبات',
    imageUrl: '',
  );

  const cat2 = CategoryModel(
    id: 'cat_decor_2',
    title: 'تنسيق ديكور الحفلات',
    imageUrl: '',
  );

  const venueService1 = ServiceItemModel(
    id: 'srv_1',
    title: 'صالة الديار الكبرى للمناسبات',
    category: 'قاعات المناسبات',
    categoryId: 'cat_venues_1',
    location: 'صنعاء',
    price: 450000,
    rating: 4.9,
    imageUrl: '',
  );

  const venueService2 = ServiceItemModel(
    id: 'srv_2',
    title: 'صالة المراسيم الملكية VIP',
    category: 'قاعات المناسبات',
    categoryId: 'cat_venues_1',
    location: 'صنعاء',
    price: 380000,
    rating: 4.8,
    imageUrl: '',
  );

  const decorService1 = ServiceItemModel(
    id: 'srv_3',
    title: 'الأندلس لتنسيق الكوش الملكية',
    category: 'تنسيق ديكور الحفلات',
    categoryId: 'cat_decor_2',
    location: 'صنعاء',
    price: 220000,
    rating: 4.9,
    imageUrl: '',
  );

  final fakeRepo = _FakeServicesRepository(
    servicesPerCategory: {
      'cat_venues_1': [venueService1, venueService2],
      'cat_decor_2': [decorService1],
    },
  );

  testWidgets('CategoryServicesScreen displays services for category 1',
      (WidgetTester tester) async {
    final homeController = HomeController(repository: fakeRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: homeController),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoryServicesScreen(category: cat1),
          ),
        ),
      ),
    );

    // Initial loading view
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pumpAndSettle();

    // Verify AppBar shows category 1 title
    expect(find.text('قاعات المناسبات'), findsOneWidget);

    // Verify category 1 services are displayed
    expect(find.text('صالة الديار الكبرى للمناسبات'), findsOneWidget);
    expect(find.text('صالة المراسيم الملكية VIP'), findsOneWidget);

    // Verify category 2 services are NOT displayed
    expect(find.text('الأندلس لتنسيق الكوش الملكية'), findsNothing);
  });

  testWidgets('CategoryServicesScreen displays services for category 2',
      (WidgetTester tester) async {
    final homeController = HomeController(repository: fakeRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: homeController),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoryServicesScreen(category: cat2),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar shows category 2 title
    expect(find.text('تنسيق ديكور الحفلات'), findsOneWidget);

    // Verify category 2 services are displayed
    expect(find.text('الأندلس لتنسيق الكوش الملكية'), findsOneWidget);

    // Verify category 1 services are NOT displayed
    expect(find.text('صالة الديار الكبرى للمناسبات'), findsNothing);
    expect(find.text('صالة المراسيم الملكية VIP'), findsNothing);
  });

  testWidgets('CategoryServicesScreen displays empty state when no services',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final homeController = HomeController(repository: fakeRepo);
    const emptyCat = CategoryModel(
      id: 'cat_empty',
      title: 'تصنيف فارغ',
      imageUrl: '',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: homeController),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoryServicesScreen(category: emptyCat),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('لا توجد خدمات متاحة حالياً'), findsOneWidget);
  });

  testWidgets('HomeScreen navigation to CategoryServicesScreen on category tap',
      (WidgetTester tester) async {
    final homeController = HomeController(repository: fakeRepo);
    final notifController = NotificationsController(repository: _FakeNotificationsRepository());

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: homeController),
          ChangeNotifierProvider<NotificationsController>.value(
              value: notifController),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on category 1 (قاعات المناسبات)
    final cat1Finder = find.text('قاعات المناسبات');
    expect(cat1Finder, findsOneWidget);
    await tester.tap(cat1Finder);
    await tester.pumpAndSettle();

    // Verify navigated to CategoryServicesScreen with Category 1
    expect(find.byType(CategoryServicesScreen), findsOneWidget);
    expect(find.text('صالة الديار الكبرى للمناسبات'), findsOneWidget);
    expect(find.text('صالة المراسيم الملكية VIP'), findsOneWidget);
    expect(find.text('الأندلس لتنسيق الكوش الملكية'), findsNothing);

    // Pop back to HomeScreen
    final backButtonFinder = find.byIcon(Icons.arrow_back);
    expect(backButtonFinder, findsOneWidget);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();

    // Now tap on category 2 (تنسيق ديكور الحفلات)
    final cat2Finder = find.text('تنسيق ديكور الحفلات');
    expect(cat2Finder, findsOneWidget);
    await tester.tap(cat2Finder);
    await tester.pumpAndSettle();

    // Verify navigated to CategoryServicesScreen with Category 2
    expect(find.byType(CategoryServicesScreen), findsOneWidget);
    expect(find.text('الأندلس لتنسيق الكوش الملكية'), findsOneWidget);
    expect(find.text('صالة الديار الكبرى للمناسبات'), findsNothing);
    expect(find.text('صالة المراسيم الملكية VIP'), findsNothing);
  });
}
