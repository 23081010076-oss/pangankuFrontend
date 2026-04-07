import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class StokRepository {
  final DioClient _client;

  StokRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchStokList({
    String? komoditasId,
    String? kecamatanId,
  }) async {
    final params = <String, dynamic>{'limit': 200};
    if (komoditasId != null) {
      params['komoditas_id'] = komoditasId;
    }
    if (kecamatanId != null) {
      params['kecamatan_id'] = kecamatanId;
    }

    final response = await _client.dio.get('/stok', queryParameters: params);
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

  Future<void> saveStok({
    required String komoditasId,
    required String kecamatanId,
    required double stokKg,
    required double kapasitasKg,
  }) async {
    await _client.dio.post(
      '/stok',
      data: {
        'komoditas_id': komoditasId,
        'kecamatan_id': kecamatanId,
        'stok_kg': stokKg,
        'kapasitas_kg': kapasitasKg,
      },
    );
  }

  Future<void> deleteStok(String id) async {
    await _client.dio.delete('/stok/$id');
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
