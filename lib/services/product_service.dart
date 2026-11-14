import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

/// Akses Firestore untuk kategori dan produk.
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Kategori aktif, diurutkan di sisi client agar tidak butuh index.
  Stream<List<CategoryModel>> streamActiveCategories() {
    return _categories
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map(CategoryModel.fromFirestore).where((c) => c.name.isNotEmpty).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Daftar produk realtime. Filter dan urut dilakukan client-side
  /// supaya tidak perlu composite index.
  Stream<List<ProductModel>> streamProducts({bool activeOnly = false}) {
    var query = _products.where('isActive', isEqualTo: true);
    if (!activeOnly) query = _products;
    return query.snapshots().map((snap) {
      final list = snap.docs.map(ProductModel.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> addProduct(ProductModel product) async {
    final now = FieldValue.serverTimestamp();
    await _products.add({
      ...product.toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateProduct(ProductModel product) async {
    await _products.doc(product.id).update(product.toMap());
  }

  Future<void> setProductActive(ProductModel product, bool active) async {
    await _products.doc(product.id).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(ProductModel product) async {
    await _products.doc(product.id).delete();
  }
}
