import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Klien server Express (pengirim FCM). Semua panggilan best-effort:
/// kegagalan jaringan tidak boleh menggagalkan transaksi kasir.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);

  Future<bool> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (Config.apiKey.isNotEmpty) 'X-API-Key': Config.apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Minta server kirim notifikasi transaksi baru ke topic admin-alerts.
  Future<bool> notifyTransaction(String transactionId) {
    return _post(Uri.parse(Config.notifyUrl), {'transactionId': transactionId});
  }

  /// Tombol "Tes Notifikasi" di Pengaturan.
  Future<bool> notifyTest() {
    return _post(Uri.parse(Config.notifyTestUrl), {'title': 'Tes notifikasi'});
  }

  void dispose() => _client.close();
}
