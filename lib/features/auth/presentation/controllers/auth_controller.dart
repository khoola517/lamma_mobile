import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/auth_result.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthController({AuthRepository? repository})
      : _repository = repository ?? SupabaseAuthRepository() {
    _initAuthListener();
  }

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _successMessage;
  bool _requiresEmailConfirmation = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get requiresEmailConfirmation => _requiresEmailConfirmation;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  void _initAuthListener() {
    try {
      _authSubscription = _repository.onAuthStateChange.listen((data) async {
        final event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        } else if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          // جلب بيانات البروفايل المحدثة
          final currentUser = await _repository.getCurrentUser();
          if (currentUser != null) {
            _user = currentUser;
            _status = AuthStatus.authenticated;
            notifyListeners();
          }
        }
      });
    } catch (_) {
      // تجاهل إذا كانت البيئة لا تدعم stream
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      _user = await _repository.getCurrentUser();
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _user =
          await _repository.login(identifier: identifier, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (result.requiresEmailConfirmation) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        _requiresEmailConfirmation = true;
        _successMessage = result.message;
      } else {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _requiresEmailConfirmation = false;
        _successMessage = result.message;
      }

      notifyListeners();
      return result;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    }
  }

  Future<bool> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.resetPassword(email.trim());
      _status = AuthStatus.unauthenticated;
      _successMessage =
          'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني بنجاح.';
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
  // edite profile

  Future<bool> updateProfile({
    required String name,
    required String phone,
    Uint8List? imageBytes,
    String? fileExtension,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      String? avatarUrl;
      if (imageBytes != null) {
        avatarUrl = await _repository.uploadAvatar(
          imageBytes: imageBytes,
          fileExtension: fileExtension ?? 'jpg',
        );
      }

      _user = await _repository.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.authenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
