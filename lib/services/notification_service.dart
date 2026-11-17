import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config.dart';
import '../firebase_options.dart';
import '../models/app_user.dart';

/// Handler background wajib top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Inisialisasi FCM: izin, token, topik admin, dan notifikasi foreground.
///
/// - Android: pesan foreground ditampilkan lewat notifikasi lokal.
/// - Web: pesan foreground ditampilkan oleh service worker
///   (`web/firebase-messaging-sw.js`); plugin notifikasi lokal tidak dipakai.
class NotificationService {
  NotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  static const _channelId = 'pos_alerts';
  static const _channelName = 'Notifikasi Kasir Toko';

  /// VAPID key untuk web push, dari `Config` (public key, bukan rahasia).
  /// Android tidak memakai ini.
  static String get webVapidKey => Config.webVapidKey;

  /// Key global untuk navigasi saat notifikasi ditap.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Potongan token FCM untuk ditampilkan di layar Pengaturan.
  static Future<String?> deviceTokenPreview() async {
    try {
      final token = await _token();
      if (token == null || token.length < 12) return token;
      return '${token.substring(0, 12)}…';
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _token() {
    // register() v17 memberi Installation ID, bukan token klasik yang
    // dibutuhkan server untuk pengiriman per-perangkat (send(token:)).
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb && webVapidKey.isNotEmpty ? webVapidKey : null,
    );
  }

  Future<void> init({required AppUser user}) async {
    try {
      await _messaging.requestPermission();

      if (!kIsWeb) {
        // Channel Android untuk notifikasi foreground.
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        );
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Token perangkat: disimpan agar backend bisa mengirim langsung.
      await _saveToken(user);
      // register() v17 tidak memancarkan token klasik; aliran lama tetap
      // satu-satunya cara mendeteksi rotasi token.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh
          .listen((_) => _saveToken(user));

      // Topik tidak didukung web; admin di web tetap menerima pesan
      // via token per-perangkat yang tersimpan di deviceTokens.
      if (!kIsWeb) {
        if (user.isAdmin) {
          await _messaging.subscribeToTopic('admin-alerts');
        } else {
          await _messaging.unsubscribeFromTopic('admin-alerts');
        }
      }

      // Foreground: di Android sistem tidak menampilkan notifikasi
      // otomatis, jadi tampilkan lewat notifikasi lokal.
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        if (!kIsWeb) _showLocal(message);
      });

      // Notifikasi ditap saat app background/terminated.
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _openTransaction(message.data);
      });

      // App dibuka dari terminasi (cold start) lewat notifikasi.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _openTransaction(initial.data);
      }
    } catch (e) {
      // Gagal izin/notifikasi tidak boleh menggagalkan login atau
      // penggunaan aplikasi — dicatat saja.
      debugPrint('Inisialisasi notifikasi dilewati: $e');
    }
  }

  Future<void> _saveToken(AppUser user) async {
    try {
      final token = await _token();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('deviceTokens').doc(token).set({
        'uid': user.uid,
        'role': user.role,
        'platform': kIsWeb ? 'web' : 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal menyimpan token FCM: $e');
    }
  }

  void _showLocal(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Kasir Toko';
    final body = notification?.body ?? message.data['body'] ?? '';
    _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi transaksi dan stok',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['transactionId'],
    );
  }

  void _openTransaction(Map<String, dynamic> data) {
    if (data['type'] != 'sale') return;
    final transactionId = data['transactionId'];
    if (transactionId is! String || transactionId.isEmpty) return;
    final state = navigatorKey.currentState;
    if (state == null) return;
    // Nama route sengaja string agar detail bisa dibuka tanpa context.
    state.pushNamed('/transaction/$transactionId');
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
  }
}
