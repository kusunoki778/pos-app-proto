/// Konfigurasi endpoint server Express (pengirim FCM).
/// Nilai bisa dioverride saat menjalankan aplikasi:
///   flutter run --dart-define=API_HOST=192.168.1.21 --dart-define=API_KEY=rahasia
class Config {
  Config._();

  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );
  static const int port = int.fromEnvironment('API_PORT', defaultValue: 3000);
  static const String apiKey = String.fromEnvironment('API_KEY');

  static String get baseUrl => 'http://$_host:$port';
  static String get healthUrl => '$baseUrl/api/health';
  static String get notifyUrl => '$baseUrl/api/notify';
  static String get notifyTestUrl => '$baseUrl/api/notify-test';
}
