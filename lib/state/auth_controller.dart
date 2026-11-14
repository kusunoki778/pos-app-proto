import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthPhase { loading, unauthenticated, authenticated }

/// Sumber kebenaran status login. Aplikasi hanya punya satu instance.
class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;
  StreamSubscription<User?>? _sub;

  AuthPhase phase = AuthPhase.loading;
  AppUser? user;
  String? errorMessage;
  bool busy = false;

  Future<void> init() async {
    _sub = _service.authStateChanges.listen(_handleAuthState);
    // Tunggu emissi pertama supaya AuthGate tidak berkedip.
    await _service.authStateChanges.first;
  }

  Future<void> _handleAuthState(User? fbUser) async {
    if (fbUser == null) {
      user = null;
      phase = AuthPhase.unauthenticated;
      notifyListeners();
      return;
    }

    phase = AuthPhase.loading;
    notifyListeners();

    try {
      final profile = await _service.fetchUserDoc(fbUser.uid);
      if (profile == null) {
        errorMessage = 'Akun ini belum terdaftar sebagai pengguna. '
            'Minta admin menjalankan seed.';
        await _service.signOut();
        return;
      }
      if (!profile.isActive) {
        errorMessage = 'Akun Anda dinonaktifkan.';
        await _service.signOut();
        return;
      }
      user = profile;
      errorMessage = null;
      phase = AuthPhase.authenticated;
    } catch (e) {
      errorMessage = 'Gagal memuat profil: $e';
      await _service.signOut();
    }
    notifyListeners();
  }

  /// Mengembalikan true bila proses login sukses (listener akan lanjut).
  Future<bool> signIn(String email, String password) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.signIn(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _messageFor(e);
      return false;
    } catch (e) {
      errorMessage = 'Login gagal: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _service.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun Anda dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Koneksi bermasalah. Periksa internet Anda.';
      default:
        return 'Login gagal (${e.code}).';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
