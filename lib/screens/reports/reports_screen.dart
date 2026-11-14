import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Placeholder fase 1. Ringkasan penjualan masuk di Fase 5.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: const EmptyState(
        icon: Icons.bar_chart,
        title: 'Laporan sedang dikerjakan',
        message: 'Ringkasan penjualan harian masuk pada Fase 5.',
      ),
    );
  }
}
