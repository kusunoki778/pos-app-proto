
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Pembungkus FirebaseAuth dan Firestore.
/// Controller tidak menyentuh SDK langsung agar mudah diganti saat tes.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Mengembalikan null kalau dokumen user belum dibuat oleh seed.
  Future<AppUser?> fetchUserDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  /// Firebase ID token untuk dikirim ke server Express
  /// (dipakai endpoint /api/checkout dan polling status).
  Future<String> getIdToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Belum login');
    }

    final token = await user.getIdToken();

    if (token == null) {
      throw StateError('Gagal mendapatkan Firebase ID Token');
    }

    return token;
  }
}
