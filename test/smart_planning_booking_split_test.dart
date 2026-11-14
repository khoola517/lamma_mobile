import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khadematy/app/routes/app_routes.dart';
import 'package:khadematy/core/config/supabase_config.dart';
import 'package:khadematy/core/constants/app_strings.dart';
import 'package:khadematy/core/services/supabase_realtime_service.dart';
import 'package:khadematy/features/auth/data/models/user_model.dart';
import 'package:khadematy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:khadematy/features/bookings/data/models/booking_model.dart';
import 'package:khadematy/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:khadematy/features/bookings/presentation/controllers/bookings_controller.dart';
import 'package:khadematy/features/bookings/presentation/screens/booking_success_screen.dart';
import 'package:khadematy/features/bookings/presentation/screens/bookings_list_screen.dart';
import 'package:khadematy/features/home/data/models/category_model.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/home/domain/repositories/services_repository.dart';
import 'package:khadematy/features/home/presentation/controllers/home_controller.dart';
import 'package:khadematy/features/smart_planning/data/models/smart_plan_models.dart';
import 'package:khadematy/features/smart_planning/domain/repositories/smart_planning_repository.dart';
import 'package:khadematy/features/smart_planning/presentation/controllers/smart_planning_controller.dart';
import 'package:khadematy/features/smart_planning/presentation/screens/package_customization_screen.dart';

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

class _FakeAuthController extends ChangeNotifier implements AuthController {
  @override
  AuthStatus status = AuthStatus.authenticated;

  @override
  bool get isAuthenticated => true;

  @override
  UserModel? user = const UserModel(
    id: 'user-1',
    name: 'عميل تجريبي',
    email: 'test@example.com',
    phone: '777123456',
  );

  @override
  String? errorMessage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSmartPlanningRepository implements SmartPlanningRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => const [];

  @override
  Future<SmartPlanResult> generatePlan(SmartPlanRequest request) async {
    const pkg = PackageOption(
      id: 'pkg_std',
      name: 'الباقة المتكاملة',
      price: 470000,
      servicesCount: 2,
      savingsText: 'وفر 10%',
      isFeatured: true,
    );
    const items = [
      CustomizableServiceItem(
        id: 'svc-1',
        name: 'قاعة الأفراح الملكية',
        vendor: 'مؤسسة القاعات',
        details: 'تتسع لـ 200 ضيف',
        price: 350000,
        isIncluded: true,
        imageUrl: 'https://example.com/hall.jpg',
      ),
      CustomizableServiceItem(
        id: 'svc-2',
        name: 'خدمات التصوير الاحترافي',
        vendor: 'استوديو الضوء',
        details: 'تصوير فيديو وفوتوغراف',
        price: 120000,
        isIncluded: true,
        imageUrl: 'https://example.com/photo.jpg',
      ),
      CustomizableServiceItem(
        id: 'svc-3',
        name: 'تنسيق الزهور',
        vendor: 'دار الزهور',
        details: 'كوشة وممرات',
        price: 80000,
        isIncluded: false,
        imageUrl: 'https://example.com/flowers.jpg',
      ),
    ];

    return SmartPlanResult(
      request: request,
      estimatedTotal: 470000,
      savingsNote: 'مناسب للميزانية',
      budgetDistribution: const [],
      packages: const [pkg],
      customizableServices: items,
      packageServicesMap: const {'pkg_std': items},
    );
  }

  @override
  Future<String> saveSelectedPackage({
    required SmartPlanRequest request,
    required PackageOption package,
    required List<CustomizableServiceItem> services,
    String? existingPackageId,
    String? customerId,
  }) async =>
      'pkg-uuid-1';
}

class _RecordedCreateCall {
  final String eventType;
  final List<String> serviceIds;
  final num? budget;
  final String? serviceImageUrl;
  final String? vendorName;

  const _RecordedCreateCall({
    required this.eventType,
    required this.serviceIds,
    required this.budget,
    required this.serviceImageUrl,
    required this.vendorName,
  });
}

class _RecordingBookingsRepository implements BookingsRepository {
  final List<_RecordedCreateCall> calls = [];
  final List<BookingModel> bookings = [];
  int _counter = 100;

  @override
  Future<List<BookingModel>> getMyBookings() async =>
      List<BookingModel>.from(bookings);

  @override
  Future<BookingModel> createBooking({
    required String eventType,
    required DateTime eventDate,
    required String timeSlot,
    required List<String> serviceIds,
    String? customerId,
    String? packageId,
    String? location,
    int? guestCount,
    num? budget,
    String? notes,
    String? serviceImageUrl,
    String? vendorName,
    String? category,
  }) async {
    _counter++;
    calls.add(_RecordedCreateCall(
      eventType: eventType,
      serviceIds: List<String>.from(serviceIds),
      budget: budget,
      serviceImageUrl: serviceImageUrl,
      vendorName: vendorName,
    ));

    final code = 'KH-$_counter';
    final booking = BookingModel(
      id: 'booking-$_counter',
      bookingCode: code,
      title: eventType,
      category: category ?? 'باقة مناسبة',
      vendorName: vendorName ?? 'مقدم الخدمة',
      imageUrl: serviceImageUrl ?? '',
      bookingDate: eventDate,
      timeSlot: timeSlot,
      status: BookingStatus.pending,
      price: budget ?? 0,
      items: [
        BookingItemModel(
          id: 'item-$_counter',
          bookingId: 'booking-$_counter',
          serviceId: serviceIds.first,
          serviceName: eventType,
          serviceImageUrl: serviceImageUrl,
          vendorName: vendorName,
          unitPrice: budget ?? 0,
          subtotal: budget ?? 0,
        ),
      ],
    );
    bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {}

  @override
  RealtimeSubscriptionToken subscribeToCustomerBookings({
    required String customerId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_cust_split',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToBookingItems({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_items_split',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToBookingStatusHistory({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_history_split',
        listenerId: '1',
      );
}

class _DummyServicesRepository implements ServicesRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ServiceItemModel>> getAllServices() async => [];

  @override
  Future<List<ServiceItemModel>> getServicesByCategory(String category) async =>
      [];

  @override
  Future<List<ServiceItemModel>> getServicesByCategoryId(
          String categoryId) async =>
      [];

  @override
  Future<ServiceItemModel?> getServiceById(String id) async => null;

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
      const RealtimeSubscriptionToken(channelKey: 'c', listenerId: '1');

  @override
  RealtimeSubscriptionToken subscribeToServices({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 's', listenerId: '1');

  @override
  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(channelKey: 'f', listenerId: '1');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  HttpOverrides.global = _MockHttpOverrides();

  setUpAll(() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.cleanUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (_) {}
  });

  testWidgets(
      'PackageCustomizationScreen creates a separate booking per included service and BookingsListScreen shows each individually',
      (tester) async {
    final smartCtrl =
        SmartPlanningController(repository: _FakeSmartPlanningRepository());
    await smartCtrl.generatePlan();

    final bookingsRepo = _RecordingBookingsRepository();
    final bookingsCtrl = BookingsController(repository: bookingsRepo);
    final authCtrl = _FakeAuthController();
    final homeCtrl = HomeController(repository: _DummyServicesRepository());

    String? capturedBookingCodeArg;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
          ChangeNotifierProvider<SmartPlanningController>.value(
              value: smartCtrl),
          ChangeNotifierProvider<BookingsController>.value(value: bookingsCtrl),
          ChangeNotifierProvider<HomeController>.value(value: homeCtrl),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.bookingSuccess) {
              capturedBookingCodeArg = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (_) =>
                    BookingSuccessScreen(bookingCode: capturedBookingCodeArg!),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const PackageCustomizationScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final confirmBtn = find.text(AppStrings.confirmBooking);
    expect(confirmBtn, findsOneWidget);

    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify 2 separate createBooking calls (one per included service, ignoring svc-3)
    expect(bookingsRepo.calls.length, 2);

    expect(bookingsRepo.calls[0].serviceIds, ['svc-1']);
    expect(bookingsRepo.calls[0].eventType, 'قاعة الأفراح الملكية');
    expect(bookingsRepo.calls[0].budget, 350000);
    expect(
        bookingsRepo.calls[0].serviceImageUrl, 'https://example.com/hall.jpg');
    expect(bookingsRepo.calls[0].vendorName, 'مؤسسة القاعات');

    expect(bookingsRepo.calls[1].serviceIds, ['svc-2']);
    expect(bookingsRepo.calls[1].eventType, 'خدمات التصوير الاحترافي');
    expect(bookingsRepo.calls[1].budget, 120000);
    expect(bookingsRepo.calls[1].serviceImageUrl,
        'https://example.com/photo.jpg');
    expect(bookingsRepo.calls[1].vendorName, 'استوديو الضوء');

    // Verify BookingSuccessScreen renders both booking codes without overflow
    expect(capturedBookingCodeArg, 'KH-101 ، #KH-102');
    expect(find.text('#KH-101 ، #KH-102'), findsOneWidget);

    // Now render BookingsListScreen and verify both separate booking cards appear
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingsController>.value(value: bookingsCtrl),
          ChangeNotifierProvider<HomeController>.value(value: homeCtrl),
        ],
        child: const MaterialApp(
          home: BookingsListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(bookingsCtrl.allBookings.length, 2);
    expect(find.text('#KH-102'), findsOneWidget);
    expect(find.text('خدمات التصوير الاحترافي'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('#KH-101'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('#KH-101'), findsOneWidget);
    expect(find.text('قاعة الأفراح الملكية'), findsOneWidget);
  });
}

