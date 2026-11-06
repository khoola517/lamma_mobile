import 'package:flutter/material.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/supabase_bookings_repository.dart';
import '../../domain/repositories/bookings_repository.dart';

class BookingsController extends ChangeNotifier {
  final BookingsRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0; // 0: الكل, 1: قيد الانتظار, 2: المكتملة
  bool? _lastAuthStatus;
  final List<RealtimeSubscriptionToken> _realtimeTokens = [];

  List<BookingModel> _bookings = [];

  BookingsController({BookingsRepository? repository})
      : _repository = repository ?? SupabaseBookingsRepository() {
    loadBookings();
    _subscribeToBookingsRealtime();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  List<BookingModel> get allBookings => _bookings;

  List<BookingModel> get currentFilteredBookings {
    switch (_selectedTabIndex) {
      case 1:
        return _bookings
            .where((b) =>
                b.status == BookingStatus.pending ||
                b.status == BookingStatus.partiallyAccepted ||
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.inProgress)
            .toList();
      case 2:
        return _bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      default:
        return _bookings;
    }
  }

  void setTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void onAuthChanged(bool isAuthenticated) {
    if (_lastAuthStatus != isAuthenticated) {
      _lastAuthStatus = isAuthenticated;
      if (isAuthenticated) {
        _subscribeToBookingsRealtime();
        loadBookings();
      } else {
        _unsubscribeRealtime();
        _bookings = [];
        _errorMessage = null;
        notifyListeners();
      }
    }
  }

  void _subscribeToBookingsRealtime() {
    _unsubscribeRealtime();
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. مزامنة حجوزات العميل عند تحديث حالتها من مقدم الخدمة أو الأدمن
    _realtimeTokens.add(
      SupabaseRealtimeService.instance.subscribeTable(
        table: 'bookings',
        filter: 'customer_id=eq.$userId',
        onInserted: (_) => loadBookings(),
        onUpdated: (_) => loadBookings(),
        onDeleted: (_) => loadBookings(),
      ),
    );

    // 2. مزامنة تفاصيل الخدمات في الحجز
    _realtimeTokens.add(
      SupabaseRealtimeService.instance.subscribeTable(
        table: 'booking_items',
        onInserted: (_) => loadBookings(),
        onUpdated: (_) => loadBookings(),
        onDeleted: (_) => loadBookings(),
      ),
    );

    // 3. إعادة المزامنة عند عودة الاتصال
    _realtimeTokens.add(
      SupabaseRealtimeService.instance.onReconnected(() {
        loadBookings();
      }),
    );
  }

  void _unsubscribeRealtime() {
    for (final token in _realtimeTokens) {
      token.cancel();
    }
    _realtimeTokens.clear();
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  Future<void> loadBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteBookings = await _repository.getMyBookings();
      _bookings = remoteBookings;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addBooking(BookingModel booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

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
    if (_isLoading) {
      throw Exception('جاري معالجة طلب حجز حالي، يرجى الانتظار.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      final newBooking = await _repository.createBooking(
        eventType: eventType,
        eventDate: eventDate,
        timeSlot: timeSlot,
        serviceIds: serviceIds,
        customerId: customerId,
        packageId: packageId,
        location: location,
        guestCount: guestCount,
        budget: budget,
        notes: notes,
        serviceImageUrl: serviceImageUrl,
        vendorName: vendorName,
        category: category,
      );
      _bookings.insert(0, newBooking);
      _isLoading = false;
      notifyListeners();
      return newBooking;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] =
          _bookings[index].copyWith(status: BookingStatus.cancelled);
      notifyListeners();
    }

    try {
      await _repository.cancelBooking(bookingId);
    } catch (_) {}
  }
}
