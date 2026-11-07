import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/supabase_realtime_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/auth_result.dart';
import '../../data/utils/auth_exception_handler.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // 1. فحص المستخدم الحالي
  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    if (user == null || session == null) return null;

    return await _getUserProfile(user);
  }

  // 2. تسجيل الدخول
  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: identifier.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw Exception('تعذر تسجيل الدخول، يرجى التأكد من البيانات المدخلة.');
      }

      return await _getUserProfile(user);
    } catch (e) {
      throw Exception(AuthExceptionHandler.getArabicMessage(e));
    }
  }

  // 3. إنشاء حساب جديد
  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> metadata = {'full_name': name.trim()};
      if (phone != null && phone.trim().isNotEmpty) {
        metadata['phone'] = phone.trim();
      }

      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );

      final user = res.user;
      if (user == null) {
        throw Exception('تعذر إنشاء الحساب الجديد، يرجى المحاولة لاحقاً.');
      }

      // حفظ البروفايل مباشرة في جدول profiles لضمان عدم بقاء الجدول فارغاً
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': name.trim(),
          'email': email.trim(),
          'phone': phone?.trim() ?? '',
          'role': 'customer',
          'is_active': true,
        });
      } catch (e) {
        debugPrint('Direct profile upsert on register note: $e');
      }

      final newUser = UserModel(
        id: user.id,
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim() ?? '',
      );

      // هل يتطلب تأكيد البريد؟
      if (res.session == null) {
        return AuthResult.emailConfirmationRequired(user: newUser);
      }

      return AuthResult.success(
        user: newUser,
        message: 'تم إنشاء الحساب بنجاح! مرحباً بك في خِدمتي',
      );
    } catch (e) {
      throw Exception(AuthExceptionHandler.getArabicMessage(e));
    }
  }

  // 4. تسجيل الخروج
  @override
  Future<void> logout() async {
    try {
      // إلغاء ربط التوكن من Supabase قبل إنهاء الجلسة
      await FcmService.instance.unregisterToken();
    } catch (e) {
      debugPrint('FCM unregister note: $e');
    }

    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut note: $e');
    }
  }

  // 5. استعادة كلمة المرور
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw Exception(AuthExceptionHandler.getArabicMessage(e));
    }
  }

  // ==========================================
  // دالة مساعدة: تبحث في جدول profiles أولاً،
  // وإن لم تجد تقوم بإنشائه وحفظه في جدول profiles تلقائياً
  // ==========================================
  Future<UserModel> _getUserProfile(User user) async {
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        return UserModel.fromJson(profile);
      }
    } catch (_) {
      // في حال حدوث أي خطأ في قراءة جدول profiles نتجاوزه
    }

    final fallbackUser = UserModel(
      id: user.id,
      name: user.userMetadata?['full_name'] as String? ?? 'مستخدم خِدمتي',
      email: user.email ?? '',
      phone: user.userMetadata?['phone'] as String? ?? '',
    );

    // إذا كان البروفايل غير موجود في الجدول، ننشئه ونحفظه الآن تلقائياً
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': fallbackUser.name,
        'email': fallbackUser.email,
        'phone': fallbackUser.phone,
        'role': 'customer',
        'is_active': true,
      });
    } catch (e) {
      debugPrint('Auto-create profile in profiles table note: $e');
    }

    return fallbackUser;
  }
  //edite profile

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لتحديث الملف الشخصي.');
    }

    final updateData = <String, dynamic>{
      'full_name': name.trim(),
      'phone': phone.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarUrl != null) {
      updateData['avatar_url'] = avatarUrl;
    }

    try {
      await _client.from('profiles').update(updateData).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating profiles table: $e');
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name.trim(),
            'phone': phone.trim(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );
    } catch (_) {}

    return await _getUserProfile(user);
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لرفع الصورة.');
    }

    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final fileName =
        '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
    final storagePath = 'avatars/$fileName';

    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            contentType: 'image/$cleanExt',
            upsert: true,
          ),
        );

    return _client.storage.from('avatars').getPublicUrl(storagePath);
  }

  @override
  RealtimeSubscriptionToken subscribeToUserProfile({
    required String userId,
    required void Function(Map<String, dynamic> record) onUpdated,
    void Function()? onResync,
  }) {
    return SupabaseRealtimeService.instance.subscribeToProfiles(
      userId: userId,
      onData: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onUpdated(payload.newRecord);
        }
      },
      onResync: onResync,
    );
  }
}
