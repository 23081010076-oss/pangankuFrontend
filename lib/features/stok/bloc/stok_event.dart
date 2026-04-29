// Penjelasan file:
// Feature: stok
// Layer: logic
// File: stok_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class StokEvent {}

// Event ini mewakili aksi 'LoadStokList' yang akan diproses oleh bloc.
class LoadStokList extends StokEvent {
  final String? komoditasId;
  final String? kecamatanId;
  final String? statusFilter;

  LoadStokList({this.komoditasId, this.kecamatanId, this.statusFilter});
}

// Event ini mewakili aksi 'RefreshStok' yang akan diproses oleh bloc.
class RefreshStok extends StokEvent {}

// Event ini mewakili aksi 'CreateOrUpdateStok' yang akan diproses oleh bloc.
class CreateOrUpdateStok extends StokEvent {
  final String komoditasId;
  final String kecamatanId;
  final double stokKg;
  final double kapasitasKg;
  CreateOrUpdateStok({
    required this.komoditasId,
    required this.kecamatanId,
    required this.stokKg,
    required this.kapasitasKg,
  });
}

// Event ini mewakili aksi 'DeleteStok' yang akan diproses oleh bloc.
class DeleteStok extends StokEvent {
  final String id;
  DeleteStok(this.id);
}
