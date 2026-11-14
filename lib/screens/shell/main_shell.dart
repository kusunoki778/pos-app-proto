import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../cashier/cashier_screen.dart';
import '../history/history_screen.dart';
import '../products/product_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}

/// Kerangka utama. Menu mengikuti role:
/// kasir hanya melihat kasir, riwayat, pengaturan.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<_NavItem> _itemsFor(bool isAdmin) {
    final kasir = _NavItem('Kasir', Icons.point_of_sale, const CashierScreen());
    final riwayat =
        _NavItem('Riwayat', Icons.receipt_long, const HistoryScreen());
    final pengaturan =
        _NavItem('Pengaturan', Icons.settings_outlined, const SettingsScreen());
    if (isAdmin) {
      return [
        kasir,
        _NavItem('Produk', Icons.inventory_2_outlined,
            const ProductListScreen()),
        riwayat,
        _NavItem('Laporan', Icons.bar_chart, const ReportsScreen()),
        pengaturan,
      ];
    }
    return [kasir, riwayat, pengaturan];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final items = _itemsFor(user?.isAdmin ?? false);

    // Jaga index tetap valid kalau role berubah.
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
              label: item.label,
            ),
        ],
      ),
    );
  }
}
