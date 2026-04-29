// Penjelasan file:
// Feature: laporan
// Layer: logic
// File: laporan_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class LaporanEvent {}

// Event ini mewakili aksi 'LoadLaporanList' yang akan diproses oleh bloc.
class LoadLaporanList extends LaporanEvent {}

// Event ini mewakili aksi 'CreateLaporan' yang akan diproses oleh bloc.
class CreateLaporan extends LaporanEvent {
  final String jenisMasalah;
  final String deskripsi;
  final String kecamatanId;
  final int prioritas;
  final String? fotoUrl;

  CreateLaporan({
    required this.jenisMasalah,
    required this.deskripsi,
    required this.kecamatanId,
    required this.prioritas,
    this.fotoUrl,
  });
}

// Event ini mewakili aksi 'UpdateLaporanStatus' yang akan diproses oleh bloc.
class UpdateLaporanStatus extends LaporanEvent {
  final String id;
  final String status; // baru | proses | selesai
  UpdateLaporanStatus({required this.id, required this.status});
}

// Event ini mewakili aksi 'DeleteLaporan' yang akan diproses oleh bloc.
class DeleteLaporan extends LaporanEvent {
  final String id;
  DeleteLaporan(this.id);
}

// Event ini mewakili aksi 'RefreshLaporan' yang akan diproses oleh bloc.
class RefreshLaporan extends LaporanEvent {}
