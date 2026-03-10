 import 'package:equatable/equatable.dart';

abstract class LaporanState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LaporanInitial extends LaporanState {}

class LaporanLoading extends LaporanState {}

class LaporanLoaded extends LaporanState {
  final List<LaporanItem> laporanList;

  LaporanLoaded({required this.laporanList});

  @override
  List<Object> get props => [laporanList];
}

class LaporanCreating extends LaporanState {}

class LaporanCreated extends LaporanState {}

class LaporanError extends LaporanState {
  final String message;

  LaporanError(this.message);

  @override
  List<Object> get props => [message];
}

class LaporanItem {
  final String id;
  final String jenisMasalah;
  final String deskripsi;
  final String kecamatanNama;
  final String status; // "baru", "proses", "selesai"
  final int prioritas;
  final String tanggal;
  final String? fotoUrl;

  LaporanItem({
    required this.id,
    required this.jenisMasalah,
    required this.deskripsi,
    required this.kecamatanNama,
    required this.status,
    required this.prioritas,
    required this.tanggal,
    this.fotoUrl,
  });

  factory LaporanItem.fromJson(Map<String, dynamic> json) {
    return LaporanItem(
      id: json['id'] ?? '',
      jenisMasalah: json['jenis_masalah'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      kecamatanNama: json['kecamatan_nama'] ?? json['Kecamatan']?['nama'] ?? '',
      status: json['status'] ?? 'baru',
      prioritas: json['prioritas'] ?? 3,
      tanggal: json['created_at'] ?? '',
      fotoUrl: json['foto_url'],
    );
  }
}

class LaporanSubmitting extends LaporanState {}

class LaporanStatusUpdated extends LaporanState {}

class LaporanDeleted extends LaporanState {}
