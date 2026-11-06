import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../presentation/controllers/notifications_controller.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> getMyNotifications();
  Stream<List<NotificationItem>> getNotificationsStream();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();

  RealtimeSubscriptionToken subscribeToUserNotifications({
    required String userId,
    required void Function(Map<String, dynamic> record, PostgresChangeEvent event) onData,
    void Function()? onResync,
  });
}

