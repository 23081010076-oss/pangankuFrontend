// Penjelasan file:
// Feature: core
// Layer: core-repository
// File: master_data_repository
// Fungsi utama: File ini menyediakan helper data umum yang dipakai lintas fitur.
import '../network/dio_client.dart';

// Repository ini berisi helper untuk master data umum,
// misalnya daftar komoditas dan daftar kecamatan.
class MasterDataRepository {
  final DioClient _client;

  MasterDataRepository(this._client);

  // Mengambil semua komoditas dari backend.
  Future<List<Map<String, dynamic>>> fetchKomoditas() async {
    final response = await _client.dio.get('/komoditas');
    final data = response.data;

    // Backend bisa mengirim response sebagai map atau list langsung.
    final list = (data is Map ? (data['data'] ?? data) : data);
    if (list is! List) {
      return [];
    }

    // Pastikan output selalu berbentuk List<Map<String, dynamic>>.
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Mengambil semua data kecamatan dari backend.
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
}
