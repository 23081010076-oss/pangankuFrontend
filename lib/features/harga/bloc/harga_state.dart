// Penjelasan file:
// Feature: harga
// Layer: logic
// File: harga_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
import 'package:equatable/equatable.dart';

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class HargaState extends Equatable {
  @override
  List<Object?> get props => [];
}

// State ini menunjukkan kondisi 'HargaInitial' pada fitur ini.
class HargaInitial extends HargaState {}

// State ini menunjukkan kondisi 'HargaLoading' pada fitur ini.
class HargaLoading extends HargaState {}

// State ini menunjukkan kondisi 'HargaCreating' pada fitur ini.
class HargaCreating extends HargaState {}

// State ini menunjukkan kondisi 'HargaCreated' pada fitur ini.
class HargaCreated extends HargaState {}

// State ini menunjukkan kondisi 'HargaUpdated' pada fitur ini.
class HargaUpdated extends HargaState {}

// State ini menunjukkan kondisi 'HargaDeleted' pada fitur ini.
class HargaDeleted extends HargaState {}

// State ini menunjukkan kondisi 'HargaLoaded' pada fitur ini.
class HargaLoaded extends HargaState {
  final List<HargaItem> hargaList;
  final List<TrendData>? trendData;
  final String? selectedKomoditas;
  final List<String> kategoris;

  HargaLoaded({
    required this.hargaList,
    this.trendData,
    this.selectedKomoditas,
    this.kategoris = const [],
  });

  @override
  List<Object?> get props =>
      [hargaList, trendData, selectedKomoditas, kategoris];
}

// State ini menunjukkan kondisi 'HargaError' pada fitur ini.
class HargaError extends HargaState {
  final String message;
  HargaError(this.message);
  @override
  List<Object> get props => [message];
}

class HargaItem {
  final String id;
  final String komoditasId;
  final String komoditasNama;
  final String kategori;
  final double harga;
  final String kecamatanId;
  final String kecamatanNama;
  final String tanggal;
  final double perubahanPersen;
  final String trend;
  final String? gambarUrl;

  const HargaItem({
    required this.id,
    required this.komoditasId,
    required this.komoditasNama,
    required this.kategori,
    required this.harga,
    required this.kecamatanId,
    required this.kecamatanNama,
    required this.tanggal,
    required this.perubahanPersen,
    required this.trend,
    this.gambarUrl,
  });

  factory HargaItem.fromJson(
    Map<String, dynamic> json, {
    String kategori = '',
  }) {
    String normalizeUuid(dynamic raw) {
      final v = raw?.toString() ?? '';
      if (v == '00000000-0000-0000-0000-000000000000') return '';
      return v;
    }

    return HargaItem(
      id: normalizeUuid(json['id']),
      komoditasId: normalizeUuid(json['komoditas_id']),
      komoditasNama: json['komoditas_nama']?.toString() ??
          (json['komoditas'] as Map?)?['nama']?.toString() ??
          (json['Komoditas'] as Map?)?['nama']?.toString() ??
          '',
      kategori: json['kategori']?.toString().isNotEmpty == true
          ? json['kategori'].toString()
          : kategori,
      harga: (json['harga_per_kg'] ?? json['harga'] ?? 0).toDouble(),
      kecamatanId: normalizeUuid(json['kecamatan_id']),
      kecamatanNama: json['kecamatan_nama']?.toString() ??
          (json['kecamatan'] as Map?)?['nama']?.toString() ??
          (json['Kecamatan'] as Map?)?['nama']?.toString() ??
          '',
      tanggal: json['tanggal']?.toString() ?? '',
      perubahanPersen: (json['perubahan_persen'] ?? 0).toDouble(),
      trend: json['trend']?.toString() ?? 'STABIL',
      gambarUrl: json['gambar_url']?.toString() ??
          (json['komoditas'] as Map?)?['gambar_url']?.toString() ??
          (json['Komoditas'] as Map?)?['gambar_url']?.toString(),
    );
  }
}

class TrendData {
  final String tanggal;
  final double avg;
  final double min;
  final double max;

  const TrendData({
    required this.tanggal,
    required this.avg,
    required this.min,
    required this.max,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      tanggal: json['tgl']?.toString() ?? json['tanggal']?.toString() ?? '',
      avg: (json['avg'] ?? 0).toDouble(),
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
    );
  }
}
