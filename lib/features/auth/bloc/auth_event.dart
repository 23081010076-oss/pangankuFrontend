// Penjelasan file:
// Feature: auth
// Layer: logic
// File: auth_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
import 'package:equatable/equatable.dart';

// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

// Event ini mewakili aksi 'AuthSessionChecked' yang akan diproses oleh bloc.
class AuthSessionChecked extends AuthEvent {
  @override
  List<Object> get props => [];
}

// Event ini mewakili aksi 'AuthLoginRequested' yang akan diproses oleh bloc.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// Event ini mewakili aksi 'AuthRegisterRequested' yang akan diproses oleh bloc.
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.role = 'petani',
  });

  @override
  List<Object> get props => [name, email, password, phone, role];
}

// Event ini mewakili aksi 'AuthLogoutRequested' yang akan diproses oleh bloc.
class AuthLogoutRequested extends AuthEvent {
  @override
  List<Object> get props => [];
}

class AuthSessionExpired extends AuthEvent {
  @override
  List<Object> get props => [];
}
