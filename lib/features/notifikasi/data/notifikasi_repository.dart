import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class NotifikasiRepository {
  final DioClient _client;

  NotifikasiRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchNotifikasiList() async {
    final response = await _client.dio.get('/notifikasi');
    final data = response.data;
    final list = data['data'] ?? (data is List ? data : []);

    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.dio.put('/notifikasi/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.dio.put('/notifikasi/read-all');
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
