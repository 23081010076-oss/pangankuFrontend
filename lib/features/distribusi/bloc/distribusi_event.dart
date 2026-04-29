// Penjelasan file:
// Feature: distribusi
// Layer: logic
// File: distribusi_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class DistribusiEvent {}

// Event ini mewakili aksi 'LoadDistribusiList' yang akan diproses oleh bloc.
class LoadDistribusiList extends DistribusiEvent {
  final String? status;
  LoadDistribusiList({this.status});
}

// Event ini mewakili aksi 'RefreshDistribusi' yang akan diproses oleh bloc.
class RefreshDistribusi extends DistribusiEvent {}

// Event ini mewakili aksi 'CreateDistribusi' yang akan diproses oleh bloc.
class CreateDistribusi extends DistribusiEvent {
  final String dariKecamatanId;
  final String keKecamatanId;
  final String komoditasId;
  final double jumlahKg;
  final String jadwalBerangkat; // ISO datetime
  final String? namaDriver;
  final String? namaKendaraan;

  CreateDistribusi({
    required this.dariKecamatanId,
    required this.keKecamatanId,
    required this.komoditasId,
    required this.jumlahKg,
    required this.jadwalBerangkat,
    this.namaDriver,
    this.namaKendaraan,
  });
}

// Event ini mewakili aksi 'UpdateDistribusiStatus' yang akan diproses oleh bloc.
class UpdateDistribusiStatus extends DistribusiEvent {
  final String id;
  final String status; // terjadwal | proses | selesai | dibatalkan
  UpdateDistribusiStatus({required this.id, required this.status});
}

// Event ini mewakili aksi 'DeleteDistribusi' yang akan diproses oleh bloc.
class DeleteDistribusi extends DistribusiEvent {
  final String id;
  DeleteDistribusi(this.id);
}
