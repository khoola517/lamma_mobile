import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khadematy/app/theme/app_theme.dart';
import 'package:khadematy/core/constants/app_colors.dart';
import 'package:khadematy/core/services/supabase_realtime_service.dart';
import 'package:khadematy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:khadematy/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:khadematy/features/home/data/models/category_model.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/home/domain/repositories/services_repository.dart';
import 'package:khadematy/features/home/presentation/controllers/home_controller.dart';
import 'package:khadematy/features/reviews/data/models/review_model.dart';
import 'package:khadematy/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:khadematy/features/reviews/presentation/controllers/reviews_controller.dart';
import 'package:khadematy/features/service_details/presentation/screens/service_details_screen.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
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
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08,
    0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A,
    0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05,
    0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
    0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
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
  final ServiceItemModel service;
  _FakeServicesRepository(this.service);

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ServiceItemModel>> getAllServices() async => [service];

  @override
  Future<List<ServiceItemModel>> getServicesByCategory(String category) async =>
      [];

  @override
  Future<List<ServiceItemModel>> getServicesByCategoryId(
          String categoryId) async =>
      [];

  @override
  Future<ServiceItemModel?> getServiceById(String id) async => service;

  @override
  Future<List<ServiceItemModel>> searchServices(String query,
          {String? category}) async =>
      [];

  @override
  Future<void> toggleFavorite(String serviceId) async {}

  @override
  Future<void> addFavorite(String serviceId) async {}

  @override
  Future<void> removeFavorite(String serviceId) async {}

  @override
  Future<List<ServiceItemModel>> getFavoriteServices() async => [];

  @override
  Future<bool> isFavorite(String serviceId) async => false;

  @override
  RealtimeSubscriptionToken subscribeToCategories({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 'cat', listenerId: '1');

  @override
  RealtimeSubscriptionToken subscribeToServices({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 'svc', listenerId: '1');

  @override
  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 'fav', listenerId: '1');
}

class _FakeReviewsRepository implements ReviewsRepository {
  @override
  Future<List<ReviewModel>> getServiceReviews(String serviceId) async => [
        ReviewModel(
          id: 'rev-1',
          serviceId: serviceId,
          customerId: 'cust-1',
          customerName: 'سارة علي',
          rating: 5,
          comment: 'خدمة رائعة جداً',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

  @override
  Future<void> submitReview({
    required String serviceId,
    String? bookingId,
    required int rating,
    required String comment,
  }) async {}

  @override
  Future<bool> hasUserBookedService(String serviceId) async => false;

  @override
  Future<String?> getUserBookingIdForService(String serviceId) async => null;

  @override
  Future<bool> hasUserReviewedService(String serviceId) async => false;

  @override
  RealtimeSubscriptionToken subscribeToServiceReviews({
    required String serviceId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 'rev', listenerId: '1');
}

class _FakeAuthController extends ChangeNotifier implements AuthController {
  @override
  AuthStatus status = AuthStatus.unauthenticated;

  @override
  bool get isAuthenticated => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('ServiceDetailsScreen applies dark mode palette dynamically',
      (tester) async {
    const sampleService = ServiceItemModel(
      id: 'svc-dark-1',
      title: 'قاعة اللؤلؤة',
      category: 'قاعات المناسبات',
      location: 'المكلا',
      price: 250000,
      rating: 4.9,
      reviewsCount: 1,
      imageUrl: 'https://example.com/hall.jpg',
      description: 'قاعة فاخرة مجهزة بالكامل',
      occasions: ['زفاف', 'تخرج'],
      features: ['تكييف مركزي', 'إضاءة ذكية'],
      workingHours: [
        {'day': 'السبت', 'status': 'متاح', 'time': '4م - 11م'},
      ],
    );

    final servicesRepo = _FakeServicesRepository(sampleService);
    final homeCtrl = HomeController(repository: servicesRepo);
    await homeCtrl.loadHomeData();

    final favCtrl = FavoritesController(repository: servicesRepo);
    final reviewsCtrl = ReviewsController(repository: _FakeReviewsRepository());
    final authCtrl = _FakeAuthController();

    AppColors.setDarkMode(true);
    addTearDown(() => AppColors.setDarkMode(false));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: homeCtrl),
          ChangeNotifierProvider<FavoritesController>.value(value: favCtrl),
          ChangeNotifierProvider<ReviewsController>.value(value: reviewsCtrl),
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ServiceDetailsScreen(service: sampleService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scaffold background must use darkBackground, not hardcoded light Color(0xFFF7F8FA)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.darkBackground);

    // Service title text must use darkTextPrimary, not hardcoded dark text Color(0xFF1E2538)
    final titleText = tester.widget<Text>(find.text('قاعة اللؤلؤة'));
    expect(titleText.style?.color, AppColors.darkTextPrimary);

    // Section heading "نبذة" must use darkTextPrimary
    final aboutHeading = tester.widget<Text>(find.text('نبذة'));
    expect(aboutHeading.style?.color, AppColors.darkTextPrimary);

    // Reviews heading "التقييمات" must use darkTextPrimary
    final reviewsHeading = tester.widget<Text>(find.text('التقييمات'));
    expect(reviewsHeading.style?.color, AppColors.darkTextPrimary);
  });
}

