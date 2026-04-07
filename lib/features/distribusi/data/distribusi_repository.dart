import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class DistribusiRepository {
  final DioClient _client;

  DistribusiRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchDistribusiList({String? status}) async {
    final params = <String, dynamic>{'limit': 50};
    if (status != null && status != 'semua') {
      params['status'] = status;
    }

    final response = await _client.dio.get('/distribusi', queryParameters: params);
    final data = response.data;
    final list = data['data'] ?? (data is List ? data : []);

    if (list is! List) {
      return [];
    }

    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createDistribusi({
    required String dariKecamatanId,
    required String keKecamatanId,
    required String komoditasId,
    required double jumlahKg,
    required String jadwalBerangkat,
    String? namaDriver,
    String? namaKendaraan,
  }) async {
    final body = <String, dynamic>{
      'dari_kecamatan_id': dariKecamatanId,
      'ke_kecamatan_id': keKecamatanId,
      'komoditas_id': komoditasId,
      'jumlah_kg': jumlahKg,
      'jadwal_berangkat': jadwalBerangkat,
      if (namaDriver != null) 'nama_driver': namaDriver,
      if (namaKendaraan != null) 'nama_kendaraan': namaKendaraan,
    };

    await _client.dio.post('/distribusi', data: body);
  }

  Future<void> updateDistribusiStatus({
    required String id,
    required String status,
  }) async {
    await _client.dio.put('/distribusi/$id/status', data: {'status': status});
  }

  Future<void> deleteDistribusi(String id) async {
    await _client.dio.delete('/distribusi/$id');
  }

  Future<Map<String, dynamic>> fetchDistribusiRoute(String distribusiId) async {
    final res = await _client.dio.get('/distribusi/$distribusiId/rute');
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    return {};
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
