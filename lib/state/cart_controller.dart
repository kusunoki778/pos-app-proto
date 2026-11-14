import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

/// Keranjang kasir. Kuantitas dibatasi stok produk saat itu.
class CartController extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  List<CartItemModel> get items => _items.values.toList(growable: false);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  int get totalUnits =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  bool contains(String productId) => _items.containsKey(productId);
  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  void add(ProductModel product) {
    if (!product.available) return;
    final existing = _items[product.id];
    if (existing == null) {
      _items[product.id] = CartItemModel.fromProduct(product);
    } else if (existing.quantity < product.stock) {
      _items[product.id] = existing.copyWith(quantity: existing.quantity + 1);
    }
    notifyListeners();
  }

  void decrement(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
