import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // User objesi için lazım

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Başlangıç (Nötr)
class AuthInitial extends AuthState {}

// İşlem Yapılıyor (Dönen Tekerlek)
class AuthLoading extends AuthState {}

// Başarılı Giriş Yapıldı (Elimizde Kullanıcı Var)
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

// Hata Oldu (Yanlış şifre vb.)
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

// mail başarıyla gönderildi durumu
class AuthPasswordResetSuccess extends AuthState {}
