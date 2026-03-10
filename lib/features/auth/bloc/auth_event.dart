import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthSessionChecked extends AuthEvent {
  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  List<Object> get props => [name, email, password, phone];
}

class AuthLogoutRequested extends AuthEvent {
  @override
  List<Object> get props => [];
}
