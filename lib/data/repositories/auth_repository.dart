import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kitaptakas/data/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
    required String location,
    String? photoBase64,
    int? setPoint,
    bool deletePhoto = false,
  }) async {
    final Map<String, dynamic> data = {
      'id': userId,
      'email': email,
      'name': name,
      'location': location,
      //'tradePoints': 100,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (deletePhoto) {
      data['photoUrl'] = FieldValue.delete();
    } else if (photoBase64 != null) {
      data['photoUrl'] = photoBase64;
    }
    if (setPoint != null) {
      data['tradePoints'] = setPoint;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception("Kullanıcı verisi alınamadı: $e");
    }
  }

  // --- GİRİŞ YAP ---
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bu e-posta ile kayıtlı kullanıcı bulunamadı.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Şifre yanlış.');
      } else {
        throw Exception(e.message ?? 'Giriş yapılamadı.');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  // --- KAYIT OL ---
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Şifre çok zayıf.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Bu e-posta zaten kullanımda.');
      } else {
        throw Exception(e.message ?? 'Kayıt olunamadı.');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      throw Exception("Google girişi başarısız: $e");
    }
  }

  // Şifremi unuttum
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Geçersiz e-posta adresi.');
      } else {
        throw Exception(e.message ?? 'Bir hata oluştu.');
      }
    } catch (e) {
      throw Exception('Mail gönderilemedi: $e');
    }
  }

  // Kullanıcı arama
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Arama sırasında hata: $e");
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // --- MEVCUT KULLANICIYI AL ---
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get userStream => _firebaseAuth.authStateChanges();
}
