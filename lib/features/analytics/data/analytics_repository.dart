// Penjelasan file:
// Feature: analytics
// Layer: api
// File: analytics_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class AnalyticsRepository {
  final DioClient _client;

  AnalyticsRepository(this._client);

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<Map<String, dynamic>> fetchDashboardStats({
    required String periode,
  }) async {
    final response = await _client.dio.get(
      '/analytics/dashboard',
      queryParameters: {'periode': periode},
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<List<Map<String, dynamic>>> fetchStatusPangan() async {
    final response = await _client.dio.get('/analytics/status-pangan');
    final data = response.data;
    final list = (data is List) ? data : (data['data'] ?? []);

    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
