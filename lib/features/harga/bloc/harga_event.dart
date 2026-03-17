abstract class HargaEvent {}

class LoadHargaList extends HargaEvent {
  final String? komoditasId;
  final String? kecamatanId;
  LoadHargaList({this.komoditasId, this.kecamatanId});
}

class LoadHargaTrend extends HargaEvent {
  final String komoditasId;
  final String periode;
  LoadHargaTrend({required this.komoditasId, this.periode = '30d'});
}

class CreateHarga extends HargaEvent {
  final String komoditasId;
  final String kecamatanId;
  final double hargaPerKg;
  final String tanggal; // "yyyy-MM-dd"
  CreateHarga({required this.komoditasId, required this.kecamatanId,
      required this.hargaPerKg, required this.tanggal,});
}

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

class DeleteHarga extends HargaEvent {
  final String id;
  DeleteHarga(this.id);
}

class RefreshHarga extends HargaEvent {}
