// Doc:
// Tujuan: Menjadi repository admin untuk CRUD master data, termasuk komoditas dengan metadata gambar.
// Dipakai oleh: Halaman admin komoditas, harga, stok, kecamatan, dan luas lahan.
// Dependensi utama: DioClient dan endpoint backend admin/master data.
// Fungsi public/utama: fetchKomoditas, createKomoditas, updateKomoditas, deleteKomoditas, fetchKecamatan, create/update/delete modul admin lain.
// Side effect penting: HTTP GET/POST/PUT/DELETE dan multipart upload foto; write pada master data komoditas/kecamatan/harga/stok/luas lahan.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class AdminRepository {
  final DioClient _client;

  AdminRepository(this._client);

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini mengirim request untuk menambahkan data baru ke backend.
  Future<void> createKomoditas({
    required String nama,
    required String satuan,
    required String kategori,
    String? gambarUrl,
  }) async {
    await _client.dio.post(
      '/komoditas',
      data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
        'gambar_url': gambarUrl,
      },
    );
  }

// Method ini mengirim request untuk memperbarui data yang sudah ada di backend.
  Future<void> updateKomoditas({
    required String id,
    required String nama,
    required String satuan,
    required String kategori,
    String? gambarUrl,
  }) async {
    await _client.dio.put(
      '/komoditas/$id',
      data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
        'gambar_url': gambarUrl,
      },
    );
  }

// Method ini menghapus data berdasarkan id atau identitas tertentu.
  Future<void> deleteKomoditas(String id) async {
    await _client.dio.delete('/komoditas/$id');
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini mengirim request untuk menambahkan data baru ke backend.
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

// Method ini mengirim request untuk memperbarui data yang sudah ada di backend.
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

// Method ini menghapus data berdasarkan id atau identitas tertentu.
  Future<void> deleteKecamatan(String id) async {
    await _client.dio.delete('/kecamatan/$id');
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini menyimpan data ke backend, baik sebagai data baru maupun update.
  Future<void> saveStok(Map<String, dynamic> data) async {
    await _client.dio.post('/stok', data: data);
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<List<Map<String, dynamic>>> fetchLuasLahan({
    int page = 1,
    int limit = 200,
    String? komoditasId,
    String? kecamatanId,
    int? tahun,
  }) async {
    final response = await _client.dio.get(
      '/luas-lahan',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (komoditasId != null) 'komoditas_id': komoditasId,
        if (kecamatanId != null) 'kecamatan_id': kecamatanId,
        if (tahun != null) 'tahun': tahun,
      },
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

// Method ini menyimpan data ke backend, baik sebagai data baru maupun update.
  Future<void> saveLuasLahan(Map<String, dynamic> data) async {
    await _client.dio.post('/luas-lahan', data: data);
  }

// Method ini menghapus data berdasarkan id atau identitas tertentu.
  Future<void> deleteLuasLahan(String id) async {
    await _client.dio.delete('/luas-lahan/$id');
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini mengirim request untuk menambahkan data baru ke backend.
  Future<void> createHarga(Map<String, dynamic> data) async {
    await _client.dio.post('/harga', data: data);
  }

// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
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

// Method ini mengirim request untuk memperbarui data yang sudah ada di backend.
  Future<void> updateUserRole({
    required String id,
    required String role,
  }) async {
    await _client.dio.put('/users/$id/role', data: {'role': role});
  }

// Method ini mengunggah file foto ke backend dan mengembalikan URL gambar.
  Future<String> uploadFoto(String filePath) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _client.dio.post(
      '/upload/foto',
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}
