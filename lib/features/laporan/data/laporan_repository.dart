import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class LaporanRepository {
  final DioClient _client;

  LaporanRepository(this._client);

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

  Future<void> updateLaporanStatus({
    required String id,
    required String status,
  }) async {
    await _client.dio.put('/laporan/$id/status', data: {'status': status});
  }

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
