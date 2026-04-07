import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsBloc(this._repository) : super(AnalyticsInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<RefreshDashboardStats>((event, _) => add(LoadDashboardStats(periode: event.periode)));
    on<LoadStatusPangan>(_onLoadStatusPangan);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchDashboardStats(periode: event.periode);
      final stats = DashboardStats.fromJson(data);
      emit(AnalyticsLoaded(stats));
    } on DioException catch (e) {
      emit(
        AnalyticsError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal terhubung ke server',
          ),
        ),
      );
    } catch (e) {
      emit(AnalyticsError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onLoadStatusPangan(
    LoadStatusPangan event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(StatusPanganLoading());
    try {
      final raw = await _repository.fetchStatusPangan();
      final items = raw
          .map((e) => StatusPanganItem.fromJson(e))
          .toList();
      emit(StatusPanganLoaded(items));
    } on DioException catch (e) {
      emit(
        StatusPanganError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal terhubung ke server',
          ),
        ),
      );
    } catch (e) {
      emit(StatusPanganError('Terjadi kesalahan: $e'));
    }
  }
}
