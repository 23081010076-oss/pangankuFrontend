class DistribusiItem {
  final String id;
  final String dari;
  final String ke;
  final String komoditas;
  final double jumlahKg;
  final String status;
  final String namaDriver;
  final String namaKendaraan;
  final String jadwalBerangkat;
  final String? eta;
  final String createdAt;

  const DistribusiItem({
    required this.id,
    required this.dari,
    required this.ke,
    required this.komoditas,
    required this.jumlahKg,
    required this.status,
    required this.namaDriver,
    required this.namaKendaraan,
    required this.jadwalBerangkat,
    this.eta,
    required this.createdAt,
  });

  factory DistribusiItem.fromJson(Map<String, dynamic> json) {
    final dariKec = json['dari_kecamatan'] as Map<String, dynamic>? ?? {};
    final keKec = json['ke_kecamatan'] as Map<String, dynamic>? ?? {};
    final kom = json['komoditas'] as Map<String, dynamic>? ?? {};

    return DistribusiItem(
      id: json['id']?.toString() ?? '',
      dari: dariKec['nama']?.toString() ?? '-',
      ke: keKec['nama']?.toString() ?? '-',
      komoditas: kom['nama']?.toString() ?? '-',
      jumlahKg: (json['jumlah_kg'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'terjadwal',
      namaDriver: json['nama_driver']?.toString() ?? '-',
      namaKendaraan: json['nama_kendaraan']?.toString() ?? '-',
      jadwalBerangkat: json['jadwal_berangkat']?.toString() ?? '',
      eta: json['eta']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

abstract class DistribusiState {}

class DistribusiInitial extends DistribusiState {}

class DistribusiLoading extends DistribusiState {}

class DistribusiLoaded extends DistribusiState {
  final List<DistribusiItem> items;
  DistribusiLoaded(this.items);
}

class DistribusiError extends DistribusiState {
  final String message;
  DistribusiError(this.message);
}

class DistribusiSaving extends DistribusiState {}

class DistribusiSaved extends DistribusiState {}

class DistribusiStatusUpdated extends DistribusiState {}
