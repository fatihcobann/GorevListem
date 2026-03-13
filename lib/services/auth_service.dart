// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Başarılı işlemde user, başarsız işlemde errorMessage döner.

class AuthResult {
  final User? user;
  final String? errorMessage;

  AuthResult({this.user, this.errorMessage});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcıyı stream olarak dinle
  Stream<User?> get user => _auth.authStateChanges();

  // E-posta ve şifre ile kayıt olma
  Future<AuthResult> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult(user: result.user);
    } on FirebaseException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Şifre çok zayıf. En az 6 karakter kullanın.';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda.';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi.';
          break;
        default:
          message = 'Kayıt başarısız: ${e.message}';
      }
      return AuthResult(errorMessage: message);
    } catch (e) {
      return AuthResult(errorMessage: 'Beklenmeyen bir hata oluştu.');
    }
  }

  // E-posta ve şifre ile giriş yapma
  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult(user: result.user);
    } on FirebaseAuthException {
      return AuthResult(errorMessage: 'E-posta veya şifre geçersiz.');
    } on FirebaseException {
      return AuthResult(errorMessage: 'E-posta veya şifre geçersiz.');
    } catch (_) {
      return AuthResult(errorMessage: 'E-posta veya şifre geçersiz.');
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    // Beni Hatırla tercihini sıfırla
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await _auth.signOut();
  }

  // Şifre sıfırlama e-postası gönder
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(user: null, errorMessage: null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi.';
          break;
        default:
          message = 'Şifre sıfırlama e-postası gönderilemedi: ${e.message}';
      }
      return AuthResult(errorMessage: message);
    } catch (e) {
      return AuthResult(errorMessage: 'Beklenmeyen bir hata oluştu.');
    }
  }

  // E-posta doğrulama e-postası gönder
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult(user: user, errorMessage: null);
      } else if (user != null && user.emailVerified) {
        return AuthResult(errorMessage: 'E-posta zaten doğrulanmış.');
      }
      return AuthResult(errorMessage: 'Kullanıcı bulunamadı.');
    } catch (e) {
      return AuthResult(errorMessage: 'Doğrulama e-postası gönderilemedi.');
    }
  }

  // E-posta doğrulama durumunu kontrol et
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Kullanıcı bilgilerini yenile
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;
}
