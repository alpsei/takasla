import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    _authRepository.userStream.listen((User? user) {
      add(AuthStatusChanged(user));
    });
    Future.delayed(Duration.zero, () {
      final user = _authRepository.currentUser;
      add(AuthStatusChanged(user));
    });
    on<AuthStatusChanged>((event, emit) async {
      if (event.user != null) {
        final role = await _authRepository.getUserRole(event.user!.uid);
        emit(AuthAuthenticated(event.user!, role));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    // Şifre sıfırlama isteği gelirse
    on<AuthResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authRepository.sendPasswordResetEmail(event.email);
        emit(AuthPasswordResetSuccess());
        emit(AuthInitial());
      } catch (e) {
        final message = e.toString().replaceAll("Exception: ", "");
        emit(AuthFailure(message));
      }
    });
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authRepository.signIn(
          email: event.email,
          password: event.password,
        );

        if (user != null) {
          final role = await _authRepository.getUserRole(user.uid);
          emit(AuthAuthenticated(user, role));
        } else {
          emit(const AuthFailure("Giriş yapılamadı."));
        }
      } catch (e) {
        final message = e.toString().replaceAll("Exception: ", "");
        emit(AuthFailure(message));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authRepository.signUp(
          email: event.email,
          password: event.password,
        );

        if (user != null) {
          await _authRepository.saveUserData(
            userId: user.uid,
            email: event.email,
            name: "Kitap Sever",
            location: "Konum Yok",
            photoBase64: null,
            setPoint: 100,
            role: 'user',
          );
          emit(AuthAuthenticated(user, 'user'));
        } else {
          emit(const AuthFailure("Kayıt olunamadı."));
        }
      } catch (e) {
        final message = e.toString().replaceAll("Exception: ", "");
        emit(AuthFailure(message));
      }
    });
    on<AuthGoogleLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authRepository.signInWithGoogle();
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
        String role = 'user';
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
        }
        if (!userDoc.exists) {
          await _authRepository.saveUserData(
            userId: user!.uid,
            email: user.email ?? "",
            name: user.displayName ?? "Kitap Sever",
            location: "Konum Yok",
            photoBase64: null,
            setPoint: 100,
            role: role,
          );

          emit(AuthAuthenticated(user, role));
        } else {
          role = userDoc.data()?['role'] as String? ?? 'user';
          emit(AuthInitial());
        }
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll("Exception: ", "")));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _authRepository.signOut();
      emit(AuthInitial());
    });

    // Kullanıcı var mı diye kontrol et
    on<AuthCheckRequest>((event, emit) async {
      final user = _authRepository.currentUser;
      if (user != null) {
        final role = await _authRepository.getUserRole(user.uid);
        emit(AuthAuthenticated(user, role));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
}
