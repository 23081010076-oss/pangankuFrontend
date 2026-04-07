import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    final session = await _repository.restoreSession();
    if (session == null) {
      emit(AuthUnauthenticated());
      return;
    }

    emit(
      AuthAuthenticated(
        name: session.name,
        role: session.role,
        userId: session.userId,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );

      emit(
        AuthAuthenticated(
          name: user.name,
          role: user.role,
          userId: user.userId,
        ),
      );
    } on DioException catch (e) {
      final msg = _repository.getErrorMessage(e);
      emit(AuthError(msg));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        role: event.role,
      );

      emit(
        AuthAuthenticated(
          name: user.name,
          role: user.role,
          userId: user.userId,
        ),
      );
    } on DioException catch (e) {
      final msg = _repository.getErrorMessage(e);
      emit(AuthError(msg));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(AuthUnauthenticated());
  }
}
