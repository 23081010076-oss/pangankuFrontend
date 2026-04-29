// Penjelasan file:
// Feature: core
// Layer: core-repository
// File: kecamatan_repository
// Fungsi utama: File ini menyediakan helper data umum yang dipakai lintas fitur.
import 'package:latlong2/latlong.dart';

import '../network/dio_client.dart';

// Repository ini khusus menangani data kecamatan yang dipakai lintas fitur,
// misalnya untuk dropdown wilayah atau koordinat peta.
class KecamatanRepository {
  // DioClient dipakai untuk request ke backend.
  final DioClient _client;

  KecamatanRepository(this._client);

  // Mengambil semua data kecamatan dari backend.
  Future<List<Map<String, dynamic>>> fetchKecamatanList() async {
    final res = await _client.dio.get('/kecamatan');
    final payload = res.data;

    // Backend bisa mengirim response sebagai { data: [...] } atau langsung list.
    final list = payload is Map ? (payload['data'] ?? payload) : payload;
    if (list is! List) {
      return [];
    }

    // Ubah setiap item menjadi Map<String, dynamic> agar mudah dipakai di aplikasi.
    return list.whereType<Map>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();
  }

  // Mengambil koordinat kecamatan lalu mengubahnya menjadi map:
  // key = id kecamatan, value = LatLng untuk kebutuhan peta.
  Future<Map<String, LatLng>> fetchKecamatanCoordinates() async {
    final list = await fetchKecamatanList();
    final result = <String, LatLng>{};

    // Loop semua kecamatan dan ambil field id, latitude, longitude.
    for (final row in list) {
      final id = row['id']?.toString() ?? '';
      final lat = (row['lat'] as num?)?.toDouble();
      final lng = (row['lng'] as num?)?.toDouble();

      // Hanya masukkan data yang lengkap.
      if (id.isNotEmpty && lat != null && lng != null) {
        result[id] = LatLng(lat, lng);
      }
    }

    return result;
  }
}
