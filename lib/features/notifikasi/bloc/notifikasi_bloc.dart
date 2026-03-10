import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'notifikasi_event.dart';
import 'notifikasi_state.dart';

class NotifikasiBloc extends Bloc<NotifikasiEvent, NotifikasiState> {
  final DioClient _client;

  NotifikasiBloc(this._client) : super(NotifikasiInitial()) {
    on<LoadNotifikasiList>(_onLoad);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllRead>(_onMarkAllRead);
    on<RefreshNotifikasi>(_onRefresh);
  }

  Future<void> _onLoad(
      LoadNotifikasiList event, Emitter<NotifikasiState> emit,) async {
    emit(NotifikasiLoading());
    try {
      final response = await _client.dio.get('/notifikasi');
      final data = response.data;
      final List<dynamic> list = data['data'] ?? (data is List ? data : []);
      final items = list
          .map((j) => NotifikasiItem.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(NotifikasiLoaded(items));
    } on DioException catch (e) {
      emit(NotifikasiError(
          e.response?.data?['error'] as String? ?? 'Gagal memuat notifikasi',),);
    } catch (e) {
      emit(NotifikasiError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onMarkAsRead(
      MarkAsRead event, Emitter<NotifikasiState> emit,) async {
    try {
      await _client.dio.put('/notifikasi/${event.id}/read');
      if (state is NotifikasiLoaded) {
        final current = (state as NotifikasiLoaded).items;
        final updated = current
            .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
            .toList();
        emit(NotifikasiLoaded(updated));
      }
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
      MarkAllRead event, Emitter<NotifikasiState> emit,) async {
    try {
      await _client.dio.put('/notifikasi/read-all');
      if (state is NotifikasiLoaded) {
        final updated = (state as NotifikasiLoaded)
            .items
            .map((n) => n.copyWith(isRead: true))
            .toList();
        emit(NotifikasiLoaded(updated));
      }
    } catch (_) {}
  }

  Future<void> _onRefresh(
      RefreshNotifikasi event, Emitter<NotifikasiState> emit,) async {
    add(LoadNotifikasiList());
  }
}
