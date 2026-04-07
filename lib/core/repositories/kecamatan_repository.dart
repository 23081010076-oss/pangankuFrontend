import 'package:latlong2/latlong.dart';

import '../network/dio_client.dart';

class KecamatanRepository {
  final DioClient _client;

  KecamatanRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchKecamatanList() async {
    final res = await _client.dio.get('/kecamatan');
    final payload = res.data;
    final list = payload is Map ? (payload['data'] ?? payload) : payload;
    if (list is! List) {
      return [];
    }

    return list.whereType<Map>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();
  }

  Future<Map<String, LatLng>> fetchKecamatanCoordinates() async {
    final list = await fetchKecamatanList();
    final result = <String, LatLng>{};

    for (final row in list) {
      final id = row['id']?.toString() ?? '';
      final lat = (row['lat'] as num?)?.toDouble();
      final lng = (row['lng'] as num?)?.toDouble();

      if (id.isNotEmpty && lat != null && lng != null) {
        result[id] = LatLng(lat, lng);
      }
    }

    return result;
  }
}
