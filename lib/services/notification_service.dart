import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

/// Handler background wajib top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Inisialisasi FCM: izin, token, topik admin, dan notifikasi lokal
/// untuk pesan yang datang saat aplikasi di foreground.
class NotificationService {
  NotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  static const _channelId = 'pos_alerts';
  static const _channelName = 'Notifikasi Kasir Toko';

  /// Key global untuk navigasi saat notifikasi ditap.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Potongan token FCM untuk ditampilkan di layar Pengaturan.
  static Future<String?> deviceTokenPreview() async {
    // register() v17 memberi Installation ID, bukan token klasik yang
    // dibutuhkan server untuk pengiriman per-perangkat (send(token:)).
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.length < 12) return token;
    return '${token.substring(0, 12)}…';
  }

  Future<void> init({required AppUser user}) async {
    // Izin notifikasi (Android 13+ menampilkan dialog sistem).
    await _messaging.requestPermission();

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

    // Token perangkat: disimpan agar backend bisa mengirim ke perangkat
    // ini, dan admin menerima broadcast via topic admin-alerts.
    await _saveToken(user);
    // register() v17 tidak memancarkan token klasik; aliran lama tetap
    // satu-satunya cara mendeteksi rotasi token.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveToken(user));

    if (user.isAdmin) {
      await _messaging.subscribeToTopic('admin-alerts');
    } else {
      await _messaging.unsubscribeFromTopic('admin-alerts');
    }

    // Foreground: sistem tidak menampilkan notifikasi otomatis,
    // jadi tampilkan lewat notifikasi lokal.
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      _showLocal(message);
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
  }

  Future<void> _saveToken(AppUser user) async {
    // ignore: deprecated_member_use
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('deviceTokens').doc(token).set({
      'uid': user.uid,
      'role': user.role,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
