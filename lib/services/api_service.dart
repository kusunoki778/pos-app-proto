import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/app_user.dart';
import '../models/cart_item_model.dart';
import 'miomipay_service.dart';
import 'transaction_service.dart';

/// Hasil checkout via server atau MiomiPay direct (tagihan MiomiPay QRIS).
class OnlineCheckoutResult {
  const OnlineCheckoutResult({
    required this.transactionId,
    required this.total,
    this.paymentUrl,
    this.qrImageUrl,
    this.reference,
    this.expiresAt,
  });

  final String transactionId;
  final int total;
  final String? paymentUrl;
  final String? qrImageUrl;
  final String? reference;
  final DateTime? expiresAt;
}

/// Status pembayaran transaksi, untuk polling.
enum PaymentStatus { pending, paid, failed, expired }

/// Klien server Express & Payment Gateway MiomiPay.
/// Memiliki mekanisme failover otomatis: jika server Express lokal offline/mati,
/// transaksi QRIS akan otomatis terhubung langsung ke sandbox MiomiPay.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 8);

  Future<Map<String, dynamic>?> _post(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (Config.apiKey.isNotEmpty) 'X-API-Key': Config.apiKey,
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cek kesehatan koneksi server Express
  Future<bool> checkServerHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(Config.healthUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Minta server kirim notifikasi transaksi baru ke topic admin-alerts.
  Future<bool> notifyTransaction(String transactionId) {
    return _post(Uri.parse(Config.notifyUrl), {
      'transactionId': transactionId,
    }).then((json) => json?['ok'] == true);
  }

  /// Tombol "Tes Notifikasi" di Pengaturan.
  Future<bool> notifyTest() {
    return _post(Uri.parse(Config.notifyTestUrl), {
      'title': 'Tes notifikasi',
    }).then((json) => json?['ok'] == true);
  }

  /// Checkout QRIS:
  /// 1. Mencoba lewat server Express terlebih dahulu.
  /// 2. Jika server tidak aktif/gagal terhubung, otomatis fallback memanggil
  ///    MiomiPay API secara langsung (Direct Mode) dan mencatat transaksi ke Firestore.
  Future<OnlineCheckoutResult> checkoutQris({
    required List<CartItemModel> cartItems,
    required String idToken,
    required AppUser cashier,
  }) async {
    // 1. Coba lewat backend server lokal (jika sedang aktif)
    try {
      final response = await _client
          .post(
            Uri.parse('${Config.baseUrl}/api/checkout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'items': cartItems
                  .map((item) => {
                        'productId': item.productId,
                        'quantity': item.quantity,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return OnlineCheckoutResult(
          transactionId: body['transactionId'] as String,
          total: (body['total'] as num?)?.toInt() ?? 0,
          paymentUrl: body['paymentUrl'] as String?,
          qrImageUrl: body['qrImageUrl'] as String?,
          reference: body['reference'] as String?,
          expiresAt: body['expiresAt'] == null
              ? null
              : DateTime.tryParse(body['expiresAt'] as String),
        );
      }
    } catch (_) {
      // Server lokal mati atau tidak dapat dijangkau, lanjut ke fallback langsung
    }

    // 2. Direct Fallback: Langsung panggil MiomiPay Sandbox API
    final miomi = await MiomiPayService().createInvoice(
      items: cartItems,
      cashier: cashier,
    );

    // Simpan dokumen transaksi berstatus pending di Firestore
    final tx = await TransactionService().createPendingQrisTransaction(
      cashier: cashier,
      cartItems: cartItems,
      reference: miomi.reference,
      paymentUrl: miomi.paymentUrl,
      externalId: miomi.externalId,
    );

    return OnlineCheckoutResult(
      transactionId: tx.id,
      total: miomi.total,
      paymentUrl: miomi.paymentUrl,
      qrImageUrl: miomi.qrImageUrl,
      reference: miomi.reference,
      expiresAt: miomi.expiresAt,
    );
  }

  /// Polling status pembayaran.
  /// Memeriksa status lewat server atau langsung ke MiomiPay API.
  Future<PaymentStatus> pollStatus({
    required String transactionId,
    required String idToken,
    String? reference,
  }) async {
    // Coba tanya ke backend server
    try {
      final response = await _client
          .get(
            Uri.parse('${Config.baseUrl}/api/transactions/$transactionId/status'),
            headers: {'Authorization': 'Bearer $idToken'},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final st = body['paymentStatus'];
        if (st == 'paid') return PaymentStatus.paid;
        if (st == 'failed') return PaymentStatus.failed;
        if (st == 'expired') return PaymentStatus.expired;
      }
    } catch (_) {}

    // Fallback mandiri: Tanya langsung ke MiomiPay API jika reference tersedia
    if (reference != null && reference.isNotEmpty) {
      final remoteStatus = await MiomiPayService().checkStatus(reference);
      if (remoteStatus == 'PAID') {
        // Lunaskan transaksi di Firestore & potong stok
        await TransactionService().settleQrisTransaction(transactionId: transactionId);
        return PaymentStatus.paid;
      } else if (remoteStatus == 'EXPIRED') {
        return PaymentStatus.expired;
      } else if (remoteStatus == 'FAILED') {
        return PaymentStatus.failed;
      }
    }

    return PaymentStatus.pending;
  }

  void dispose() => _client.close();
}
