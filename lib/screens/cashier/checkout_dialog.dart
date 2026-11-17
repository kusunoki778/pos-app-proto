import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';
import 'qris_payment_screen.dart';

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

enum _Method { tunai, qris }

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
      if (_method == _Method.qris) {
        await _confirmQris(cart);
      } else {
        await _confirmCash(user, cart);
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  /// Tunai: harga diverifikasi Firestore saat transaction, langsung `paid`.
  Future<void> _confirmCash(dynamic user, dynamic cart) async {
    final transaction = await TransactionService().checkoutCash(
      cashier: user,
      cartItems: cart.items,
      paid: _paid,
    );
    if (!mounted) return;
    // Notifikasi best-effort: gagal jaringan tidak membatalkan transaksi.
    ApiService().notifyTransaction(transaction.id).catchError((_) => false);
    // Tampilkan struk, lalu beri tahu pemanggil untuk mengosongkan keranjang.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceiptView(transaction: transaction),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  /// QRIS: menghubungi server atau langsung MiomiPay sandbox API
  Future<void> _confirmQris(dynamic cart) async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      setState(() => _processing = false);
      return;
    }
    final idToken = await AuthService().getIdToken();
    final result = await ApiService().checkoutQris(
      cartItems: cart.items,
      idToken: idToken,
      cashier: user,
    );
    if (!mounted) return;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrisPaymentScreen(
          transactionId: result.transactionId,
          total: result.total,
          idToken: idToken,
          invoiceNumber: result.reference,
          qrImageUrl: result.qrImageUrl,
          paymentUrl: result.paymentUrl,
          expiresAt: result.expiresAt,
        ),
      ),
    );
    if (paid != true) {
      if (mounted) {
        setState(() => _processing = false);
      }
      return;
    }
    // Transaksi lunas; ambil transaksi terbaru untuk struk
    final transaction =
        await TransactionService().getTransactionById(result.transactionId);
    if (transaction == null) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceiptView(transaction: transaction),
    );
    if (mounted) Navigator.of(context).pop(true);
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
          padding: const EdgeInsets.all(20),
          children: [
            // Card Total
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_rounded, color: scheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${cart.itemCount} jenis, ${cart.totalUnits} item',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(cart.subtotal),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pilihan Metode Pembayaran
            Text(
              'Pilih Metode Pembayaran',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _method = _Method.tunai),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _method == _Method.tunai
                            ? scheme.primary.withValues(alpha: 0.08)
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _method == _Method.tunai ? scheme.primary : scheme.outline,
                          width: _method == _Method.tunai ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_rounded,
                            color: _method == _Method.tunai ? scheme.primary : scheme.onSurface,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Uang Tunai',
                            style: TextStyle(
                              fontWeight: _method == _Method.tunai ? FontWeight.w800 : FontWeight.w600,
                              color: _method == _Method.tunai ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _method = _Method.qris),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _method == _Method.qris
                            ? scheme.primary.withValues(alpha: 0.08)
                            : scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _method == _Method.qris ? scheme.primary : scheme.outline,
                          width: _method == _Method.qris ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: _method == _Method.qris ? scheme.primary : scheme.onSurface,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'QRIS MiomiPay',
                            style: TextStyle(
                              fontWeight: _method == _Method.qris ? FontWeight.w800 : FontWeight.w600,
                              color: _method == _Method.qris ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_method == _Method.qris) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tagihan QRIS otomatis dibuat melalui Payment Gateway MiomiPay Sandbox. Kode QR akan ditampilkan di layar berikutnya.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF166534),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_method == _Method.tunai) ...[
              const SizedBox(height: 20),
              Text(
                'Nominal Uang Diterima',
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _paidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  errorText: _paidController.text.isEmpty
                      ? null
                      : (!_paidValid ? 'Nominal kurang dari total tagihan' : null),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Uang Pas'),
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
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Uang Kembalian',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(_change),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            if (_processing)
              const LoadingView(label: 'Memproses transaksi...')
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _paidValid ? _confirm : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: _method == _Method.qris ? scheme.primary : const Color(0xFF10B981),
                  ),
                  icon: Icon(_method == _Method.qris ? Icons.qr_code_2_rounded : Icons.check_circle_rounded),
                  label: Text(
                    _method == _Method.qris
                        ? 'Lanjut Buat QRIS (${formatRupiah(_total)})'
                        : 'Selesaikan Pembayaran Tunai',
                  ),
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'Pembayaran Berhasil!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            transaction.transactionNumber,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 20),
            for (final item in transaction.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
            _row(context, 'Metode', transaction.paymentMethod.toUpperCase()),
            _row(context, 'Total', formatRupiah(transaction.total), isBold: true),
            if (transaction.paid != null)
              _row(context, 'Dibayar', formatRupiah(transaction.paid!)),
            if (transaction.change != null && transaction.change! > 0)
              _row(context, 'Kembalian', formatRupiah(transaction.change!)),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Selesai & Transaksi Baru'),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
