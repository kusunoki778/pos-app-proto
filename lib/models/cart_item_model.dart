// Item di keranjang. Snapshot nama dan harga saat ditambahkan,
// mengikuti pola `items[]` pada transaksi.
import 'product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final String? imageUrl;

  int get lineTotal => unitPrice * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  factory CartItemModel.fromProduct(ProductModel product, {int quantity = 1}) {
    return CartItemModel(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
      imageUrl: product.imageUrl,
    );
  }
}
