import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import 'transaction_detail_screen.dart';

/// Riwayat transaksi. Admin melihat semua, kasir hanya miliknya.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const Scaffold(body: LoadingView());
    }
    final service = TransactionService();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.streamTransactions(seeAll: user.isAdmin, uid: user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Memuat riwayat...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Gagal memuat riwayat',
              message: '${snapshot.error}',
            );
          }
          final transactions = snapshot.data ?? const <TransactionModel>[];
          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Belum ada transaksi',
              message: 'Transaksi yang selesai akan muncul di sini.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _TransactionCard(transaction: transactions[index]),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transactionId: transaction.id,
            ),
          ),
        ),
        title: Text(
          transaction.transactionNumber,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          transaction.createdAt == null
              ? ''
              : formatDateTime(transaction.createdAt!),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatRupiah(transaction.total),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            _StatusChip(status: transaction.paymentStatus),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'paid' => ('Lunas', scheme.primary),
      'pending' => ('Menunggu', const Color(0xFFE0A526)),
      'failed' => ('Gagal', scheme.error),
      'expired' => ('Kedaluwarsa', scheme.error),
      _ => (status, scheme.onSurface.withValues(alpha: 0.55)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
