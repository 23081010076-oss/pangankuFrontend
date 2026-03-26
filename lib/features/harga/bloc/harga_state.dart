import 'package:equatable/equatable.dart';

abstract class HargaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HargaInitial extends HargaState {}

class HargaLoading extends HargaState {}

class HargaCreating extends HargaState {}

class HargaCreated extends HargaState {}

class HargaUpdated extends HargaState {}

class HargaDeleted extends HargaState {}

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
  List<Object?> get props => [hargaList, trendData, selectedKomoditas, kategoris];
}

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
  });

  factory HargaItem.fromJson(Map<String, dynamic> json, {String kategori = ''}) {
    String normalizeUuid(dynamic raw) {
      final v = raw?.toString() ?? '';
      if (v == '00000000-0000-0000-0000-000000000000') return '';
      return v;
    }

    return HargaItem(
      id: normalizeUuid(json['id']),
      komoditasId: normalizeUuid(json['komoditas_id']),
      komoditasNama: json['komoditas_nama']?.toString() ??
          (json['Komoditas'] as Map?)?['nama']?.toString() ?? '',
      kategori: json['kategori']?.toString().isNotEmpty == true
          ? json['kategori'].toString()
          : kategori,
      harga: (json['harga_per_kg'] ?? json['harga'] ?? 0).toDouble(),
      kecamatanId: normalizeUuid(json['kecamatan_id']),
      kecamatanNama: json['kecamatan_nama']?.toString() ??
          (json['Kecamatan'] as Map?)?['nama']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      perubahanPersen: (json['perubahan_persen'] ?? 0).toDouble(),
      trend: json['trend']?.toString() ?? 'STABIL',
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
