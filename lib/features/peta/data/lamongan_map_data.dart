// Penjelasan file:
// Feature: peta
// Layer: data
// File: lamongan_map_data
// Fungsi utama: Menyimpan acuan koordinat WGS84 Kabupaten Lamongan untuk peta.
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LamonganMapData {
  LamonganMapData._();

  static const double north = -6.8222246;
  static const double south = -7.4250213;
  static const double west = 112.0110758;
  static const double east = 112.6138726;

  static const LatLng center = LatLng(-7.1229318, 112.3281935);

  static final LatLngBounds bounds = LatLngBounds.unsafe(
    north: north,
    south: south,
    west: west,
    east: east,
  );

  static const Map<String, LatLng> coordinatesByKecamatan = {
    'Babat': LatLng(-7.106111111, 112.212777777),
    'Bluluk': LatLng(-7.293333333, 112.126388888),
    'Brondong': LatLng(-6.9025, 112.239166666),
    'Deket': LatLng(-7.095555555, 112.453888888),
    'Glagah': LatLng(-7.050096934, 112.494329095),
    'Kalitengah': LatLng(-7.014444444, 112.4),
    'Karangbinangun': LatLng(-7.030555555, 112.449722222),
    'Karanggeneng': LatLng(-7.016111111, 112.34),
    'Kedungpring': LatLng(-7.183888888, 112.204166666),
    'Kembangbahu': LatLng(-7.197777777, 112.356944444),
    'Lamongan': LatLng(-7.1225, 112.382777777),
    'Laren': LatLng(-6.98342, 112.282922),
    'Maduran': LatLng(-7.007210781, 112.28094918),
    'Mantup': LatLng(-7.274444444, 112.344722222),
    'Modo': LatLng(-7.240557227, 112.148072233),
    'Ngimbang': LatLng(-7.298611111, 112.193055555),
    'Paciran': LatLng(-6.884166666, 112.371388888),
    'Pucuk': LatLng(-7.099444444, 112.291944444),
    'Sambeng': LatLng(-7.297485371, 112.270803663),
    'Sarirejo': LatLng(-7.190414437, 112.450537588),
    'Sekaran': LatLng(-7.061515946, 112.276860206),
    'Solokuro': LatLng(-6.93, 112.353611111),
    'Sugio': LatLng(-7.174444444, 112.278888888),
    'Sukodadi': LatLng(-7.113055555, 112.335833333),
    'Sukorame': LatLng(-7.345304587, 112.111505934),
    'Tikung': LatLng(-7.176944444, 112.44),
    'Turi': LatLng(-7.096944928, 112.373971711),
  };

  static LatLng? coordinateForKecamatan(String name) {
    final normalized = _normalizeName(name);
    for (final entry in coordinatesByKecamatan.entries) {
      if (_normalizeName(entry.key) == normalized) return entry.value;
    }
    return null;
  }

  static LatLng resolvePoint({
    required String kecamatanName,
    required double lat,
    required double lng,
  }) {
    final referencePoint = coordinateForKecamatan(kecamatanName);
    if (referencePoint != null) return referencePoint;

    final apiPoint = LatLng(lat, lng);
    if (contains(apiPoint)) return apiPoint;
    return center;
  }

  static bool contains(LatLng point) {
    return point.latitude >= south &&
        point.latitude <= north &&
        point.longitude >= west &&
        point.longitude <= east;
  }

  static String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^kecamatan\s+'), '');
  }
}
