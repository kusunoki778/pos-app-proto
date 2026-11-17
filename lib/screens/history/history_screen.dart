import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import 'transaction_detail_screen.dart';

/// Riwayat transaksi penjualan: Admin melihat semua, Kasir hanya miliknya.
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
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.streamTransactions(seeAll: user.isAdmin, uid: user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Memuat riwayat transaksi...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat riwayat',
              message: '${snapshot.error}',
            );
          }
          final transactions = snapshot.data ?? const <TransactionModel>[];
          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum Ada Transaksi',
              message: 'Transaksi penjualan yang telah diproses akan tercatat di sini.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final scheme = theme.colorScheme;
    final isQris = transaction.paymentMethod == 'qris';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transactionId: transaction.id,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isQris ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isQris ? Icons.qr_code_2_rounded : Icons.money_rounded,
                  color: isQris ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.createdAt == null
                          ? ''
                          : formatDateTime(transaction.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(transaction.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: transaction.paymentStatus),
                ],
              ),
            ],
          ),
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
    final (label, color, bg) = switch (status) {
      'paid' => ('Lunas', const Color(0xFF059669), const Color(0xFFECFDF5)),
      'pending' => ('Menunggu', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      'failed' => ('Gagal', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
      'expired' => ('Kedaluwarsa', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
      _ => (status, const Color(0xFF64748B), const Color(0xFFF1F5F9)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
