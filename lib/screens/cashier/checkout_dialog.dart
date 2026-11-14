import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../services/transaction_service.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';

/// Halaman pembayaran: pilih metode, hitung kembalian, konfirmasi.
/// Hasil: true bila transaksi sukses (keranjang dikosongkan oleh pemanggil).
class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(builder: (_) => const CheckoutDialog());
  }

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

enum _Method { tunai, qris, debit }

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _paidController = TextEditingController();
  _Method _method = _Method.tunai;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  int get _total => context.read<CartController>().subtotal;
  int get _paid {
    if (_method != _Method.tunai) return _total;
    return int.tryParse(_paidController.text.trim()) ?? 0;
  }

  int get _change {
    final value = _paid - _total;
    return value > 0 ? value : 0;
  }

  bool get _paidValid {
    if (_method != _Method.tunai) return true;
    return _paid >= _total;
  }

  Future<void> _confirm() async {
    if (!_paidValid) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    final cart = context.read<CartController>();
    final user = context.read<AuthController>().user;
    if (user == null || cart.isEmpty) {
      setState(() => _processing = false);
      return;
    }

    try {
      final transaction = await TransactionService().checkoutCash(
        cashier: user,
        cartItems: cart.items,
        paid: _paid,
      );
      if (!mounted) return;
      // Notifikasi best-effort: gagal jaringan tidak membatalkan transaksi.
      ApiService().notifyTransaction(transaction.id);
      // Tampilkan struk, lalu beri tahu pemanggil untuk mengosongkan keranjang.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReceiptView(transaction: transaction),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _processing = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  void _fillPaid(int amount) {
    setState(() => _paidController.text = '$amount');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cart.itemCount} jenis, ${cart.totalUnits} item',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatRupiah(cart.subtotal),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Metode pembayaran', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<_Method>(
              segments: const [
                ButtonSegment(value: _Method.tunai, label: Text('Tunai')),
                ButtonSegment(value: _Method.qris, label: Text('QRIS')),
                ButtonSegment(value: _Method.debit, label: Text('Debit')),
              ],
              selected: {_method},
              onSelectionChanged: (selection) =>
                  setState(() => _method = selection.first),
            ),
            if (_method != _Method.tunai) ...[
              const SizedBox(height: 12),
              Text(
                'Pencatatan ${_method.name}: nilai otomatis dianggap lunak '
                'sebesar total. Integrasi pembayaran digital menyusul di Tahap 7.',
                style: theme.textTheme.bodySmall!
                    .copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
              ),
            ],
            if (_method == _Method.tunai) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Uang diterima (Rp)',
                  errorText: _paidController.text.isEmpty
                      ? null
                      : (!_paidValid ? 'Kurang dari total' : null),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Uang pas'),
                    onPressed: () => _fillPaid(_total),
                  ),
                  ActionChip(
                    label: const Text('20.000'),
                    onPressed: () => _fillPaid(20000),
                  ),
                  ActionChip(
                    label: const Text('50.000'),
                    onPressed: () => _fillPaid(50000),
                  ),
                  ActionChip(
                    label: const Text('100.000'),
                    onPressed: () => _fillPaid(100000),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Text('Kembalian', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        formatRupiah(_change),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            if (_processing)
              const LoadingView(label: 'Menyimpan transaksi...')
            else
              FilledButton.icon(
                onPressed: _paidValid ? _confirm : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Selesaikan Pembayaran'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Struk ringkas setelah pembayaran sukses.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: scheme.primary),
          const SizedBox(width: 8),
          const Text('Struk'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(transaction.transactionNumber,
                style: theme.textTheme.titleMedium),
            Text(
              transaction.createdAt == null
                  ? ''
                  : formatDateTime(transaction.createdAt!),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final item in transaction.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(formatRupiah(item.lineTotal)),
                  ],
                ),
              ),
            const Divider(height: 20),
            _row(context, 'Total', formatRupiah(transaction.total)),
            if (transaction.paid != null)
              _row(context, 'Dibayar', formatRupiah(transaction.paid!)),
            if (transaction.change != null)
              _row(context, 'Kembalian', formatRupiah(transaction.change!)),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
