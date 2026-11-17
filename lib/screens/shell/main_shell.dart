import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../cashier/cashier_screen.dart';
import '../history/history_screen.dart';
import '../products/product_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.screen);
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
}

/// Kerangka navigasi utama aplikasi POS.
/// Role-based navigation:
/// - Admin: Kasir, Produk (CRUD Menu), Riwayat, Laporan, Pengaturan
/// - Kasir: Kasir, Riwayat, Pengaturan
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<_NavItem> _itemsFor(bool isAdmin) {
    final kasir = _NavItem(
      'Kasir',
      Icons.point_of_sale_outlined,
      Icons.point_of_sale_rounded,
      const CashierScreen(),
    );
    final riwayat = _NavItem(
      'Riwayat',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      const HistoryScreen(),
    );
    final pengaturan = _NavItem(
      'Pengaturan',
      Icons.settings_outlined,
      Icons.settings_rounded,
      const SettingsScreen(),
    );

    if (isAdmin) {
      return [
        kasir,
        _NavItem(
          'Produk',
          Icons.inventory_2_outlined,
          Icons.inventory_2_rounded,
          const ProductListScreen(),
        ),
        riwayat,
        _NavItem(
          'Laporan',
          Icons.bar_chart_outlined,
          Icons.bar_chart_rounded,
          const ReportsScreen(),
        ),
        pengaturan,
      ];
    }
    return [kasir, riwayat, pengaturan];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final items = _itemsFor(user?.isAdmin ?? false);

    // Jaga index tetap valid jika ada pergantian role sesi
    final index = _index.clamp(0, items.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: items.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
