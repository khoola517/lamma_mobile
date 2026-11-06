import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/models/booking_model.dart';

abstract class BookingsRepository {
  Future<List<BookingModel>> getMyBookings();
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
  });
  Future<void> cancelBooking(String bookingId);

  RealtimeSubscriptionToken subscribeToCustomerBookings({
    required String customerId,
    required void Function() onData,
    void Function()? onResync,
  });

  RealtimeSubscriptionToken subscribeToBookingItems({
    required void Function() onData,
    void Function()? onResync,
  });

  RealtimeSubscriptionToken subscribeToBookingStatusHistory({
    required void Function() onData,
    void Function()? onResync,
  });
}
