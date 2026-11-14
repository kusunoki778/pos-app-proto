import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item_model.dart';

/// Transaksi POS. Harga dan total di sisi app hanya untuk tampilan;
/// kebenaran nominal divalidasi backend (Tahap 7).
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.cashierId,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    this.currency = 'IDR',
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionStatus = 'pending',
    this.providerReference,
    this.paymentUrl,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.paid,
    this.change,
  });

  final String id;
  final String transactionNumber;
  final String cashierId;
  final List<CartItemModel> items;
  final int subtotal;
  final int discount;
  final int total;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionStatus;
  final String? providerReference;
  final String? paymentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  /// Nilai uang yang dibayarkan dan kembalian (checkout tunai).
  final int? paid;
  final int? change;

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawItems = (data['items'] ?? const []) as List<dynamic>;
    return TransactionModel(
      id: doc.id,
      transactionNumber: (data['transactionNumber'] ?? '') as String,
      cashierId: (data['cashierId'] ?? '') as String,
      items: rawItems
          .map((e) => _itemFrom((e as Map).cast<String, dynamic>()))
          .toList(),
      subtotal: (data['subtotal'] ?? 0) as int,
      discount: (data['discount'] ?? 0) as int,
      total: (data['total'] ?? 0) as int,
      currency: (data['currency'] ?? 'IDR') as String,
      paymentMethod: (data['paymentMethod'] ?? '') as String,
      paymentStatus: (data['paymentStatus'] ?? 'pending') as String,
      transactionStatus: (data['transactionStatus'] ?? 'pending') as String,
      providerReference: data['providerReference'] as String?,
      paymentUrl: data['paymentUrl'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      paidAt: _date(data['paidAt']),
      paid: data['paid'] as int?,
      change: data['change'] as int?,
    );
  }

  static CartItemModel _itemFrom(Map<String, dynamic> map) {
    return CartItemModel(
      productId: (map['productId'] ?? '') as String,
      productName: (map['productName'] ?? '') as String,
      unitPrice: (map['unitPrice'] ?? 0) as int,
      quantity: (map['quantity'] ?? 0) as int,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
