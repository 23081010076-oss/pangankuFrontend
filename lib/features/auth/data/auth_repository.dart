// Penjelasan file:
// Feature: auth
// Layer: api
// File: auth_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';

class AuthUserData {
  final String name;
  final String role;
  final String userId;

  const AuthUserData({
    required this.name,
    required this.role,
    required this.userId,
  });
}

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class AuthRepository {
  final DioClient _client;
  final FlutterSecureStorage _storage;

  AuthRepository(
    this._client, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

// Method ini mencoba memulihkan sesi atau data lama yang pernah disimpan.
  Future<AuthUserData?> restoreSession() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) {
      return null;
    }

    try {
      final res = await _client.dio.get('/auth/me');
      return AuthUserData(
        name: res.data['name']?.toString() ?? '',
        role: res.data['role']?.toString() ?? 'petani',
        userId: res.data['id']?.toString() ?? '',
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

// Method ini menjalankan proses login ke backend dan mengembalikan data user.
  Future<AuthUserData> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return _saveTokensAndUser(res.data as Map<String, dynamic>);
  }

// Method ini menjalankan proses pendaftaran user baru ke backend.
  Future<AuthUserData> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final res = await _client.dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
    );

    return _saveTokensAndUser(res.data as Map<String, dynamic>);
  }

// Method ini membersihkan sesi login atau memberitahu backend bahwa user logout.
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // no-op
    }
    await clearSession();
  }

// Method ini berisi logika utama sesuai kebutuhan fitur pada file ini.
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  String getErrorMessage(DioException e) => _client.getErrorMessage(e);

// Method ini berisi logika utama sesuai kebutuhan fitur pada file ini.
  Future<AuthUserData> _saveTokensAndUser(Map<String, dynamic> data) async {
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};

    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: data['access_token']?.toString(),
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: data['refresh_token']?.toString(),
    );
    await _storage.write(
      key: AppConstants.userRoleKey,
      value: user['role']?.toString() ?? 'petani',
    );
    await _storage.write(
      key: AppConstants.userNameKey,
      value: user['name']?.toString() ?? '',
    );
    await _storage.write(
      key: AppConstants.userIdKey,
      value: user['id']?.toString() ?? '',
    );

    return AuthUserData(
      name: user['name']?.toString() ?? '',
      role: user['role']?.toString() ?? 'petani',
      userId: user['id']?.toString() ?? '',
    );
  }
}
