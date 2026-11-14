import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handler notifikasi background (wajib sebelum runApp sesuai docs FCM).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final authController = AuthController(AuthService());
  await authController.init();

  runApp(KasirTokoApp(authController: authController));
}
