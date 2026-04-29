// Penjelasan file:
// Feature: harga
// Layer: logic
// File: harga_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class HargaEvent {}

// Event ini mewakili aksi 'LoadHargaList' yang akan diproses oleh bloc.
class LoadHargaList extends HargaEvent {
  final String? komoditasId;
  final String? kecamatanId;
  LoadHargaList({this.komoditasId, this.kecamatanId});
}

// Event ini mewakili aksi 'LoadHargaTrend' yang akan diproses oleh bloc.
class LoadHargaTrend extends HargaEvent {
  final String komoditasId;
  final String periode;
  LoadHargaTrend({required this.komoditasId, this.periode = '30d'});
}

// Event ini mewakili aksi 'CreateHarga' yang akan diproses oleh bloc.
class CreateHarga extends HargaEvent {
  final String komoditasId;
  final String kecamatanId;
  final double hargaPerKg;
  final String tanggal; // "yyyy-MM-dd"
  CreateHarga({
    required this.komoditasId,
    required this.kecamatanId,
    required this.hargaPerKg,
    required this.tanggal,
  });
}

// Event ini mewakili aksi 'UpdateHarga' yang akan diproses oleh bloc.
class UpdateHarga extends HargaEvent {
  final String id;
  final double hargaPerKg;
  final String tanggal;

  UpdateHarga({
    required this.id,
    required this.hargaPerKg,
    required this.tanggal,
  });
}

// Event ini mewakili aksi 'DeleteHarga' yang akan diproses oleh bloc.
class DeleteHarga extends HargaEvent {
  final String id;
  DeleteHarga(this.id);
}

// Event ini mewakili aksi 'RefreshHarga' yang akan diproses oleh bloc.
class RefreshHarga extends HargaEvent {}
