import 'package:flutter_test/flutter_test.dart';
import 'package:panganku_mobile/features/peta/data/lamongan_map_data.dart';

void main() {
  test('Lamongan map data contains 27 kecamatan inside regency bounds', () {
    expect(LamonganMapData.coordinatesByKecamatan, hasLength(27));

    for (final entry in LamonganMapData.coordinatesByKecamatan.entries) {
      expect(
        LamonganMapData.contains(entry.value),
        isTrue,
        reason: '${entry.key} must be inside Lamongan bounds',
      );
    }
  });

  test('Lamongan map data resolves common kecamatan name variants', () {
    expect(
      LamonganMapData.coordinateForKecamatan('Kecamatan Babat'),
      LamonganMapData.coordinatesByKecamatan['Babat'],
    );
    expect(
      LamonganMapData.resolvePoint(
        kecamatanName: 'Pucuk',
        lat: 0,
        lng: 0,
      ),
      LamonganMapData.coordinatesByKecamatan['Pucuk'],
    );
  });
}
