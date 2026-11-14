import 'package:cloud_firestore/cloud_firestore.dart';

/// Kategori produk. Kategori yang terpakai dinonaktifkan, bukan dihapus.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: data['description'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
