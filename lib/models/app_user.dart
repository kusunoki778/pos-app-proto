import 'package:cloud_firestore/cloud_firestore.dart';

/// Pengguna aplikasi. Role menentukan menu dan hak akses.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      name: (data['name'] ?? data['email'] ?? '') as String,
      role: (data['role'] ?? 'cashier') as String,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }
}
