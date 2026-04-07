import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/laporan_repository.dart';
import 'laporan_event.dart';
import 'laporan_state.dart';

class LaporanBloc extends Bloc<LaporanEvent, LaporanState> {
  final LaporanRepository _repository;

  LaporanBloc(this._repository) : super(LaporanInitial()) {
    on<LoadLaporanList>(_onLoadLaporanList);
    on<CreateLaporan>(_onCreateLaporan);
    on<RefreshLaporan>(_onRefreshLaporan);
    on<UpdateLaporanStatus>(_onUpdateLaporanStatus);
    on<DeleteLaporan>(_onDeleteLaporan);
  }

  Future<void> _onRefreshLaporan(
    RefreshLaporan event,
    Emitter<LaporanState> emit,
  ) async {
    try {
      final list = await _repository.fetchLaporanList();
      final laporanList = list.map((json) => LaporanItem.fromJson(json)).toList();
      emit(LaporanLoaded(laporanList: laporanList));
    } on DioException catch (e) {
      final message = _repository.getErrorMessage(
        e,
        fallback: 'Gagal memuat ulang data laporan',
      );
      emit(LaporanError(message));
    } catch (e) {
      emit(LaporanError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onLoadLaporanList(
    LoadLaporanList event,
    Emitter<LaporanState> emit,
  ) async {
    emit(LaporanLoading());
    try {
      final list = await _repository.fetchLaporanList();
      final laporanList = list.map((json) => LaporanItem.fromJson(json)).toList();

      emit(LaporanLoaded(laporanList: laporanList));
    } on DioException catch (e) {
      final message = _repository.getErrorMessage(
        e,
        fallback: 'Gagal terhubung ke server',
      );
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
      await _repository.createLaporan(
        jenisMasalah: event.jenisMasalah,
        deskripsi: event.deskripsi,
        kecamatanId: event.kecamatanId,
        prioritas: event.prioritas,
        fotoUrl: event.fotoUrl,
      );

      emit(LaporanCreated());
      add(LoadLaporanList());
    } on DioException catch (e) {
      final message = _repository.getErrorMessage(
        e,
        fallback: 'Gagal membuat laporan',
      );
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
      await _repository.updateLaporanStatus(id: event.id, status: event.status);
      emit(LaporanStatusUpdated());
      add(LoadLaporanList());
    } on DioException catch (e) {
      if (prev != null) emit(prev);
      emit(
        LaporanError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal memperbarui status',
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteLaporan(
      DeleteLaporan event, Emitter<LaporanState> emit,) async {
    emit(LaporanSubmitting());
    try {
      await _repository.deleteLaporan(event.id);
      emit(LaporanDeleted());
      add(LoadLaporanList());
    } on DioException catch (e) {
      emit(
        LaporanError(
          _repository.getErrorMessage(e, fallback: 'Gagal menghapus laporan'),
        ),
      );
    }
  }
}
