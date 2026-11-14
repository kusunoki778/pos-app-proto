import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_communication/models/product_model.dart';
import 'package:realtime_communication/state/cart_controller.dart';

ProductModel _product(String id, {int stock = 10, int price = 5000}) {
  return ProductModel(
    id: id,
    name: 'Produk $id',
    categoryId: 'cat-1',
    price: price,
    stock: stock,
  );
}

void main() {
  test('keranjang kosong di awal', () {
    final cart = CartController();
    expect(cart.isEmpty, isTrue);
    expect(cart.itemCount, 0);
    expect(cart.subtotal, 0);
  });

  test('menambah produk baru dan menaikkan kuantitas', () {
    final cart = CartController();
    cart.add(_product('p1', stock: 3));
    cart.add(_product('p1', stock: 3));
    expect(cart.itemCount, 1);
    expect(cart.totalUnits, 2);
  });

  test('kuantitas tidak melebihi stok', () {
    final cart = CartController();
    final product = _product('p1', stock: 2);
    cart.add(product);
    cart.add(product);
    cart.add(product);
    expect(cart.quantityOf('p1'), 2);
  });

  test('produk nonaktif tidak bisa ditambahkan', () {
    final cart = CartController();
    cart.add(_product('p1', stock: 0));
    expect(cart.isEmpty, isTrue);
  });

  test('decrement menghapus item saat kuantitas 1', () {
    final cart = CartController();
    cart.add(_product('p1'));
    cart.decrement('p1');
    expect(cart.contains('p1'), isFalse);
  });

  test('subtotal dihitung dari line total', () {
    final cart = CartController();
    cart.add(_product('p1', price: 5000));
    cart.add(_product('p1'));
    cart.add(_product('p2', price: 7000));
    expect(cart.subtotal, 5000 * 2 + 7000);
  });

  test('remove dan clear mengosongkan keranjang', () {
    final cart = CartController();
    cart.add(_product('p1'));
    cart.add(_product('p2'));
    cart.remove('p1');
    expect(cart.itemCount, 1);
    cart.clear();
    expect(cart.isEmpty, isTrue);
  });

  test('notifyListeners dipanggil saat perubahan', () {
    var notified = 0;
    final cart = CartController()..addListener(() => notified++);
    cart.add(_product('p1'));
    cart.decrement('p1');
    expect(notified, 2);
  });
}
