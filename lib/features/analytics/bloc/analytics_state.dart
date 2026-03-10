class DashboardStats {
  final int totalKomoditas;
  final int alertCount;
  final int updateHariIni;
  final int kecamatanAman;
  final int kecamatanWaspada;
  final int kecamatanKritis;
  final double avgHargaBeras;
  final double avgHargaJagung;
  final double avgHargaKedelai;
  final double avgHargaCabai;
  final double avgHargaGula;
  final double avgHargaMinyak;
  final List<double> harga7HariBeras;
  final List<double> harga7HariJagung;
  final List<double> harga7HariKedelai;
  final List<double> harga7HariCabai;
  final List<double> harga7HariGula;
  final List<double> harga7HariMinyak;
  final int distribusiAktif;
  final int laporanBulanIni;

  const DashboardStats({
    required this.totalKomoditas,
    required this.alertCount,
    required this.updateHariIni,
    required this.kecamatanAman,
    required this.kecamatanWaspada,
    required this.kecamatanKritis,
    required this.avgHargaBeras,
    required this.avgHargaJagung,
    required this.avgHargaKedelai,
    required this.avgHargaCabai,
    required this.avgHargaGula,
    required this.avgHargaMinyak,
    required this.harga7HariBeras,
    required this.harga7HariJagung,
    required this.harga7HariKedelai,
    required this.harga7HariCabai,
    required this.harga7HariGula,
    required this.harga7HariMinyak,
    required this.distribusiAktif,
    required this.laporanBulanIni,
  });

  static List<double> _parseDoubleList(dynamic raw) {
    if (raw == null) return List.filled(7, 0.0);
    return List<double>.from((raw as List).map((e) => (e as num).toDouble()));
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalKomoditas: (json['total_komoditas'] ?? 0) as int,
      alertCount: (json['alert_count'] ?? 0) as int,
      updateHariIni: (json['update_hari_ini'] ?? 0) as int,
      kecamatanAman: (json['kecamatan_aman'] ?? 0) as int,
      kecamatanWaspada: (json['kecamatan_waspada'] ?? 0) as int,
      kecamatanKritis: (json['kecamatan_kritis'] ?? 0) as int,
      avgHargaBeras: (json['avg_harga_beras'] ?? 0).toDouble(),
      avgHargaJagung: (json['avg_harga_jagung'] ?? 0).toDouble(),
      avgHargaKedelai: (json['avg_harga_kedelai'] ?? 0).toDouble(),
      avgHargaCabai: (json['avg_harga_cabai'] ?? 0).toDouble(),
      avgHargaGula: (json['avg_harga_gula'] ?? 0).toDouble(),
      avgHargaMinyak: (json['avg_harga_minyak'] ?? 0).toDouble(),
      harga7HariBeras: _parseDoubleList(json['harga_7hari_beras']),
      harga7HariJagung: _parseDoubleList(json['harga_7hari_jagung']),
      harga7HariKedelai: _parseDoubleList(json['harga_7hari_kedelai']),
      harga7HariCabai: _parseDoubleList(json['harga_7hari_cabai']),
      harga7HariGula: _parseDoubleList(json['harga_7hari_gula']),
      harga7HariMinyak: _parseDoubleList(json['harga_7hari_minyak']),
      distribusiAktif: (json['distribusi_aktif'] ?? 0) as int,
      laporanBulanIni: (json['laporan_bulan_ini'] ?? 0) as int,
    );
  }
}

abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final DashboardStats stats;
  AnalyticsLoaded(this.stats);
}

class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
}

class StatusPanganLoading extends AnalyticsState {}

class StatusPanganLoaded extends AnalyticsState {
  final List<StatusPanganItem> items;
  StatusPanganLoaded(this.items);
}

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
