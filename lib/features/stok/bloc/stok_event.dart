abstract class StokEvent {}

class LoadStokList extends StokEvent {
  final String? komoditasId;
  final String? kecamatanId;
  final String? statusFilter;

  LoadStokList({this.komoditasId, this.kecamatanId, this.statusFilter});
}

class RefreshStok extends StokEvent {}

class CreateOrUpdateStok extends StokEvent {
  final String komoditasId;
  final String kecamatanId;
  final double stokKg;
  final double kapasitasKg;
  CreateOrUpdateStok({required this.komoditasId, required this.kecamatanId,
      required this.stokKg, required this.kapasitasKg,});
}
