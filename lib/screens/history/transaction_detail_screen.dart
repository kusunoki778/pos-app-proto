import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';

/// Detail satu transaksi penjualan dengan tampilan bergaya e-struk modern.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final service = TransactionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: FutureBuilder(
        future: service.getTransactionById(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Memuat data transaksi...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat transaksi',
              message: '${snapshot.error}',
            );
          }
          final transaction = snapshot.data;
          if (transaction == null) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Transaksi tidak ditemukan',
              message: 'Data transaksi tidak tersedia atau milik kasir lain.',
            );
          }

          final isPaid = transaction.paymentStatus == 'paid';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: scheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'LUNAS' : transaction.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          Text(
                            transaction.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        transaction.transactionNumber,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.createdAt == null
                            ? ''
                            : formatDateTime(transaction.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            formatRupiah(transaction.total),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Daftar Item Pesanan
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: scheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian Produk (${transaction.items.length} jenis)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Divider(height: 20),
                      for (final item in transaction.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${formatRupiah(item.unitPrice)} x ${item.quantity}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRupiah(item.lineTotal),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 20),
                      _row(context, 'Subtotal', formatRupiah(transaction.subtotal)),
                      if (transaction.discount > 0)
                        _row(context, 'Diskon', '-${formatRupiah(transaction.discount)}'),
                      _row(context, 'Total Akhir', formatRupiah(transaction.total), isBold: true),
                      if (transaction.paid != null)
                        _row(context, 'Uang Diterima', formatRupiah(transaction.paid!)),
                      if (transaction.change != null && transaction.change! > 0)
                        _row(context, 'Kembalian', formatRupiah(transaction.change!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Kasir
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: scheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Diproses oleh Kasir: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        transaction.cashierId.isEmpty ? 'Kasir' : transaction.cashierId,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isBold = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? scheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
