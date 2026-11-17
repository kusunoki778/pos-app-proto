import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/cart_item_model.dart';

class MiomiInvoiceResult {
  const MiomiInvoiceResult({
    required this.reference,
    required this.paymentUrl,
    required this.qrImageUrl,
    required this.total,
    required this.externalId,
    this.expiresAt,
  });

  final String reference;
  final String paymentUrl;
  final String? qrImageUrl;
  final int total;
  final String externalId;
  final DateTime? expiresAt;
}

/// Service komunikasi langsung ke MiomiPay Payment Gateway Sandbox API.
/// Ini memungkinkan pembayaran QRIS berfungsi secara mandiri (standalone)
/// bahkan ketika server lokal Express tidak sedang dijalankan.
class MiomiPayService {
  MiomiPayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'https://pg.miomidev.com/api/v1';
  static const String defaultApiKey = 'MP-SB-xMmSCXcLzI7qMJQeJIEAFOUxoVqqvwMp';
  static const String simulatorUrl = 'https://pg.miomidev.com/sandbox/simulator';
  static const Duration _timeout = Duration(seconds: 12);

  /// Buat tagihan QRIS langsung ke API MiomiPay
  Future<MiomiInvoiceResult> createInvoice({
    required List<CartItemModel> items,
    required AppUser cashier,
    String? apiKey,
  }) async {
    final subtotal = items.fold<int>(
      0,
      (acc, item) => acc + (item.unitPrice * item.quantity),
    );

    final externalId = 'POS-${DateTime.now().millisecondsSinceEpoch}';
    final key = (apiKey?.isNotEmpty ?? false) ? apiKey! : defaultApiKey;

    final response = await _client
        .post(
          Uri.parse('$baseUrl/payment/create'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'external_id': externalId,
            'amount': subtotal,
            'customer_name': cashier.name.isNotEmpty ? cashier.name : 'Kasir Toko',
            'customer_email': cashier.email.isNotEmpty ? cashier.email : 'kasir@pos.test',
            'description': 'Pembayaran POS - Kasir Toko',
          }),
        )
        .timeout(_timeout);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = payload['message'] ?? payload['error'] ?? 'Gagal membuat tagihan';
      throw Exception('MiomiPay menolak tagihan ($msg)');
    }

    final data = (payload['data'] as Map<String, dynamic>?) ?? payload;
    final reference = (data['reference'] ?? data['id'] ?? externalId).toString();
    final paymentUrl = (data['checkout_url'] ?? data['payment_url'] ?? '').toString();
    final qrImageUrl = data['qr_image_url'] as String?;
    final expiresAtStr = data['expires_at'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

    return MiomiInvoiceResult(
      reference: reference,
      paymentUrl: paymentUrl,
      qrImageUrl: qrImageUrl,
      total: subtotal,
      externalId: externalId,
      expiresAt: expiresAt,
    );
  }

  /// Cek status pembayaran tagihan ke MiomiPay
  Future<String?> checkStatus(String reference, {String? apiKey}) async {
    try {
      final key = (apiKey?.isNotEmpty ?? false) ? apiKey! : defaultApiKey;
      final response = await _client
          .get(
            Uri.parse('$baseUrl/payment/${Uri.encodeComponent(reference)}/status'),
            headers: {
              'Authorization': 'Bearer $key',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>?;
      final status = (data?['status'] ?? payload['status'] ?? '').toString().toUpperCase();
      return status;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
