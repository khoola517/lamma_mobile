import '../../presentation/controllers/notifications_controller.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> getMyNotifications();
  Stream<List<NotificationItem>> getNotificationsStream();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}

