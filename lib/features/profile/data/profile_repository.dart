// Penjelasan file:
// Feature: profile
// Layer: api
// File: profile_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class ProfileRepository {
  final DioClient _client;

  ProfileRepository(this._client);

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _client.dio.get('/users/profile');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

// Method ini mengirim request untuk memperbarui data yang sudah ada di backend.
  Future<void> updateProfile({
    required String name,
    String? phone,
    String? kecamatanId,
  }) async {
    await _client.dio.put(
      '/users/profile',
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      },
    );
  }

// Method ini berisi logika utama sesuai kebutuhan fitur pada file ini.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.dio.put(
      '/users/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
