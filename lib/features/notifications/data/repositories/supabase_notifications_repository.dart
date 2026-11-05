import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../presentation/controllers/notifications_controller.dart';

class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient _client;

  SupabaseNotificationsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<List<NotificationItem>> getMyNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((n) => _mapToNotificationItem(n as Map<String, dynamic>)).toList();
  }

  @override
  Stream<List<NotificationItem>> getNotificationsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((n) => _mapToNotificationItem(n)).toList());
  }

  NotificationItem _mapToNotificationItem(Map<String, dynamic> n) {
    final type = (n['type'] as String?) ?? '';
    IconData icon = Icons.notifications_outlined;
    if (type.contains('confirm') || type.contains('success')) {
      icon = Icons.check_circle_outline;
    } else if (type.contains('created') || type.contains('request')) {
      icon = Icons.mark_email_unread_outlined;
    } else if (type.contains('offer') || type.contains('discount')) {
      icon = Icons.local_offer_outlined;
    } else if (type.contains('warning') || type.contains('update')) {
      icon = Icons.error_outline;
    } else if (type.contains('cancel')) {
      icon = Icons.cancel_outlined;
    }

    final createdAtStr = n['created_at'] as String?;
    String timeAgo = 'الآن';
    if (createdAtStr != null) {
      final date = DateTime.tryParse(createdAtStr);
      if (date != null) {
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = 'منذ ${diff.inDays} يوم';
        } else if (diff.inHours > 0) {
          timeAgo = 'منذ ${diff.inHours} ساعة';
        } else if (diff.inMinutes > 0) {
          timeAgo = 'منذ ${diff.inMinutes} دقيقة';
        }
      }
    }

    return NotificationItem(
      id: n['id'] as String? ?? '',
      title: (n['title'] as String?) ?? 'إشعار جديد',
      body: (n['body'] as String?) ?? '',
      timeAgo: timeAgo,
      isRead: (n['is_read'] as bool?) ?? false,
      icon: icon,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }
}
