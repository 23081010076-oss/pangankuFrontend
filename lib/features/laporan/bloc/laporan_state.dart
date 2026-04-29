// Penjelasan file:
// Feature: laporan
// Layer: logic
// File: laporan_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
import 'package:equatable/equatable.dart';

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class LaporanState extends Equatable {
  @override
  List<Object?> get props => [];
}

// State ini menunjukkan kondisi 'LaporanInitial' pada fitur ini.
class LaporanInitial extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanLoading' pada fitur ini.
class LaporanLoading extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanLoaded' pada fitur ini.
class LaporanLoaded extends LaporanState {
  final List<LaporanItem> laporanList;

  LaporanLoaded({required this.laporanList});

  @override
  List<Object> get props => [laporanList];
}

// State ini menunjukkan kondisi 'LaporanCreating' pada fitur ini.
class LaporanCreating extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanCreated' pada fitur ini.
class LaporanCreated extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanError' pada fitur ini.
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

// State ini menunjukkan kondisi 'LaporanSubmitting' pada fitur ini.
class LaporanSubmitting extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanStatusUpdated' pada fitur ini.
class LaporanStatusUpdated extends LaporanState {}

// State ini menunjukkan kondisi 'LaporanDeleted' pada fitur ini.
class LaporanDeleted extends LaporanState {}
