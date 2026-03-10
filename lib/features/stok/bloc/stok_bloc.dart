import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'stok_event.dart';
import 'stok_state.dart';

class StokBloc extends Bloc<StokEvent, StokState> {
  final DioClient _client;

  StokBloc(this._client) : super(StokInitial()) {
    on<LoadStokList>(_onLoad);
    on<CreateOrUpdateStok>(_onCreateOrUpdateStok);
    on<RefreshStok>(_onRefresh);
  }

  Future<void> _onLoad(LoadStokList event, Emitter<StokState> emit) async {
    emit(StokLoading());
    try {
      final params = <String, dynamic>{'limit': 200};
      if (event.komoditasId != null) params['komoditas_id'] = event.komoditasId;
      if (event.kecamatanId != null) params['kecamatan_id'] = event.kecamatanId;

      final response = await _client.dio.get('/stok', queryParameters: params);
      final data = response.data;
      final List<dynamic> list = data['data'] ?? (data is List ? data : []);
      final items = list
          .map((j) => StokItem.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(StokLoaded(items));
    } on DioException catch (e) {
      emit(StokError(
          e.response?.data?['error'] as String? ?? 'Gagal memuat data stok',),);
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
      final response = await _client.dio.post('/stok', data: {
        'komoditas_id': event.komoditasId,
        'kecamatan_id': event.kecamatanId,
        'stok_kg': event.stokKg,
        'kapasitas_kg': event.kapasitasKg,
      },);
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(StokSaved());
        add(LoadStokList());
      } else {
        emit(StokError('Gagal menyimpan stok'));
      }
    } on DioException catch (e) {
      emit(StokError(e.response?.data is Map
          ? e.response!.data['error'] ?? 'Gagal menyimpan stok'
          : 'Gagal menyimpan stok',),);
    }
  }
}
