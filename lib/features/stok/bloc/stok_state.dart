// Penjelasan file:
// Feature: stok
// Layer: logic
// File: stok_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
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
  final String? gambarUrl;
  final String? kategori;

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
    this.gambarUrl,
    this.kategori,
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
      gambarUrl: kom['gambar_url']?.toString(),
      kategori: kom['kategori']?.toString(),
    );
  }
}

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class StokState {}

// State ini menunjukkan kondisi 'StokInitial' pada fitur ini.
class StokInitial extends StokState {}

// State ini menunjukkan kondisi 'StokLoading' pada fitur ini.
class StokLoading extends StokState {}

// State ini menunjukkan kondisi 'StokLoaded' pada fitur ini.
class StokLoaded extends StokState {
  final List<StokItem> items;
  StokLoaded(this.items);
}

// State ini menunjukkan kondisi 'StokError' pada fitur ini.
class StokError extends StokState {
  final String message;
  StokError(this.message);
}

// State ini menunjukkan kondisi 'StokSaving' pada fitur ini.
class StokSaving extends StokState {}

// State ini menunjukkan kondisi 'StokSaved' pada fitur ini.
class StokSaved extends StokState {}
