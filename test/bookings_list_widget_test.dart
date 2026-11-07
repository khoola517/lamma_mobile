import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khadematy/app/routes/app_routes.dart';
import 'package:khadematy/core/services/supabase_realtime_service.dart';
import 'package:khadematy/features/bookings/data/models/booking_model.dart';
import 'package:khadematy/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:khadematy/features/bookings/presentation/controllers/bookings_controller.dart';
import 'package:khadematy/features/bookings/presentation/screens/bookings_list_screen.dart';
import 'package:khadematy/features/home/data/models/category_model.dart';
import 'package:khadematy/features/home/data/models/service_item_model.dart';
import 'package:khadematy/features/home/domain/repositories/services_repository.dart';
import 'package:khadematy/features/home/presentation/controllers/home_controller.dart';

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

class _MockTestBookingsRepository implements BookingsRepository {
  List<BookingModel> bookings = [];

  @override
  Future<List<BookingModel>> getMyBookings() async => bookings;

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
    final b = BookingModel(
      id: 'new-booking',
      bookingCode: 'KH-12345',
      title: eventType,
      category: category ?? 'عام',
      vendorName: vendorName ?? 'مقدم الخدمة',
      imageUrl: serviceImageUrl ?? '',
      bookingDate: eventDate,
      timeSlot: timeSlot,
      status: BookingStatus.pending,
      price: budget ?? 1000,
    );
    bookings.insert(0, b);
    return b;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      bookings[idx] = bookings[idx].copyWith(status: BookingStatus.cancelled);
    }
  }

  @override
  RealtimeSubscriptionToken subscribeToCustomerBookings({
    required String customerId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_cust_b',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToBookingItems({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_items_b',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToBookingStatusHistory({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_history_b',
        listenerId: '1',
      );
}

class _MockTestServicesRepository implements ServicesRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ServiceItemModel>> getAllServices() async => [
        const ServiceItemModel(
          id: 'svc-1',
          title: 'قاعة الملكة الذهبية',
          category: 'قاعات المناسبات',
          location: 'صنعاء',
          price: 350000,
          rating: 4.8,
          imageUrl: 'https://example.com/image.jpg',
        ),
      ];

  @override
  Future<List<ServiceItemModel>> getServicesByCategory(String category) async => [];

  @override
  Future<List<ServiceItemModel>> getServicesByCategoryId(String categoryId) async => [];

  @override
  Future<ServiceItemModel?> getServiceById(String id) async => null;

  @override
  Future<List<ServiceItemModel>> searchServices(String query, {String? category}) async => [];

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
      const RealtimeSubscriptionToken(
        channelKey: 'test_cat',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToServices({
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_svc',
        listenerId: '1',
      );

  @override
  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required void Function() onData,
    void Function()? onResync,
  }) =>
      const RealtimeSubscriptionToken(
        channelKey: 'test_fav',
        listenerId: '1',
      );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('BookingsListScreen renders and clicks Rebook button', (tester) async {
    final mockRepo = _MockTestBookingsRepository();
    mockRepo.bookings = [
      BookingModel(
        id: 'b-cancelled-1',
        bookingCode: 'KH-88771',
        title: 'قاعة الملكة الذهبية',
        category: 'قاعات المناسبات',
        vendorName: 'قاعة الملكة',
        imageUrl: 'https://example.com/venue.jpg',
        bookingDate: DateTime.now().add(const Duration(days: 10)),
        timeSlot: 'الفترة المسائية (4:00 م - 11:00 م)',
        status: BookingStatus.cancelled,
        price: 350000,
        items: const [
          BookingItemModel(
            id: 'item-1',
            bookingId: 'b-cancelled-1',
            serviceId: 'svc-1',
            serviceName: 'قاعة الملكة الذهبية',
            unitPrice: 350000,
            subtotal: 350000,
          ),
        ],
      ),
    ];

    final bookingsCtrl = BookingsController(repository: mockRepo);
    final homeCtrl = HomeController(repository: _MockTestServicesRepository());
    await homeCtrl.loadHomeData();

    dynamic capturedArguments;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingsController>.value(value: bookingsCtrl),
          ChangeNotifierProvider<HomeController>.value(value: homeCtrl),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.bookingDate) {
              capturedArguments = settings.arguments;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('شاشة تأكيد الحجز')),
              );
            }
            return MaterialPageRoute(builder: (_) => const BookingsListScreen());
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify booking card is rendered
    expect(find.text('#KH-88771'), findsOneWidget);
    expect(find.text('قاعة الملكة الذهبية'), findsOneWidget);

    // Verify "إعادة الحجز" button is present
    final rebookBtn = find.text('إعادة الحجز');
    expect(rebookBtn, findsOneWidget);

    // Tap "إعادة الحجز"
    await tester.tap(rebookBtn);
    await tester.pumpAndSettle();

    // Verify navigated to booking date screen
    expect(find.text('شاشة تأكيد الحجز'), findsOneWidget);
    expect(capturedArguments, isNotNull);
    final argsMap = capturedArguments as Map<String, dynamic>;
    final svc = argsMap['service'] as ServiceItemModel;
    expect(svc.id, 'svc-1');
    expect(svc.title, 'قاعة الملكة الذهبية');
    expect(argsMap['initialSlot'], 'الفترة المسائية (4:00 م - 11:00 م)');
  });
}
