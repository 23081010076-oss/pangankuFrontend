import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/harga_repository.dart';
import 'harga_event.dart';
import 'harga_state.dart';

class HargaBloc extends Bloc<HargaEvent, HargaState> {
  final HargaRepository _repository;

  HargaBloc(this._repository) : super(HargaInitial()) {
    on<LoadHargaList>(_onLoadHargaList);
    on<LoadHargaTrend>(_onLoadHargaTrend);
    on<CreateHarga>(_onCreateHarga);
    on<UpdateHarga>(_onUpdateHarga);
    on<DeleteHarga>(_onDeleteHarga);
    on<RefreshHarga>((_, __) => add(LoadHargaList()));
  }

  Future<void> _onLoadHargaList(
      LoadHargaList event, Emitter<HargaState> emit,) async {
    emit(HargaLoading());
    try {
      final results = await Future.wait([
        _repository.fetchLatestHarga(),
        _repository.fetchKomoditas(),
      ]);

      final hargaRaw = results[0];
      final komRaw = results[1];

      final Map<String, String> kategoriMap = {};
      for (final k in komRaw) {
        final id = k['id']?.toString() ?? '';
        final kat = k['kategori']?.toString() ?? '';
        if (id.isNotEmpty) kategoriMap[id] = kat;
      }

      final hargaList = hargaRaw.map((json) {
        final komId = json['komoditas_id']?.toString() ?? '';
        return HargaItem.fromJson(json, kategori: kategoriMap[komId] ?? '');
      }).toList();

      final kategoris = kategoriMap.values
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      emit(HargaLoaded(hargaList: hargaList, kategoris: kategoris));
    } on DioException catch (e) {
      emit(
        HargaError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal terhubung ke server',
          ),
        ),
      );
    } catch (e) {
      emit(HargaError('Terjadi kesalahan: \$e'));
    }
  }

  Future<void> _onLoadHargaTrend(
      LoadHargaTrend event, Emitter<HargaState> emit,) async {
    final current = state is HargaLoaded ? state as HargaLoaded : null;
    try {
      final data = await _repository.fetchHargaTrend(
        komoditasId: event.komoditasId,
        periode: event.periode,
      );

      final trendData = data.map((j) => TrendData.fromJson(j)).toList();

      emit(HargaLoaded(
        hargaList: current?.hargaList ?? [],
        kategoris: current?.kategoris ?? [],
        trendData: trendData,
        selectedKomoditas: event.komoditasId,
      ),);
    } on DioException catch (e) {
      emit(
        HargaError(
          _repository.getErrorMessage(e, fallback: 'Gagal memuat trend'),
        ),
      );
    }
  }

  Future<void> _onCreateHarga(
      CreateHarga event, Emitter<HargaState> emit,) async {
    final current = state is HargaLoaded ? state as HargaLoaded : null;
    emit(HargaCreating());
    try {
      await _repository.createHarga(
        komoditasId: event.komoditasId,
        kecamatanId: event.kecamatanId,
        hargaPerKg: event.hargaPerKg,
        tanggal: event.tanggal,
      );
      emit(HargaCreated());
      add(LoadHargaList());
    } on DioException catch (e) {
      if (current != null) emit(current);
      emit(
        HargaError(
          _repository.getErrorMessage(e, fallback: 'Gagal menyimpan harga'),
        ),
      );
    }
  }

  Future<void> _onUpdateHarga(
      UpdateHarga event, Emitter<HargaState> emit,) async {
    emit(HargaCreating());
    try {
      await _repository.updateHarga(
        id: event.id,
        hargaPerKg: event.hargaPerKg,
        tanggal: event.tanggal,
      );
      emit(HargaUpdated());
      add(LoadHargaList());
    } on DioException catch (e) {
      emit(
        HargaError(
          _repository.getErrorMessage(e, fallback: 'Gagal memperbarui harga'),
        ),
      );
    }
  }

  Future<void> _onDeleteHarga(
      DeleteHarga event, Emitter<HargaState> emit,) async {
    emit(HargaCreating());
    try {
      await _repository.deleteHarga(event.id);
      emit(HargaDeleted());
      add(LoadHargaList());
    } on DioException catch (e) {
      emit(
        HargaError(
          _repository.getErrorMessage(e, fallback: 'Gagal menghapus harga'),
        ),
      );
    }
  }
}
