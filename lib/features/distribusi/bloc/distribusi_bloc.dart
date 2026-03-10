import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'distribusi_event.dart';
import 'distribusi_state.dart';

class DistribusiBloc extends Bloc<DistribusiEvent, DistribusiState> {
  final DioClient _client;

  DistribusiBloc(this._client) : super(DistribusiInitial()) {
    on<LoadDistribusiList>(_onLoad);
    on<CreateDistribusi>(_onCreateDistribusi);
    on<UpdateDistribusiStatus>(_onUpdateDistribusiStatus);
    on<DeleteDistribusi>(_onDeleteDistribusi);
    on<RefreshDistribusi>(_onRefresh);
  }

  Future<void> _onLoad(
      LoadDistribusiList event, Emitter<DistribusiState> emit,) async {
    emit(DistribusiLoading());
    try {
      final params = <String, dynamic>{'limit': 50};
      if (event.status != null && event.status != 'semua') {
        params['status'] = event.status;
      }

      final response =
          await _client.dio.get('/distribusi', queryParameters: params);
      final data = response.data;
      final List<dynamic> list = data['data'] ?? (data is List ? data : []);
      final items = list
          .map((j) => DistribusiItem.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(DistribusiLoaded(items));
    } on DioException catch (e) {
      emit(DistribusiError(e.response?.data?['error'] as String? ??
          'Gagal memuat data distribusi',),);
    } catch (e) {
      emit(DistribusiError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onRefresh(
      RefreshDistribusi event, Emitter<DistribusiState> emit,) async {
    add(LoadDistribusiList());
  }

  Future<void> _onCreateDistribusi(
      CreateDistribusi event, Emitter<DistribusiState> emit,) async {
    emit(DistribusiSaving());
    try {
      final Map<String, dynamic> body = {
        'dari_kecamatan_id': event.dariKecamatanId,
        'ke_kecamatan_id': event.keKecamatanId,
        'komoditas_id': event.komoditasId,
        'jumlah_kg': event.jumlahKg,
        'jadwal_berangkat': event.jadwalBerangkat,
      };
      if (event.namaDriver != null) body['nama_driver'] = event.namaDriver;
      if (event.namaKendaraan != null) body['nama_kendaraan'] = event.namaKendaraan;

      final response = await _client.dio.post('/distribusi', data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(DistribusiSaved());
        add(LoadDistribusiList());
      } else {
        emit(DistribusiError('Gagal membuat jadwal distribusi'));
      }
    } on DioException catch (e) {
      emit(DistribusiError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal membuat jadwal'
          : 'Gagal membuat jadwal',),);
    }
  }

  Future<void> _onUpdateDistribusiStatus(
      UpdateDistribusiStatus event, Emitter<DistribusiState> emit,) async {
    try {
      await _client.dio.put(
          '/distribusi/${event.id}/status', data: {'status': event.status},);
      emit(DistribusiStatusUpdated());
      add(LoadDistribusiList());
    } on DioException catch (e) {
      emit(DistribusiError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal memperbarui status'
          : 'Gagal memperbarui status',),);
    }
  }

  Future<void> _onDeleteDistribusi(
      DeleteDistribusi event, Emitter<DistribusiState> emit,) async {
    emit(DistribusiSaving());
    try {
      await _client.dio.delete('/distribusi/${event.id}');
      emit(DistribusiSaved());
      add(LoadDistribusiList());
    } on DioException catch (e) {
      emit(DistribusiError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal menghapus distribusi'
          : 'Gagal menghapus distribusi',),);
    }
  }
}
