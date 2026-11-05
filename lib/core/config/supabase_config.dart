import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// تكوين Supabase المركزي والآمن
/// يعتمد على متغيرات البيئة Compile-time (--dart-define) مع دعم القيم الافتراضية
class SupabaseConfig {
  SupabaseConfig._();

  /// عنوان مشروع Supabase العام
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lynrgiiseawlulwpdesv.supabase.co',
  );

  /// المفتاح العام (Anon / Publishable Key)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_gBDSZglDdnrWJ14Pz2ti2Q_gjSQ7yhW',
  );

  /// رابط Supabase بعد إزالة أي زيادات مثل /rest/v1/ أو الشَرطات الزائدة
  static String get cleanUrl {
    var url = supabaseUrl.trim();
    if (url.endsWith('/rest/v1/')) {
      url = url.substring(0, url.length - 9);
    } else if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - 8);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// هل تم تزويد التطبيق بمفاتيح فعلية؟
  static bool get isConfigured =>
      cleanUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !cleanUrl.contains('demo-khadematy.supabase.co');

  /// العميل البرمجي لـ Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// تهيئة عميل Supabase بأمان عند بدء التطبيق
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: cleanUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase Initialization Note: Running in fallback mode ($e)');
    }
  }
}
