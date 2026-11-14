import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../state/auth_controller.dart';

/// Halaman profil, status notifikasi, dan logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  bool _testing = false;

  String _roleLabel(String role) {
    if (role == 'admin') return 'Admin';
    if (role == 'cashier') return 'Kasir';
    return role;
  }

  Future<void> _testNotification() async {
    setState(() => _testing = true);
    final ok = await _api.notifyTest();
    if (!mounted) return;
    setState(() => _testing = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Perintah terkirim ke server. Notifikasi akan muncul untuk admin.'
            : 'Server tidak merespons. Pastikan server berjalan di ${Config.baseUrl}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '-',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(user?.email ?? '-',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _roleLabel(user?.role ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifikasi',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _testing ? null : _testNotification,
                        child: _testing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Tes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: NotificationService.deviceTokenPreview(),
                    builder: (context, snapshot) {
                      final token = snapshot.data;
                      return Text(
                        token == null
                            ? 'Token FCM belum tersedia.'
                            : 'Token FCM: $token...',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Server notifikasi: ${Config.baseUrl}\n'
                    'Admin menerima notifikasi tiap transaksi baru '
                    '(topik admin-alerts).',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
