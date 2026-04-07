import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/distribusi_repository.dart';
import 'distribusi_event.dart';
import 'distribusi_state.dart';

class DistribusiBloc extends Bloc<DistribusiEvent, DistribusiState> {
  final DistribusiRepository _repository;

  DistribusiBloc(this._repository) : super(DistribusiInitial()) {
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
      final list = await _repository.fetchDistribusiList(status: event.status);
      final items = list
          .map((j) => DistribusiItem.fromJson(j))
          .toList();
      emit(DistribusiLoaded(items));
    } on DioException catch (e) {
      emit(
        DistribusiError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal memuat data distribusi',
          ),
        ),
      );
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
      await _repository.createDistribusi(
        dariKecamatanId: event.dariKecamatanId,
        keKecamatanId: event.keKecamatanId,
        komoditasId: event.komoditasId,
        jumlahKg: event.jumlahKg,
        jadwalBerangkat: event.jadwalBerangkat,
        namaDriver: event.namaDriver,
        namaKendaraan: event.namaKendaraan,
      );
      emit(DistribusiSaved());
      add(LoadDistribusiList());
    } on DioException catch (e) {
      emit(
        DistribusiError(
          _repository.getErrorMessage(e, fallback: 'Gagal membuat jadwal'),
        ),
      );
    }
  }

  Future<void> _onUpdateDistribusiStatus(
      UpdateDistribusiStatus event, Emitter<DistribusiState> emit,) async {
    try {
      await _repository.updateDistribusiStatus(
        id: event.id,
        status: event.status,
      );
      emit(DistribusiStatusUpdated());
      add(LoadDistribusiList());
    } on DioException catch (e) {
      emit(
        DistribusiError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal memperbarui status',
          ),
        ),
      );
    }
  }

  Future<void> _onDeleteDistribusi(
      DeleteDistribusi event, Emitter<DistribusiState> emit,) async {
    emit(DistribusiSaving());
    try {
      await _repository.deleteDistribusi(event.id);
      emit(DistribusiSaved());
      add(LoadDistribusiList());
    } on DioException catch (e) {
      emit(
        DistribusiError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal menghapus distribusi',
          ),
        ),
      );
    }
  }
}
