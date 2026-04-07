import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/stok_repository.dart';
import 'stok_event.dart';
import 'stok_state.dart';

class StokBloc extends Bloc<StokEvent, StokState> {
  final StokRepository _repository;

  StokBloc(this._repository) : super(StokInitial()) {
    on<LoadStokList>(_onLoad);
    on<CreateOrUpdateStok>(_onCreateOrUpdateStok);
    on<DeleteStok>(_onDeleteStok);
    on<RefreshStok>(_onRefresh);
  }

  Future<void> _onLoad(LoadStokList event, Emitter<StokState> emit) async {
    emit(StokLoading());
    try {
      final list = await _repository.fetchStokList(
        komoditasId: event.komoditasId,
        kecamatanId: event.kecamatanId,
      );
      final items = list
          .map((j) => StokItem.fromJson(j))
          .toList();
      emit(StokLoaded(items));
    } on DioException catch (e) {
      emit(
        StokError(
          _repository.getErrorMessage(e, fallback: 'Gagal memuat data stok'),
        ),
      );
    } catch (e) {
      emit(StokError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onRefresh(RefreshStok event, Emitter<StokState> emit) async {
    add(LoadStokList());
  }

  Future<void> _onCreateOrUpdateStok(
      CreateOrUpdateStok event, Emitter<StokState> emit,) async {
    emit(StokSaving());
    try {
      await _repository.saveStok(
        komoditasId: event.komoditasId,
        kecamatanId: event.kecamatanId,
        stokKg: event.stokKg,
        kapasitasKg: event.kapasitasKg,
      );
      emit(StokSaved());
      add(LoadStokList());
    } on DioException catch (e) {
      emit(
        StokError(
          _repository.getErrorMessage(e, fallback: 'Gagal menyimpan stok'),
        ),
      );
    }
  }

  Future<void> _onDeleteStok(
      DeleteStok event, Emitter<StokState> emit,) async {
    emit(StokSaving());
    try {
      await _repository.deleteStok(event.id);
      emit(StokSaved());
      add(LoadStokList());
    } on DioException catch (e) {
      emit(
        StokError(
          _repository.getErrorMessage(e, fallback: 'Gagal menghapus stok'),
        ),
      );
    }
  }
}
