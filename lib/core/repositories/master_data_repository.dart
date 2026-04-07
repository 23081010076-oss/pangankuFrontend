import '../network/dio_client.dart';

class MasterDataRepository {
  final DioClient _client;

  MasterDataRepository(this._client);

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
