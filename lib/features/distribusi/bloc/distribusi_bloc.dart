// Penjelasan file:
// Feature: distribusi
// Layer: logic
// File: distribusi_bloc
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/distribusi_repository.dart';
import 'distribusi_event.dart';
import 'distribusi_state.dart';

// Bloc ini menerima event dari UI, menjalankan proses, lalu mengeluarkan state baru.
class DistribusiBloc extends Bloc<DistribusiEvent, DistribusiState> {
  final DistribusiRepository _repository;

  DistribusiBloc(this._repository) : super(DistribusiInitial()) {
    on<LoadDistribusiList>(_onLoad);
    on<CreateDistribusi>(_onCreateDistribusi);
    on<UpdateDistribusiStatus>(_onUpdateDistribusiStatus);
    on<DeleteDistribusi>(_onDeleteDistribusi);
    on<RefreshDistribusi>(_onRefresh);
  }

// Handler ini dijalankan saat event tertentu diterima oleh bloc.
  Future<void> _onLoad(
    LoadDistribusiList event,
    Emitter<DistribusiState> emit,
  ) async {
    emit(DistribusiLoading());
    try {
      final list = await _repository.fetchDistribusiList(status: event.status);
      final items = list.map((j) => DistribusiItem.fromJson(j)).toList();
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

// Handler ini dijalankan saat event tertentu diterima oleh bloc.
  Future<void> _onRefresh(
    RefreshDistribusi event,
    Emitter<DistribusiState> emit,
  ) async {
    add(LoadDistribusiList());
  }

// Handler ini dijalankan saat event tertentu diterima oleh bloc.
  Future<void> _onCreateDistribusi(
    CreateDistribusi event,
    Emitter<DistribusiState> emit,
  ) async {
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

// Handler ini dijalankan saat event tertentu diterima oleh bloc.
  Future<void> _onUpdateDistribusiStatus(
    UpdateDistribusiStatus event,
    Emitter<DistribusiState> emit,
  ) async {
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

// Handler ini dijalankan saat event tertentu diterima oleh bloc.
  Future<void> _onDeleteDistribusi(
    DeleteDistribusi event,
    Emitter<DistribusiState> emit,
  ) async {
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
