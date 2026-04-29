// Penjelasan file:
// Feature: laporan
// Layer: api
// File: laporan_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class LaporanRepository {
  final DioClient _client;

  LaporanRepository(this._client);

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<List<Map<String, dynamic>>> fetchLaporanList() async {
    final response = await _client.dio.get('/laporan');
    final data = response.data;
    final list = data is Map ? (data['data'] ?? []) : data ?? [];

    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

// Method ini mengirim request untuk menambahkan data baru ke backend.
  Future<void> createLaporan({
    required String jenisMasalah,
    required String deskripsi,
    required String kecamatanId,
    required int prioritas,
    String? fotoUrl,
  }) async {
    await _client.dio.post(
      '/laporan',
      data: {
        'jenis_masalah': jenisMasalah,
        'deskripsi': deskripsi,
        'kecamatan_id': kecamatanId,
        'prioritas': prioritas,
        if (fotoUrl != null) 'foto_url': fotoUrl,
      },
    );
  }

// Method ini mengirim request untuk memperbarui data yang sudah ada di backend.
  Future<void> updateLaporanStatus({
    required String id,
    required String status,
  }) async {
    await _client.dio.put('/laporan/$id/status', data: {'status': status});
  }

// Method ini menghapus data berdasarkan id atau identitas tertentu.
  Future<void> deleteLaporan(String id) async {
    await _client.dio.delete('/laporan/$id');
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
