// Penjelasan file:
// Feature: auth
// Layer: logic
// File: auth_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
import 'package:equatable/equatable.dart';

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class AuthState extends Equatable {
  const AuthState();
}

// State ini menunjukkan kondisi 'AuthInitial' pada fitur ini.
class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

// State ini menunjukkan kondisi 'AuthLoading' pada fitur ini.
class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

// State ini menunjukkan kondisi 'AuthAuthenticated' pada fitur ini.
class AuthAuthenticated extends AuthState {
  final String name;
  final String role;
  final String userId;

  const AuthAuthenticated({
    required this.name,
    required this.role,
    required this.userId,
  });

  @override
  List<Object> get props => [name, role, userId];
}

// State ini menunjukkan kondisi 'AuthUnauthenticated' pada fitur ini.
class AuthUnauthenticated extends AuthState {
  @override
  List<Object> get props => [];
}

// State ini menunjukkan kondisi 'AuthError' pada fitur ini.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
