import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../models/booking_model.dart';
import '../../domain/repositories/bookings_repository.dart';

class SupabaseBookingsRepository implements BookingsRepository {
  final SupabaseClient _client;

  SupabaseBookingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<List<BookingModel>> getMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('bookings')
        .select(
            '*, booking_items(*, services(name, image_url, categories(name), provider_profiles(business_name)))')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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
    final userId = customerId ?? _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً لإتمام وتأكيد الحجز.');
    }

    String slot = 'evening';
    if (timeSlot.contains('صباح') || timeSlot == 'morning') {
      slot = 'morning';
    } else if (timeSlot.contains('كامل') || timeSlot == 'full_day') {
      slot = 'full_day';
    }

    // التحقق من صحة معرّفات UUID وتأمين التوافق مع قاعدة بيانات Supabase
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    List<String> validServiceIds =
        serviceIds.where((id) => uuidRegex.hasMatch(id)).toList();

    // في حال عدم توفر معرفات صالحة (مثلاً عند استدعاء تجريبي)، يتم جلب أول خدمة نشطة
    if (validServiceIds.isEmpty) {
      final activeServices = await _client
          .from('services')
          .select('id')
          .eq('status', 'active')
          .limit(1);
      if (activeServices.isNotEmpty) {
        validServiceIds = [activeServices.first['id'] as String];
      }
    }

    final String? validPackageId =
        (packageId != null && uuidRegex.hasMatch(packageId)) ? packageId : null;

    // استخراج بيانات الخدمة الفعلية (الصورة، الاسم، التصنيف، اسم المزود)
    String? resolvedImageUrl = serviceImageUrl;
    String resolvedVendor = vendorName ?? 'منصة خِدمتي';
    String resolvedCategory = category ?? 'خدمة خاصة';
    String resolvedTitle = eventType;

    if ((resolvedImageUrl == null || resolvedImageUrl.trim().isEmpty) &&
        validServiceIds.isNotEmpty) {
      try {
        final srvData = await _client
            .from('services')
            .select(
                'name, image_url, categories(name), provider_profiles(business_name)')
            .eq('id', validServiceIds.first)
            .maybeSingle();

        if (srvData != null) {
          final dbImg = srvData['image_url'] as String?;
          if (dbImg != null && dbImg.trim().isNotEmpty) {
            resolvedImageUrl = dbImg.trim();
          }
          final dbName = srvData['name'] as String?;
          if (dbName != null && dbName.trim().isNotEmpty) {
            resolvedTitle = dbName.trim();
          }
          if (srvData['categories'] is Map &&
              srvData['categories']['name'] != null) {
            resolvedCategory =
                (srvData['categories']['name'] as String).trim();
          }
          if (srvData['provider_profiles'] is Map &&
              srvData['provider_profiles']['business_name'] != null) {
            resolvedVendor =
                (srvData['provider_profiles']['business_name'] as String).trim();
          }
        }
      } catch (_) {}
    }

    try {
      final dynamic rpcRes = await _client.rpc(
        'create_booking_atomic',
        params: {
          'p_customer_id': userId,
          'p_event_type': eventType,
          'p_event_date': eventDate.toIso8601String().split('T')[0],
          'p_time_slot': slot,
          'p_service_ids': validServiceIds,
          'p_package_id': validPackageId,
          'p_event_location': location,
          'p_guest_count': guestCount,
          'p_budget': budget,
          'p_notes': notes,
        },
      );

      final Map<String, dynamic> data =
          rpcRes is Map<String, dynamic> ? rpcRes : {};

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'فشل إنشاء الحجز.');
      }

      final bookingId = data['booking_id'] as String;
      final bookingCode = data['booking_code'] as String;
      final totalAmount = (data['total_amount'] as num?) ?? budget ?? 0;

      // إشعار مقدم الخدمة لحظياً بالطلب الجديد
      _notifyProviderOnNewBooking(bookingId, bookingCode, validServiceIds);

      return BookingModel(
        id: bookingId,
        bookingCode: bookingCode,
        title: resolvedTitle,
        category: resolvedCategory,
        vendorName: resolvedVendor,
        imageUrl: resolvedImageUrl ??
            'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=600&q=80',
        bookingDate: eventDate,
        timeSlot: timeSlot,
        status: BookingStatus.pending,
        price: totalAmount,
        priceUnit: 'ر.ي',
        notes: notes,
        progressStep: 1,
        items: [
          if (validServiceIds.isNotEmpty)
            BookingItemModel(
              id: '',
              bookingId: bookingId,
              serviceId: validServiceIds.first,
              serviceName: resolvedTitle,
              serviceImageUrl: resolvedImageUrl,
              category: resolvedCategory,
              vendorName: resolvedVendor,
              unitPrice: totalAmount,
              subtotal: totalAmount,
            ),
        ],
      );
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST202') {
        // إذا لم تكن الدالة منشورة، يتم الإدراج المباشر في جداول bookings و booking_items في Supabase
        final bookingCode =
            'KH-${DateTime.now().year % 100}-${(DateTime.now().millisecondsSinceEpoch % 90000) + 10000}';
        final totalAmount = budget ?? 0;

        final inserted = await _client.from('bookings').insert({
          'customer_id': userId,
          'booking_code': bookingCode,
          'event_type': eventType,
          'event_date': eventDate.toIso8601String().split('T')[0],
          'time_slot': slot,
          'event_location': location,
          'guest_count': guestCount,
          'budget': budget,
          'total_amount': totalAmount,
          'notes': notes,
          'status': 'pending',
          if (validPackageId != null) 'package_id': validPackageId,
        }).select('id').single();

        final bookingId = inserted['id'] as String;

        if (validServiceIds.isNotEmpty) {
          final itemsToInsert = validServiceIds.map((sid) => {
            'booking_id': bookingId,
            'service_id': sid,
            'quantity': 1,
            'unit_price': totalAmount,
            'subtotal': totalAmount,
            'item_status': 'pending',
          }).toList();
          await _client.from('booking_items').insert(itemsToInsert);
        }

        // إشعار مقدم الخدمة لحظياً بالطلب الجديد
        _notifyProviderOnNewBooking(bookingId, bookingCode, validServiceIds);

        return BookingModel(
          id: bookingId,
          bookingCode: bookingCode,
          title: resolvedTitle,
          category: resolvedCategory,
          vendorName: resolvedVendor,
          imageUrl: resolvedImageUrl ??
              'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=600&q=80',
          bookingDate: eventDate,
          timeSlot: timeSlot,
          status: BookingStatus.pending,
          price: totalAmount,
          priceUnit: 'ر.ي',
          notes: notes,
          progressStep: 1,
          items: [
            if (validServiceIds.isNotEmpty)
              BookingItemModel(
                id: '',
                bookingId: bookingId,
                serviceId: validServiceIds.first,
                serviceName: resolvedTitle,
                serviceImageUrl: resolvedImageUrl,
                category: resolvedCategory,
                vendorName: resolvedVendor,
                unitPrice: totalAmount,
                subtotal: totalAmount,
              ),
          ],
        );
      }
      throw Exception(pe.message);
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  Future<void> _notifyProviderOnNewBooking(
    String bookingId,
    String bookingCode,
    List<String> serviceIds,
  ) async {
    try {
      if (serviceIds.isEmpty) return;
      final services = await _client
          .from('services')
          .select('provider_id, provider_profiles(user_id)')
          .inFilter('id', serviceIds);
      final Set<String> targetUserIds = {};
      for (final s in services as List) {
        final prov = s['provider_profiles'] as Map<String, dynamic>?;
        final uid = prov?['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          targetUserIds.add(uid);
        }
      }
      for (final uid in targetUserIds) {
        await _client.from('notifications').insert({
          'user_id': uid,
          'title': 'طلب حجز جديد',
          'body': 'لديك طلب حجز جديد برقم #$bookingCode في انتظار الموافقة',
          'type': 'booking_request',
          'related_booking_id': bookingId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  @override
  RealtimeSubscriptionToken subscribeToCustomerBookings({
    required String customerId,
    required void Function() onData,
    void Function()? onResync,
  }) {
    return SupabaseRealtimeService.instance.subscribeToBookings(
      customerId: customerId,
      onData: (_) => onData(),
      onResync: onResync,
    );
  }

  @override
  RealtimeSubscriptionToken subscribeToBookingItems({
    required void Function() onData,
    void Function()? onResync,
  }) {
    return SupabaseRealtimeService.instance.subscribeToBookingItems(
      onData: (_) => onData(),
      onResync: onResync,
    );
  }

  @override
  RealtimeSubscriptionToken subscribeToBookingStatusHistory({
    required void Function() onData,
    void Function()? onResync,
  }) {
    return SupabaseRealtimeService.instance.subscribeToBookingStatusHistory(
      onData: (_) => onData(),
      onResync: onResync,
    );
  }
}
