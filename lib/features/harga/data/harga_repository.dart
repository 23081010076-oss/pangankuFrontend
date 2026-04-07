import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class HargaRepository {
  final DioClient _client;

  HargaRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchLatestHarga() async {
    final response = await _client.dio.get('/harga/latest');
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? []) : data ?? []);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchKomoditas() async {
    final response = await _client.dio.get('/komoditas');
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? []) : data ?? []);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchKecamatan() async {
    final response = await _client.dio.get('/kecamatan');
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? []) : data ?? []);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchHargaTrend({
    required String komoditasId,
    required String periode,
  }) async {
    final response = await _client.dio.get(
      '/harga/trend/$komoditasId',
      queryParameters: {'periode': periode},
    );

    final raw = response.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    if (list is! List) {
      return [];
    }

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> fetchForecast({
    required String komoditasId,
    String? kecamatanId,
  }) async {
    final response = await _client.dio.get(
      '/harga/forecast',
      queryParameters: {
        'komoditas_id': komoditasId,
        if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    }
    return {};
  }

  Future<void> createHarga({
    required String komoditasId,
    required String kecamatanId,
    required double hargaPerKg,
    required String tanggal,
  }) async {
    await _client.dio.post(
      '/harga',
      data: {
        'komoditas_id': komoditasId,
        'kecamatan_id': kecamatanId,
        'harga_per_kg': hargaPerKg,
        'tanggal': tanggal,
      },
    );
  }

  Future<void> updateHarga({
    required String id,
    required double hargaPerKg,
    required String tanggal,
  }) async {
    await _client.dio.put(
      '/harga/$id',
      data: {
        'harga_per_kg': hargaPerKg,
        'tanggal': tanggal,
      },
    );
  }

  Future<void> deleteHarga(String id) async {
    await _client.dio.delete('/harga/$id');
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
