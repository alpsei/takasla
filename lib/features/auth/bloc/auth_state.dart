import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Başlangıç Durumu
class AuthInitial extends AuthState {}

// İşlem Yapılıyor
class AuthLoading extends AuthState {}

// Başarılı Giriş Yapıldı
class AuthAuthenticated extends AuthState {
  final User user;
  final String role;

  const AuthAuthenticated(this.user, this.role);

  @override
  List<Object> get props => [user, role];
}

class AuthUnauthenticated extends AuthState {}

// Hata Oldu
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

// mail başarıyla gönderildi durumu
class AuthPasswordResetSuccess extends AuthState {}
