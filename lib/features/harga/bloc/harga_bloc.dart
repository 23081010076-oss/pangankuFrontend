import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'harga_event.dart';
import 'harga_state.dart';

class HargaBloc extends Bloc<HargaEvent, HargaState> {
  final DioClient _client;

  HargaBloc(this._client) : super(HargaInitial()) {
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
        _client.dio.get('/harga/latest'),
        _client.dio.get('/komoditas'),
      ]);

      final hargaResp = results[0];
      final komResp = results[1];

      final List<dynamic> hargaRaw = (() {
        final d = hargaResp.data;
        return (d is Map ? (d['data'] ?? []) : d ?? []) as List<dynamic>;
      })();

      final List<dynamic> komRaw = (() {
        final d = komResp.data;
        return (d is Map ? (d['data'] ?? []) : d ?? []) as List<dynamic>;
      })();

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
      emit(HargaError(
          e.response?.data is Map
              ? e.response!.data['error'] ?? 'Gagal terhubung ke server'
              : 'Gagal terhubung ke server',),);
    } catch (e) {
      emit(HargaError('Terjadi kesalahan: \$e'));
    }
  }

  Future<void> _onLoadHargaTrend(
      LoadHargaTrend event, Emitter<HargaState> emit,) async {
    final current = state is HargaLoaded ? state as HargaLoaded : null;
    try {
      final response = await _client.dio.get(
        '/harga/trend/${event.komoditasId}',
        queryParameters: {'periode': event.periode},
      );

      final raw = response.data;
      final List<dynamic> data =
          (raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : [])) as List<dynamic>;

      final trendData = data.map((j) => TrendData.fromJson(j)).toList();

      emit(HargaLoaded(
        hargaList: current?.hargaList ?? [],
        kategoris: current?.kategoris ?? [],
        trendData: trendData,
        selectedKomoditas: event.komoditasId,
      ),);
    } on DioException catch (e) {
      emit(HargaError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal memuat trend'
          : 'Gagal memuat trend',),);
    }
  }

  Future<void> _onCreateHarga(
      CreateHarga event, Emitter<HargaState> emit,) async {
    final current = state is HargaLoaded ? state as HargaLoaded : null;
    emit(HargaCreating());
    try {
      final response = await _client.dio.post('/harga', data: {
        'komoditas_id': event.komoditasId,
        'kecamatan_id': event.kecamatanId,
        'harga_per_kg': event.hargaPerKg,
        'tanggal': event.tanggal,
      },);
      if (response.statusCode == 201 || response.statusCode == 200) {
        emit(HargaCreated());
        add(LoadHargaList());
      } else {
        if (current != null) emit(current);
        emit(HargaError('Gagal menyimpan data harga'));
      }
    } on DioException catch (e) {
      if (current != null) emit(current);
      emit(HargaError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal menyimpan harga'
          : 'Gagal menyimpan harga',),);
    }
  }

  Future<void> _onUpdateHarga(
      UpdateHarga event, Emitter<HargaState> emit,) async {
    emit(HargaCreating());
    try {
      final response = await _client.dio.put('/harga/${event.id}', data: {
        'harga_per_kg': event.hargaPerKg,
        'tanggal': event.tanggal,
      },);
      if (response.statusCode == 200) {
        emit(HargaUpdated());
        add(LoadHargaList());
      } else {
        emit(HargaError('Gagal memperbarui data harga'));
      }
    } on DioException catch (e) {
      emit(HargaError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal memperbarui harga'
          : 'Gagal memperbarui harga',),);
    }
  }

  Future<void> _onDeleteHarga(
      DeleteHarga event, Emitter<HargaState> emit,) async {
    emit(HargaCreating());
    try {
      final response = await _client.dio.delete('/harga/${event.id}');
      if (response.statusCode == 200) {
        emit(HargaDeleted());
        add(LoadHargaList());
      } else {
        emit(HargaError('Gagal menghapus data harga'));
      }
    } on DioException catch (e) {
      emit(HargaError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal menghapus harga'
          : 'Gagal menghapus harga',),);
    }
  }
}
