import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../state/auth_controller.dart';
import '../../widgets/animasi.dart';
import '../../widgets/common.dart';

/// Dashboard Admin: ringkasan penjualan, transaksi terkini, dan stok menipis.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Khusus Admin',
          message: 'Halaman laporan ini hanya dapat diakses oleh akun Admin.',
        ),
      );
    }
    final service = TransactionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Ringkasan Penjualan')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.streamTransactions(seeAll: true, uid: user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Menghitung statistik penjualan...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat laporan',
              message: '${snapshot.error}',
            );
          }
          final transactions = snapshot.data ?? const <TransactionModel>[];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TodaySummary(transactions: transactions),
              const SizedBox(height: 16),
              StaggerEnter(
                delay: const Duration(milliseconds: 260),
                child: _TransactionList(transactions: transactions.take(5).toList()),
              ),
              const SizedBox(height: 16),
              const StaggerEnter(
                delay: Duration(milliseconds: 340),
                child: _LowStockCard(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final today = transactions
        .where((t) =>
            t.paymentStatus == 'paid' &&
            t.createdAt != null &&
            !t.createdAt!.isBefore(startOfDay))
        .toList();

    final revenue = today.fold<int>(0, (sum, t) => sum + t.total);
    final units = today.fold<int>(
      0,
      (sum, t) => sum + t.items.fold<int>(0, (s, item) => s + item.quantity),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: StaggerEnter(
                delay: Duration.zero,
                child: _MetricCard(
                  icon: Icons.payments_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F46E5),
                  label: 'Omzet Hari Ini',
                  value: formatRupiah(revenue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggerEnter(
                delay: const Duration(milliseconds: 80),
                child: _MetricCard(
                  icon: Icons.receipt_long_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  label: 'Transaksi',
                  value: '${today.length}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggerEnter(
                delay: const Duration(milliseconds: 160),
                child: _MetricCard(
                  icon: Icons.inventory_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  label: 'Item Terjual',
                  value: '$units',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Transaksi Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada transaksi penjualan.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: transaction.paymentMethod == 'qris'
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      transaction.paymentMethod == 'qris'
                          ? Icons.qr_code_2_rounded
                          : Icons.money_rounded,
                      color: transaction.paymentMethod == 'qris'
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.transactionNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    transaction.createdAt == null ? '' : formatDateTime(transaction.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  trailing: Text(
                    formatRupiah(transaction.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final service = ProductService();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Text(
                  'Peringatan Stok Menipis (< 5)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<List<ProductModel>>(
            stream: service.streamProducts(activeOnly: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final lowStock = (snapshot.data ?? const <ProductModel>[])
                  .where((p) => p.stock < 5)
                  .toList()
                ..sort((a, b) => a.stock.compareTo(b.stock));

              if (lowStock.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Semua stok produk saat ini aman (di atas 5 unit).'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStock.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = lowStock[index];
                  final isZero = product.stock == 0;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isZero ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isZero ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                        color: isZero ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isZero ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isZero ? 'Habis (0)' : 'Sisa ${product.stock}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isZero ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
