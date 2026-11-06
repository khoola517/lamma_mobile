import 'package:flutter/material.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../data/repositories/supabase_notifications_repository.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;
  final IconData icon;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead = false,
    required this.icon,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
      icon: icon,
    );
  }
}

class NotificationsController extends ChangeNotifier {
  final NotificationsRepository _repository;
  bool _isLoading = false;
  bool _lastAuthStatus = false;
  final List<RealtimeSubscriptionToken> _realtimeTokens = [];

  // تم حذف البيانات الوهمية (Mock Data) والاعتماد حصراً على بيانات Supabase الحية
  List<NotificationItem> _notifications = [];

  NotificationsController({NotificationsRepository? repository})
      : _repository = repository ?? SupabaseNotificationsRepository();

  bool get isLoading => _isLoading;
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// يتفاعل تلقائياً مع تسجيل الدخول والخروج عبر شجرة الـ Provider
  void onAuthChanged(bool isAuthenticated) {
    if (_lastAuthStatus != isAuthenticated) {
      _lastAuthStatus = isAuthenticated;
      if (isAuthenticated) {
        _subscribeToRealtime();
        loadNotifications();
      } else {
        _unsubscribeFromRealtime();
        _notifications = [];
        notifyListeners();
      }
    }
  }

  /// الاشتراك في تدفق البث اللحظي عبر المستودع
  void _subscribeToRealtime() {
    _unsubscribeFromRealtime();
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeTokens.add(
      _repository.subscribeToUserNotifications(
        userId: userId,
        onData: (record, event) {
          loadNotifications();
        },
        onResync: loadNotifications,
      ),
    );

    _realtimeTokens.add(
      SupabaseRealtimeService.instance.onReconnected(() {
        loadNotifications();
      }),
    );
  }

  void _unsubscribeFromRealtime() {
    for (final token in _realtimeTokens) {
      token.cancel();
    }
    _realtimeTokens.clear();
  }

  /// جلب الإشعارات الفعلية من Supabase
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await _repository.getMyNotifications();
      _notifications = remote;
    } catch (_) {
      // إبقاء القائمة الحالية عند حدوث خطأ في الاتصال
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    try {
      await _repository.markAllAsRead();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await _repository.markAsRead(id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _unsubscribeFromRealtime();
    super.dispose();
  }
}
