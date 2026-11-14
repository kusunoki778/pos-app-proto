import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';

/// Detail satu transaksi, dibuka dari riwayat atau notifikasi.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = TransactionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: FutureBuilder(
        future: service.getTransactionById(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Memuat transaksi...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Gagal memuat',
              message: '${snapshot.error}',
            );
          }
          final transaction = snapshot.data;
          if (transaction == null) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Transaksi tidak ditemukan',
              message: 'Bisa jadi transaksi milik pengguna lain.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                transaction.transactionNumber,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                transaction.createdAt == null
                    ? ''
                    : formatDateTime(transaction.createdAt!),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      for (final item in transaction.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} '
                                  '(${formatRupiah(item.unitPrice)} '
                                  'x${item.quantity})',
                                ),
                              ),
                              Text(formatRupiah(item.lineTotal)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Row(label: 'Metode', value: transaction.paymentMethod),
              _Row(label: 'Status', value: transaction.paymentStatus),
              _Row(label: 'Total', value: formatRupiah(transaction.total)),
              if (transaction.paid != null)
                _Row(label: 'Dibayar', value: formatRupiah(transaction.paid!)),
              if (transaction.change != null)
                _Row(label: 'Kembalian', value: formatRupiah(transaction.change!)),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
