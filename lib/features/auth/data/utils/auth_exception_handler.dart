
import 'package:supabase_flutter/supabase_flutter.dart';

/// معالج أخطاء المصادقة لتحويل الرسائل التقنية إلى رسائل عربية واضحة وآمنة
class AuthExceptionHandler {
  AuthExceptionHandler._();

  static String getArabicMessage(dynamic error) {
    if (error == null) {
      return 'حدث خطأ غير معروف، يرجى المحاولة لاحقاً.';
    }

    final String errorText = error.toString().toLowerCase();

    // 1. معالجة أخطاء الرابط الافتراضي الوهمي (demo URL) وأخطاء الشبكة والـ DNS
    if (errorText.contains('demo-khadematy.supabase.co')) {
      return 'لم يتم ربط التطبيق بمشروع Supabase الفعلي بعد! الرابط الحالي هو عنوان تجريبي (demo-khadematy.supabase.co). يرجى وضع رابط مشروعك (SUPABASE_URL) والمفتاح العام (SUPABASE_ANON_KEY) في ملف lib/core/config/supabase_config.dart.';
    }

    if (errorText.contains('failed host lookup') ||
        errorText.contains('socket') ||
        errorText.contains('clientexception') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('connection refused') ||
        errorText.contains('connection timed out') ||
        errorText.contains('no address associated with hostname')) {
      return 'تعذر الاتصال بالخادم. يرجى التأكد من اتصالك بالإنترنت وصحة رابط مشروع Supabase.';
    }

    // 2. معالجة أخطاء Supabase AuthException
    if (error is AuthException) {
      final code = (error.code ?? '').toLowerCase();
      final msg = error.message.toLowerCase();

      // أخطاء بيانات الاعتماد
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid email or password')) {
        return 'بيانات تسجيل الدخول غير صحيحة. يرجى التأكد من البريد الإلكتروني وكلمة المرور.';
      }

      // البريد الإلكتروني مسجل مسبقاً
      if (code == 'user_already_exists' ||
          msg.contains('user already registered') ||
          msg.contains('already exists')) {
        return 'هذا البريد الإلكتروني مسجل بالفعل. يمكنك تسجيل الدخول أو استخدام استعادة كلمة المرور.';
      }

      // تأكيد البريد الإلكتروني
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return 'لم يتم تأكيد البريد الإلكتروني بعد. يرجى فتح بريدك والنقر على رابط التفعيل.';
      }

      // قيود المعدل / تكرار المحاولات
      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        return 'تم تجاوز عدد المحاولات المسموح به مؤقتاً. يرجى الانتظار بضع دقائق قبل المحاولة مجدداً.';
      }

      // كلمة المرور ضعيفة
      if (code == 'weak_password' ||
          msg.contains('weak password') ||
          msg.contains('password should be at least')) {
        return 'كلمة المرور ضعيفة. يرجى إدخال كلمة مرور تحتوي على 6 أحرف على الأقل.';
      }

      // البريد الإلكتروني غير صالح
      if (msg.contains('invalid email') || msg.contains('unable to validate email')) {
        return 'صيغة البريد الإلكتروني غير صالحة. يرجى إدخال بريد صحيح.';
      }

      // المستخدم غير موجود
      if (code == 'user_not_found' || msg.contains('user not found')) {
        return 'لم يتم العثور على حساب مسجل بهذا البريد الإلكتروني.';
      }

      // أخطاء متعلقة بالجلسة أو الـ Token
      if (msg.contains('token has expired') || msg.contains('jwt expired')) {
        return 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.';
      }

      return 'تعذر إتمام العملية: ${error.message}';
    }

    final errorString = error.toString().replaceAll('Exception: ', '').trim();
    if (errorString.isNotEmpty && !errorString.startsWith('AssertionError')) {
      return errorString;
    }

    return 'حدث خطأ غير متوقع أثناء معالجة الطلب. يرجى المحاولة لاحقاً.';
  }
}
