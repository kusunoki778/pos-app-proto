import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode tampilan (terang/gelap/ikut sistem) yang dipilih di Pengaturan.
/// Pilihan disimpan ke SharedPreferences supaya bertahan setelah app
/// dibuka lagi.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      final parsed = ThemeMode.values.cast<ThemeMode?>().firstWhere(
            (m) => m?.name == saved,
            orElse: () => null,
          );
      if (parsed != null && parsed != _mode) {
        _mode = parsed;
        notifyListeners();
      }
    } catch (_) {
      // Gagal membaca prefs tidak menghalangi app jalan (mode sistem).
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Persistensi gagal pun tidak fatal — mode tetap aktif di sesi ini.
    }
  }
}
