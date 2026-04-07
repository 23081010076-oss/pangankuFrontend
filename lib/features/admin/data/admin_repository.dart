import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class AdminRepository {
  final DioClient _client;

  AdminRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchKomoditas() async {
    final response = await _client.dio.get('/komoditas');
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? data) : data);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> createKomoditas({
    required String nama,
    required String satuan,
    required String kategori,
  }) async {
    await _client.dio.post(
      '/komoditas',
      data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
      },
    );
  }

  Future<void> updateKomoditas({
    required String id,
    required String nama,
    required String satuan,
    required String kategori,
  }) async {
    await _client.dio.put(
      '/komoditas/$id',
      data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
      },
    );
  }

  Future<void> deleteKomoditas(String id) async {
    await _client.dio.delete('/komoditas/$id');
  }

  Future<List<Map<String, dynamic>>> fetchKecamatan() async {
    final response = await _client.dio.get('/kecamatan');
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? data) : data);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> createKecamatan({
    required String nama,
    required double lat,
    required double lng,
    required double luasHa,
  }) async {
    await _client.dio.post(
      '/kecamatan',
      data: {
        'nama': nama,
        'lat': lat,
        'lng': lng,
        'luas_ha': luasHa,
      },
    );
  }

  Future<void> updateKecamatan({
    required String id,
    required String nama,
    required double lat,
    required double lng,
    required double luasHa,
  }) async {
    await _client.dio.put(
      '/kecamatan/$id',
      data: {
        'nama': nama,
        'lat': lat,
        'lng': lng,
        'luas_ha': luasHa,
      },
    );
  }

  Future<void> deleteKecamatan(String id) async {
    await _client.dio.delete('/kecamatan/$id');
  }

  Future<List<Map<String, dynamic>>> fetchStok({int limit = 200}) async {
    final response = await _client.dio.get(
      '/stok',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    final list = (data is Map ? (data['data'] ?? []) : data);
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> saveStok(Map<String, dynamic> data) async {
    await _client.dio.post('/stok', data: data);
  }

  Future<Map<String, dynamic>> fetchHargaPage({
    required int page,
    required int limit,
    String? komoditasId,
    String? kecamatanId,
    String order = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'order': order,
      if (komoditasId != null) 'komoditas_id': komoditasId,
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
    };

    final response = await _client.dio.get('/harga', queryParameters: params);
    final raw = response.data;
    final items = List<Map<String, dynamic>>.from(
      raw is Map ? (raw['data'] ?? []) : raw,
    );
    final total = raw is Map ? (raw['total'] as int? ?? 0) : items.length;

    return {'items': items, 'total': total};
  }

  Future<void> createHarga(Map<String, dynamic> data) async {
    await _client.dio.post('/harga', data: data);
  }

  Future<Map<String, dynamic>> fetchUsers({
    required int page,
    required int limit,
    String? role,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _client.dio.get('/users', queryParameters: params);
    final raw = response.data as Map<String, dynamic>;
    return {
      'items': List<Map<String, dynamic>>.from(raw['data'] ?? []),
      'total': (raw['total'] ?? 0) as int,
    };
  }

  Future<void> updateUserRole({required String id, required String role}) async {
    await _client.dio.put('/users/$id/role', data: {'role': role});
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
