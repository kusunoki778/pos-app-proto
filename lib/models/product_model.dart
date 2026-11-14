import 'package:cloud_firestore/cloud_firestore.dart';

/// Produk toko. Nominal harga integer rupiah, stok tidak boleh negatif.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final int price;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get available => isActive && stock > 0;

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: data['description'] as String?,
      categoryId: (data['categoryId'] ?? '') as String,
      price: (data['price'] ?? 0) as int,
      stock: (data['stock'] ?? 0) as int,
      imageUrl: data['imageUrl'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
