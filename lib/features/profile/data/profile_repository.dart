import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class ProfileRepository {
  final DioClient _client;

  ProfileRepository(this._client);

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _client.dio.get('/users/profile');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

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
