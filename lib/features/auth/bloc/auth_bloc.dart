import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DioClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthBloc(this._client) : super(AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      // Cek validitas token dengan endpoint /auth/me
      try {
        final res = await _client.dio.get('/auth/me');
        emit(
          AuthAuthenticated(
            name: res.data['name'],
            role: res.data['role'],
            userId: res.data['id'],
          ),
        );
      } catch (_) {
        await _storage.deleteAll();
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {
          'email': event.email,
          'password': event.password,
        },
      );

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: res.data['access_token'],
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: res.data['refresh_token'],
      );
      await _storage.write(
        key: AppConstants.userRoleKey,
        value: res.data['user']['role'],
      );
      await _storage.write(
        key: AppConstants.userNameKey,
        value: res.data['user']['name'],
      );
      await _storage.write(
        key: AppConstants.userIdKey,
        value: res.data['user']['id'],
      );

      emit(
        AuthAuthenticated(
          name: res.data['user']['name'],
          role: res.data['user']['role'],
          userId: res.data['user']['id'],
        ),
      );
    } on DioException catch (e) {
      final msg = _client.getErrorMessage(e);
      emit(AuthError(msg));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final res = await _client.dio.post(
        '/auth/register',
        data: {
          'name': event.name,
          'email': event.email,
          'password': event.password,
          'phone': event.phone,
          'role': event.role,
        },
      );

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: res.data['access_token'],
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: res.data['refresh_token'],
      );
      await _storage.write(
        key: AppConstants.userRoleKey,
        value: res.data['user']['role'],
      );
      await _storage.write(
        key: AppConstants.userNameKey,
        value: res.data['user']['name'],
      );
      await _storage.write(
        key: AppConstants.userIdKey,
        value: res.data['user']['id'],
      );

      emit(
        AuthAuthenticated(
          name: res.data['user']['name'],
          role: res.data['user']['role'],
          userId: res.data['user']['id'],
        ),
      );
    } on DioException catch (e) {
      final msg = _client.getErrorMessage(e);
      emit(AuthError(msg));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // Ignore error, tetap logout di client
    }
    await _storage.deleteAll();
    emit(AuthUnauthenticated());
  }
}
