class StokItem {
  final String id;
  final String kecamatanId;
  final String kecamatanNama;
  final String komoditasId;
  final String komoditasNama;
  final String komoditasSatuan;
  final double stokKg;
  final double kapasitasKg;
  final double stokPersen;
  final String statusStok;
  final String updatedAt;

  const StokItem({
    required this.id,
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.komoditasId,
    required this.komoditasNama,
    required this.komoditasSatuan,
    required this.stokKg,
    required this.kapasitasKg,
    required this.stokPersen,
    required this.statusStok,
    required this.updatedAt,
  });

  factory StokItem.fromJson(Map<String, dynamic> json) {
    final stokKg = (json['stok_kg'] as num?)?.toDouble() ?? 0;
    final kapasitasKg = (json['kapasitas_kg'] as num?)?.toDouble() ?? 1;
    final persen = (kapasitasKg > 0 ? stokKg / kapasitasKg * 100 : 0)
        .clamp(0, 100)
        .toDouble();
    final String status;
    if (persen >= 70) {
      status = 'aman';
    } else if (persen >= 30) {
      status = 'waspada';
    } else {
      status = 'kritis';
    }

    final kec = json['kecamatan'] as Map<String, dynamic>? ?? {};
    final kom = json['komoditas'] as Map<String, dynamic>? ?? {};

    return StokItem(
      id: json['id']?.toString() ?? '',
      kecamatanId: json['kecamatan_id']?.toString() ?? '',
      kecamatanNama: kec['nama']?.toString() ?? '-',
      komoditasId: json['komoditas_id']?.toString() ?? '',
      komoditasNama: kom['nama']?.toString() ?? '-',
      komoditasSatuan: kom['satuan']?.toString() ?? 'kg',
      stokKg: stokKg,
      kapasitasKg: kapasitasKg,
      stokPersen: persen,
      statusStok: status,
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

abstract class StokState {}

class StokInitial extends StokState {}

class StokLoading extends StokState {}

class StokLoaded extends StokState {
  final List<StokItem> items;
  StokLoaded(this.items);
}

class StokError extends StokState {
  final String message;
  StokError(this.message);
}

class StokSaving extends StokState {}

class StokSaved extends StokState {}
