// Penjelasan file:
// Feature: notifikasi
// Layer: api
// File: notifikasi_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class NotifikasiRepository {
  final DioClient _client;

  NotifikasiRepository(this._client);

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini berisi logika utama sesuai kebutuhan fitur pada file ini.
  Future<void> markAsRead(String id) async {
    await _client.dio.put('/notifikasi/$id/read');
  }

// Method ini berisi logika utama sesuai kebutuhan fitur pada file ini.
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
