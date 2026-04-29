// Penjelasan file:
// Feature: analytics
// Layer: logic
// File: analytics_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Doc:
// Tujuan: Mendefinisikan state analytics, model dashboard, status pangan, metadata komoditas, dan detail luas lahan kecamatan untuk UI analitik.
// Dipakai oleh: AnalyticsBloc, AnalyticsPage, analytics sections, dashboard chart, dan laporan analytics.
// Dependensi utama: Response JSON dari AnalyticsRepository dan endpoint `/analytics/dashboard` serta `/analytics/status-pangan`.
// Fungsi public/utama: KomoditasTrend, LuasLahanKecamatan, DashboardStats, ActiveAlert, StatusPanganItem, AnalyticsState variants.
// Side effect penting: Tidak ada I/O langsung; parsing JSON menentukan data yang bisa dirender UI.
class LuasLahanKecamatan {
  final String kecamatanId;
  final String kecamatanNama;
  final double luasHa;

  const LuasLahanKecamatan({
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.luasHa,
  });

  factory LuasLahanKecamatan.fromJson(Map<String, dynamic> json) {
    return LuasLahanKecamatan(
      kecamatanId: json['kecamatan_id']?.toString() ?? '',
      kecamatanNama: json['kecamatan_nama']?.toString() ?? 'Kecamatan',
      luasHa: (json['luas_ha'] as num?)?.toDouble() ?? 0,
    );
  }
}

class KomoditasTrend {
  final String id;
  final String nama;
  final String gambarUrl;
  final double avgHarga;
  final double totalStok;
  final double luasLahan;
  final List<LuasLahanKecamatan> luasLahanByKecamatan;
  final List<double> hargaHarian;
  final List<double> stokHarian;

  const KomoditasTrend({
    required this.id,
    required this.nama,
    required this.gambarUrl,
    required this.avgHarga,
    required this.totalStok,
    required this.luasLahan,
    this.luasLahanByKecamatan = const [],
    required this.hargaHarian,
    required this.stokHarian,
  });

  factory KomoditasTrend.fromJson(Map<String, dynamic> json) {
    return KomoditasTrend(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? 'Komoditas',
      gambarUrl: json['gambar_url']?.toString() ?? '',
      avgHarga: (json['avg_harga'] ?? 0).toDouble(),
      totalStok: (json['total_stok'] ?? 0).toDouble(),
      luasLahan: (json['luas_lahan'] ?? 0).toDouble(),
      luasLahanByKecamatan: DashboardStats._parseLuasLahanKecamatanList(
        json['luas_lahan_by_kecamatan'],
      ),
      hargaHarian: DashboardStats._parseDoubleList(json['harga_harian']),
      stokHarian: DashboardStats._parseStokList(json['stok_harian']),
    );
  }
}

class DashboardStats {
  final String periode;
  final List<String> tanggalLabels;
  final List<ActiveAlert> activeAlerts;
  final int totalKomoditas;
  final int alertCount;
  final int updateHariIni;
  final int kecamatanAman;
  final int kecamatanWaspada;
  final int kecamatanKritis;
  final List<String> listKecamatanAman;
  final List<String> listKecamatanWaspada;
  final List<String> listKecamatanKritis;
  final List<KomoditasTrend> komoditasTrend;
  final int distribusiAktif;
  final int laporanBulanIni;

  const DashboardStats({
    required this.periode,
    required this.tanggalLabels,
    required this.activeAlerts,
    required this.totalKomoditas,
    required this.alertCount,
    required this.updateHariIni,
    required this.kecamatanAman,
    required this.kecamatanWaspada,
    required this.kecamatanKritis,
    this.listKecamatanAman = const [],
    this.listKecamatanWaspada = const [],
    this.listKecamatanKritis = const [],
    required this.komoditasTrend,
    required this.distribusiAktif,
    required this.laporanBulanIni,
  });

  static List<double> _parseDoubleList(dynamic raw) {
    if (raw == null) return List.filled(7, 0.0);
    return List<double>.from((raw as List).map((e) => (e as num).toDouble()));
  }

  static List<double> _parseStokList(dynamic raw) {
    if (raw == null) return List.filled(7, 0.0);
    return List<double>.from((raw as List).map((e) => (e as num).toDouble()));
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return const [];
    return List<String>.from((raw as List).map((e) => e.toString()));
  }

  static List<String> _fallbackLabels(int length) {
    return List<String>.generate(length, (i) => 'H${i + 1}');
  }

  static List<ActiveAlert> _parseActiveAlerts(dynamic raw) {
    if (raw == null) return const [];
    return List<ActiveAlert>.from(
      (raw as List).map((e) => ActiveAlert.fromJson(e as Map<String, dynamic>)),
    );
  }

  static List<KomoditasTrend> _parseKomoditasTrendList(dynamic raw) {
    if (raw == null) return const [];
    return List<KomoditasTrend>.from(
      (raw as List)
          .map((e) => KomoditasTrend.fromJson(e as Map<String, dynamic>)),
    );
  }

  static List<LuasLahanKecamatan> _parseLuasLahanKecamatanList(dynamic raw) {
    if (raw == null) return const [];
    return List<LuasLahanKecamatan>.from(
      (raw as List)
          .map((e) => LuasLahanKecamatan.fromJson(e as Map<String, dynamic>)),
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final labels = _parseStringList(json['tanggal_labels']);
    final komTrend = _parseKomoditasTrendList(json['komoditas_trend']);

    return DashboardStats(
      periode: json['periode']?.toString() ?? '7d',
      tanggalLabels: labels.isEmpty ? _fallbackLabels(7) : labels,
      activeAlerts: _parseActiveAlerts(json['active_alerts']),
      totalKomoditas: (json['total_komoditas'] as num?)?.toInt() ?? 0,
      alertCount: (json['alert_count'] as num?)?.toInt() ?? 0,
      updateHariIni: (json['update_hari_ini'] as num?)?.toInt() ?? 0,
      kecamatanAman: (json['kecamatan_aman'] as num?)?.toInt() ?? 0,
      kecamatanWaspada: (json['kecamatan_waspada'] as num?)?.toInt() ?? 0,
      kecamatanKritis: (json['kecamatan_kritis'] as num?)?.toInt() ?? 0,
      listKecamatanAman: _parseStringList(json['list_kecamatan_aman']),
      listKecamatanWaspada: _parseStringList(json['list_kecamatan_waspada']),
      listKecamatanKritis: _parseStringList(json['list_kecamatan_kritis']),
      komoditasTrend: komTrend,
      distribusiAktif: (json['distribusi_aktif'] as num?)?.toInt() ?? 0,
      laporanBulanIni: (json['laporan_bulan_ini'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActiveAlert {
  final String id;
  final String jenisMasalah;
  final String kecamatanNama;
  final String status;
  final int prioritas;
  final DateTime? createdAt;

  const ActiveAlert({
    required this.id,
    required this.jenisMasalah,
    required this.kecamatanNama,
    required this.status,
    required this.prioritas,
    required this.createdAt,
  });

  factory ActiveAlert.fromJson(Map<String, dynamic> json) {
    return ActiveAlert(
      id: json['id']?.toString() ?? '',
      jenisMasalah: json['jenis_masalah']?.toString() ?? 'Laporan Darurat',
      kecamatanNama: json['kecamatan_nama']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'baru',
      prioritas: (json['prioritas'] as num?)?.toInt() ?? 3,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class AnalyticsState {}

// State ini menunjukkan kondisi 'AnalyticsInitial' pada fitur ini.
class AnalyticsInitial extends AnalyticsState {}

// State ini menunjukkan kondisi 'AnalyticsLoading' pada fitur ini.
class AnalyticsLoading extends AnalyticsState {}

// State ini menunjukkan kondisi 'AnalyticsLoaded' pada fitur ini.
class AnalyticsLoaded extends AnalyticsState {
  final DashboardStats stats;
  AnalyticsLoaded(this.stats);
}

// State ini menunjukkan kondisi 'AnalyticsError' pada fitur ini.
class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
}

// State ini menunjukkan kondisi 'StatusPanganLoading' pada fitur ini.
class StatusPanganLoading extends AnalyticsState {}

// State ini menunjukkan kondisi 'StatusPanganLoaded' pada fitur ini.
class StatusPanganLoaded extends AnalyticsState {
  final List<StatusPanganItem> items;
  StatusPanganLoaded(this.items);
}

// State ini menunjukkan kondisi 'StatusPanganError' pada fitur ini.
class StatusPanganError extends AnalyticsState {
  final String message;
  StatusPanganError(this.message);
}

class StatusPanganItem {
  final String kecamatanId;
  final String kecamatanNama;
  final double lat;
  final double lng;
  final String statusStok;
  final double stokPersen;
  final String hargaTrend;
  final int jumlahLaporanAktif;

  const StatusPanganItem({
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.lat,
    required this.lng,
    required this.statusStok,
    required this.stokPersen,
    required this.hargaTrend,
    required this.jumlahLaporanAktif,
  });

  factory StatusPanganItem.fromJson(Map<String, dynamic> json) {
    return StatusPanganItem(
      kecamatanId: json['kecamatan_id']?.toString() ?? '',
      kecamatanNama: json['kecamatan_nama']?.toString() ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      statusStok: json['status_stok']?.toString() ?? 'tidak_ada_data',
      stokPersen: (json['stok_persen'] ?? 0).toDouble(),
      hargaTrend: json['harga_trend']?.toString() ?? 'STABIL',
      jumlahLaporanAktif: (json['jumlah_laporan_aktif'] ?? 0) as int,
    );
  }
}
