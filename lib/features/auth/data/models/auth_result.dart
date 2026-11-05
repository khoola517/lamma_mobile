import 'user_model.dart';

/// نتيجة عملية المصادقة
class AuthResult {
  final UserModel? user;
  final bool requiresEmailConfirmation;
  final String? message;
  final bool isSuccess;

  const AuthResult({
    this.user,
    this.requiresEmailConfirmation = false,
    this.message,
    this.isSuccess = true,
  });

  factory AuthResult.success({
    UserModel? user,
    String? message,
  }) {
    return AuthResult(
      user: user,
      requiresEmailConfirmation: false,
      message: message,
      isSuccess: true,
    );
  }

  factory AuthResult.emailConfirmationRequired({
    UserModel? user,
    String? message,
  }) {
    return AuthResult(
      user: user,
      requiresEmailConfirmation: true,
      message: message ??
          'تم إنشاء الحساب بنجاح! يرجى مراجعة بريدك الإلكتروني لتفعيل الحساب قبل تسجيل الدخول.',
      isSuccess: true,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(
      user: null,
      requiresEmailConfirmation: false,
      message: errorMessage,
      isSuccess: false,
    );
  }
}
