import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/firebase_options.dart';
import '../config/supabase_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM Background message handled: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'إشعارات خِدمتي',
    description: 'قناة إشعارات الحجوزات والطلبات وتحديثات الحساب',
    importance: Importance.max,
  );

  String? _currentToken;
  bool _initialized = false;

  /// تهيئة خدمة إشعارات Firebase في تطبيق الموبايل
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. تهيئة تطبيق Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. تسجيل معالج الرسائل في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. طلب الصلاحيات من المستخدم
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 4. تهيئة قناة الإشعارات المحلية لـ Android (Heads-up Notifications)
      if (!kIsWeb && Platform.isAndroid) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInit);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            _handleNotificationClick(response.payload);
          },
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 5. الاستماع للرسائل في الواجهة الأمامية (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 6. الاستماع للنقر على الإشعار عند فتح التطبيق
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened from background: ${message.data}');
        _handleNotificationClick(jsonEncode(message.data));
      });

      // فحص الإشعار الأولي إذا فتح التطبيق من حالة الإنهاء (Terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(jsonEncode(initialMessage.data));
      }

      // 7. الاستماع لتحديثات التوكن
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _currentToken = newToken;
        syncTokenWithSupabase();
      });

      // 8. الاستماع لتغيرات حالة المصادقة في Supabase
      _initAuthListener();

      _initialized = true;
      debugPrint('FCM Service initialized successfully for Mobile');
    } catch (e) {
      debugPrint('FCM Service initialization error: $e');
    }
  }

  /// إظهار الإشعار المحلي عندما يكون التطبيق مفتوحاً في الواجهة الأمامية
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// معالجة النقر على الإشعار
  void _handleNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Handled notification click payload: $data');
      // Navigation hooks can be routed according to data['booking_id'] or data['type']
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  /// ربط الخدمة بحالة الدخول والخروج في Supabase
  void _initAuthListener() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        syncTokenWithSupabase();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentToken = null;
      }
    });

    // مزامنة فورية إذا كان المستخدم مسجلاً بالفعل
    if (SupabaseConfig.client.auth.currentUser != null) {
      syncTokenWithSupabase();
    }
  }

  /// تسجيل توكن الجهاز الحالي في جدول user_fcm_tokens على Supabase
  Future<void> syncTokenWithSupabase() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      debugPrint('FCM: User not authenticated, skipping token registration');
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM: Failed to obtain device token');
        return;
      }

      _currentToken = token;

      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final deviceInfo = {
        'platform': platform,
        'os_version': Platform.operatingSystemVersion,
        'registered_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client.rpc(
        'register_fcm_token',
        params: {
          'p_fcm_token': token,
          'p_platform': platform,
          'p_device_info': deviceInfo,
        },
      );

      debugPrint('FCM Token registered successfully in Supabase for user: ${user.id}');
    } catch (e) {
      debugPrint('FCM Token registration error in Supabase: $e');
    }
  }

  /// إلغاء ربط التوكن عند تسجيل الخروج
  Future<void> unregisterToken() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final token = _currentToken ?? await _messaging.getToken();

    if (user == null || token == null || token.isEmpty) return;

    try {
      await SupabaseConfig.client.rpc(
        'unregister_fcm_token',
        params: {
          'p_fcm_token': token,
        },
      );
      debugPrint('FCM Token unregistered successfully from Supabase');
    } catch (e) {
      debugPrint('FCM Token unregistration error: $e');
    } finally {
      _currentToken = null;
    }
  }
}

