abstract class LaporanEvent {}

class LoadLaporanList extends LaporanEvent {}

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

class UpdateLaporanStatus extends LaporanEvent {
  final String id;
  final String status; // baru | proses | selesai
  UpdateLaporanStatus({required this.id, required this.status});
}

class DeleteLaporan extends LaporanEvent {
  final String id;
  DeleteLaporan(this.id);
}

class RefreshLaporan extends LaporanEvent {}
