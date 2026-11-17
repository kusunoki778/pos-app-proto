import 'package:flutter/foundation.dart';

/// Konfigurasi endpoint server Express & Payment Gateway.
class Config {
  Config._();

  static const String _defaultHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );
  static const int defaultPort = int.fromEnvironment('API_PORT', defaultValue: 3000);
  static const String apiKey = String.fromEnvironment('API_KEY');

  static String? _customHost;
  static int? _customPort;

  static void setServer({required String host, int? port}) {
    _customHost = host.trim();
    if (port != null) _customPort = port;
  }

  static String get host {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    // Auto-detect untuk Android Emulator: localhost PC dapat diakses via 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && _defaultHost == 'localhost') {
      return '10.0.2.2';
    }
    return _defaultHost;
  }

  static int get port => _customPort ?? defaultPort;

  /// VAPID key web push (Firebase Console → Web Push certificate).
  static const String webVapidKey = String.fromEnvironment(
    'WEB_VAPID_KEY',
    defaultValue:
        'BMIMgweHu4ILIJRitCJ1-RLOF7LlYepKfids6qSENEkWmBCs7ubxq54jUd1JjVahJKve3lHAE-sFAr0G1WS-iK0',
  );

  static String get baseUrl => 'http://$host:$port';
  static String get healthUrl => '$baseUrl/api/health';
  static String get notifyUrl => '$baseUrl/api/notify';
  static String get notifyTestUrl => '$baseUrl/api/notify-test';
}
