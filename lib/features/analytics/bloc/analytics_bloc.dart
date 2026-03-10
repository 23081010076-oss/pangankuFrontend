import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final DioClient _client;

  AnalyticsBloc(this._client) : super(AnalyticsInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<RefreshDashboardStats>((_, __) => add(LoadDashboardStats()));
    on<LoadStatusPangan>(_onLoadStatusPangan);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final response = await _client.dio.get('/analytics/dashboard');
      if (response.statusCode == 200) {
        final stats =
            DashboardStats.fromJson(response.data as Map<String, dynamic>);
        emit(AnalyticsLoaded(stats));
      } else {
        emit(AnalyticsError('Gagal memuat data analitik'));
      }
    } on DioException catch (e) {
      emit(
        AnalyticsError(
          e.response?.data['error'] ?? 'Gagal terhubung ke server',
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
      final response = await _client.dio.get('/analytics/status-pangan');
      final List<dynamic> raw = (response.data is List)
          ? response.data as List<dynamic>
          : (response.data['data'] ?? []) as List<dynamic>;
      final items = raw
          .map((e) => StatusPanganItem.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(StatusPanganLoaded(items));
    } on DioException catch (e) {
      emit(
        StatusPanganError(
          e.response?.data['error'] ?? 'Gagal terhubung ke server',
        ),
      );
    } catch (e) {
      emit(StatusPanganError('Terjadi kesalahan: $e'));
    }
  }
}
