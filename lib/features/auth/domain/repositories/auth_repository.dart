import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/auth_result.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login({
    required String identifier,
    required String password,
  });
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });
  Future<void> logout();
  Future<void> resetPassword(String email);
  Stream<AuthState> get onAuthStateChange;
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String? avatarUrl,
  });
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String fileExtension,
  });
}

