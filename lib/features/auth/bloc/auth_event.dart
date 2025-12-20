import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Giriş Yapma İsteği
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

// Kayıt Olma İsteği
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthRegisterRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthCheckRequest extends AuthEvent {}

// Çıkış Yapma İsteği
class AuthLogoutRequested extends AuthEvent {}

// Google ile giriş yapma
class AuthGoogleLoginRequested extends AuthEvent {}

// Şifre Sıfırlama İsteği
class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  const AuthResetPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthStatusChanged extends AuthEvent {
  final User? user;
  const AuthStatusChanged(this.user);

  @override
  List<Object> get props => [?user];
}
