import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

/// Pembuatan transaksi dan riwayat.
/// Nominal dihitung ulang dari data produk di Firestore (bukan dari UI),
/// sesuai PRD §10.2. Tahap 7 (backend) akan memindahkan validasi ini
/// ke Express, dan MiomiPay menyusul.
class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Nomor transaksi dari waktu saat ini, unik cukup untuk per detik.
  static String generateNumber(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'POS-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  /// Checkout tunai (pengganti sementara MiomiPay):
  /// satu Firestore transaction: verifikasi stok + harga, kurangi stok,
  /// simpan transaksi berstatus paid.
  Future<TransactionModel> checkoutCash({
    required AppUser cashier,
    required List<CartItemModel> cartItems,
    required int paid,
  }) async {
    final subtotal = cartItems
        .fold<int>(0, (acc, item) => acc + item.unitPrice * item.quantity);
    if (paid < subtotal) {
      throw ArgumentError('Nominal bayar kurang dari total');
    }
    final change = paid - subtotal;

    final result = await _db.runTransaction<(String, List<Map<String, dynamic>>)>(
      (transaction) async {
        final checks = <(ProductModel, int)>[];
        // Baca semua produk dulu, tulis belakangan (aturan Firestore transaction).
        for (final item in cartItems) {
          final snap = await transaction.get(_products.doc(item.productId));
          if (!snap.exists) {
            throw Exception('Produk tidak ditemukan: ${item.productName}');
          }
          final product = ProductModel.fromFirestore(snap);
          if (!product.isActive) {
            throw Exception('Produk nonaktif: ${product.name}');
          }
          if (product.stock < item.quantity) {
            throw Exception(
              'Stok ${product.name} tinggal ${product.stock}, '
              'keranjang minta ${item.quantity}',
            );
          }
          checks.add((product, item.quantity));
        }

        var subtotal = 0;
        final itemsSnapshot = <Map<String, dynamic>>[];
        for (final (product, quantity) in checks) {
          final lineTotal = product.price * quantity;
          subtotal += lineTotal;
          itemsSnapshot.add({
            'productId': product.id,
            'productName': product.name,
            'unitPrice': product.price,
            'quantity': quantity,
            'lineTotal': lineTotal,
          });
          transaction.update(_products.doc(product.id), {
            'stock': product.stock - quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final doc = _transactions.doc();
        transaction.set(doc, {
          'transactionNumber': generateNumber(DateTime.now()),
          'cashierId': cashier.uid,
          'cashierName': cashier.name,
          'items': itemsSnapshot,
          'subtotal': subtotal,
          'discount': 0,
          'total': subtotal,
          'currency': 'IDR',
          'paymentMethod': 'tunai',
          'paymentStatus': 'paid',
          'transactionStatus': 'paid',
          'providerReference': null,
          'paymentUrl': null,
          'paid': paid,
          'change': change,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'paidAt': FieldValue.serverTimestamp(),
        });
        return (doc.id, itemsSnapshot);
      },
    );

    final (docId, _) = result;
    final saved = await _transactions.doc(docId).get();
    return TransactionModel.fromFirestore(saved);
  }

  /// Detail transaksi untuk layar detail. Rules menolak transaksi
  /// milik pengguna lain; permission-denied diterjemahkan jadi null.
  Future<TransactionModel?> getTransactionById(String id) async {
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _transactions.doc(id).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
    if (!snap.exists) return null;
    return TransactionModel.fromFirestore(snap);
  }

  /// Riwayat: admin melihat semua, kasir hanya miliknya.
  Stream<List<TransactionModel>> streamTransactions({
    required bool seeAll,
    required String uid,
  }) {
    Query<Map<String, dynamic>> query = _transactions;
    if (!seeAll) {
      query = query.where('cashierId', isEqualTo: uid);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs.map(TransactionModel.fromFirestore).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
