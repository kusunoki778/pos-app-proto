import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/history/transaction_detail_screen.dart';
import 'screens/shell/main_shell.dart';
import 'services/notification_service.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Root aplikasi. Tema terang default toko; tema gelap ikut tersedia.
class KasirTokoApp extends StatelessWidget {
  const KasirTokoApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        // Keranjang di level aplikasi: route yang di-push (mis. CheckoutDialog)
        // dan semua tab tetap bisa membacanya. Sekali dibuat, hidup selama app.
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: MaterialApp(
        title: 'Kasir Toko',
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationService.navigatorKey,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        onGenerateRoute: (settings) {
          // Notifikasi ditap membuka detail transaksi tanpa context.
          final uri = Uri.tryParse(settings.name ?? '');
          if (uri != null && uri.pathSegments.length == 2 &&
              uri.pathSegments[0] == 'transaction') {
            return MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                transactionId: uri.pathSegments[1],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

/// Penentu layar awal berdasarkan status login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.phase) {
      case AuthPhase.loading:
        return const Scaffold(
          body: LoadingView(label: 'Memeriksa sesi...'),
        );
      case AuthPhase.unauthenticated:
        return const LoginScreen();
      case AuthPhase.authenticated:
        return const _NotificationBootstrap();
    }
  }
}

/// Mengaktifkan FCM sekali setelah user login.
class _NotificationBootstrap extends StatefulWidget {
  const _NotificationBootstrap();

  @override
  State<_NotificationBootstrap> createState() => _NotificationBootstrapState();
}

class _NotificationBootstrapState extends State<_NotificationBootstrap> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    final user = context.read<AuthController>().user;
    if (user != null) {
      _notificationService.init(user: user);
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
