abstract class DistribusiEvent {}

class LoadDistribusiList extends DistribusiEvent {
  final String? status;
  LoadDistribusiList({this.status});
}

class RefreshDistribusi extends DistribusiEvent {}

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

class UpdateDistribusiStatus extends DistribusiEvent {
  final String id;
  final String status; // terjadwal | proses | selesai | dibatalkan
  UpdateDistribusiStatus({required this.id, required this.status});
}

class DeleteDistribusi extends DistribusiEvent {
  final String id;
  DeleteDistribusi(this.id);
}
