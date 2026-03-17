import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'laporan_event.dart';
import 'laporan_state.dart';

class LaporanBloc extends Bloc<LaporanEvent, LaporanState> {
  final DioClient _client;

  LaporanBloc(this._client) : super(LaporanInitial()) {
    on<LoadLaporanList>(_onLoadLaporanList);
    on<CreateLaporan>(_onCreateLaporan);
    on<RefreshLaporan>((_, __) => add(LoadLaporanList()));
    on<UpdateLaporanStatus>(_onUpdateLaporanStatus);
    on<DeleteLaporan>(_onDeleteLaporan);
  }

  Future<void> _onLoadLaporanList(
    LoadLaporanList event,
    Emitter<LaporanState> emit,
  ) async {
    emit(LaporanLoading());
    try {
      final response = await _client.dio.get('/laporan');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list = data['data'] ?? data ?? [];
        final laporanList =
            list.map((json) => LaporanItem.fromJson(json)).toList();

        emit(LaporanLoaded(laporanList: laporanList));
      } else {
        emit(LaporanError('Gagal memuat data laporan'));
      }
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Gagal terhubung ke server';
      emit(LaporanError(message));
    } catch (e) {
      emit(LaporanError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onCreateLaporan(
    CreateLaporan event,
    Emitter<LaporanState> emit,
  ) async {
    emit(LaporanCreating());
    try {
      final response = await _client.dio.post('/laporan', data: {
        'jenis_masalah': event.jenisMasalah,
        'deskripsi': event.deskripsi,
        'kecamatan_id': event.kecamatanId,
        'prioritas': event.prioritas,
        if (event.fotoUrl != null) 'foto_url': event.fotoUrl,
      },);

      if (response.statusCode == 201 || response.statusCode == 200) {
        emit(LaporanCreated());
        // Reload the list
        add(LoadLaporanList());
      } else {
        emit(LaporanError('Gagal membuat laporan'));
      }
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Gagal membuat laporan';
      emit(LaporanError(message));
    } catch (e) {
      emit(LaporanError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onUpdateLaporanStatus(
      UpdateLaporanStatus event, Emitter<LaporanState> emit,) async {
    final prev = state is LaporanLoaded ? state as LaporanLoaded : null;
    emit(LaporanSubmitting());
    try {
      await _client.dio
          .put('/laporan/${event.id}/status', data: {'status': event.status});
      emit(LaporanStatusUpdated());
      add(LoadLaporanList());
    } on DioException catch (e) {
      if (prev != null) emit(prev);
      emit(LaporanError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal memperbarui status'
          : 'Gagal memperbarui status',),);
    }
  }

  Future<void> _onDeleteLaporan(
      DeleteLaporan event, Emitter<LaporanState> emit,) async {
    emit(LaporanSubmitting());
    try {
      await _client.dio.delete('/laporan/${event.id}');
      emit(LaporanDeleted());
      add(LoadLaporanList());
    } on DioException catch (e) {
      emit(LaporanError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal menghapus laporan'
          : 'Gagal menghapus laporan',),);
    }
  }
}
