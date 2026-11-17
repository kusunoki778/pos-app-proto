import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../services/api_service.dart';

/// Halaman pembayaran QRIS bergaya hosted payment page (pola pelatihan-pg):
/// header invoice + status badge, countdown, QR, polling status,
/// tombol buka pembayaran/simulator, dan struk saat lunas.
class QrisPaymentScreen extends StatefulWidget {
  const QrisPaymentScreen({
    super.key,
    required this.transactionId,
    required this.total,
    required this.idToken,
    this.invoiceNumber,
    this.qrImageUrl,
    this.paymentUrl,
    this.expiresAt,
  });

  final String transactionId;
  final int total;
  final String idToken;
  final String? invoiceNumber;
  final String? qrImageUrl;
  final String? paymentUrl;
  final DateTime? expiresAt;

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  final ApiService _api = ApiService();
  Timer? _poll;
  Timer? _countdown;
  PaymentStatus _status = PaymentStatus.pending;
  bool _checking = false;
  DateTime? _paidAt;

  static const _simulatorUrl = 'https://pg.miomidev.com/sandbox/simulator';

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      _expireIfDue();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _countdown?.cancel();
    _api.dispose();
    super.dispose();
  }

  int get _secondsLeft {
    final due = widget.expiresAt;
    if (due == null) return 15 * 60;
    final diff = due.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _expireIfDue() {
    if (_status != PaymentStatus.pending) return;
    if (widget.expiresAt != null &&
        DateTime.now().isAfter(widget.expiresAt!)) {
      _poll?.cancel();
      setState(() => _status = PaymentStatus.expired);
    }
  }

  Future<void> _check() async {
    if (_status != PaymentStatus.pending || _checking) return;
    _checking = true;
    final status = await _api.pollStatus(
      transactionId: widget.transactionId,
      idToken: widget.idToken,
      reference: widget.invoiceNumber,
    );
    _checking = false;
    if (!mounted) return;
    if (status == PaymentStatus.pending || status == _status) return;
    _poll?.cancel();
    setState(() {
      _status = status;
      if (status == PaymentStatus.paid) {
        _paidAt = DateTime.now();
      }
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tersalin: $text')),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('HTTPS') && !uri.isScheme('HTTP')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _finish(bool paid) async {
    _poll?.cancel();
    _countdown?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(paid);
  }

  String get _invoiceLabel =>
      (widget.invoiceNumber?.isNotEmpty ?? false)
          ? widget.invoiceNumber!
          : widget.transactionId;

  String get _statusLabel {
    return switch (_status) {
      PaymentStatus.pending => 'Menunggu pembayaran',
      PaymentStatus.paid => 'Lunas / Berhasil',
      PaymentStatus.failed => 'Gagal / Ditolak',
      PaymentStatus.expired => 'Kedaluwarsa',
    };
  }

  Color _statusColor(ColorScheme scheme) {
    return switch (_status) {
      PaymentStatus.pending => const Color(0xFFE0A526),
      PaymentStatus.paid => scheme.primary,
      PaymentStatus.failed || PaymentStatus.expired => scheme.error,
    };
  }

  String get _timerLabel {
    final s = _secondsLeft;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(scheme);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran QRIS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header invoice ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'NO. INVOICE',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _StatusBadge(label: _statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _invoiceLabel,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin nomor invoice',
                          onPressed: () => _copy(_invoiceLabel),
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total yang harus dibayar',
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              Text(
                                formatRupiah(widget.total),
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        if (_status == PaymentStatus.pending)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Selesaikan dalam',
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              Text(
                                _timerLabel,
                                style: theme.textTheme.titleLarge!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFE0A526),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Isi sesuai status ──
            switch (_status) {
              PaymentStatus.pending => _PendingBody(
                  qrImageUrl: widget.qrImageUrl,
                  paymentUrl: widget.paymentUrl,
                  theme: theme.textTheme,
                  scheme: scheme,
                  secondsLeft: _secondsLeft,
                  onOpenPaymentPage: widget.paymentUrl == null ||
                          widget.paymentUrl!.isEmpty
                      ? null
                      : () => _launch(widget.paymentUrl!),
                  onOpenSimulator: () => _launch(_simulatorUrl),
                  onCopyPaymentUrl: (url) => _copy(url),
                ),
              PaymentStatus.paid => _SuccessBody(
                  theme: theme.textTheme,
                  scheme: scheme,
                  invoice: _invoiceLabel,
                  paidAt: _paidAt ?? DateTime.now(),
                  total: widget.total,
                  onDone: () => _finish(true),
                ),
              PaymentStatus.failed => _ClosedBody(
                  theme: theme.textTheme,
                  scheme: scheme,
                  icon: Icons.cancel_outlined,
                  title: 'Pembayaran gagal',
                  message: 'Transaksi ditolak. Stok tidak terpotong — '
                      'silakan buat tagihan baru dari keranjang.',
                  onBack: () => _finish(false),
                ),
              PaymentStatus.expired => _ClosedBody(
                  theme: theme.textTheme,
                  scheme: scheme,
                  icon: Icons.hourglass_bottom,
                  title: 'Batas waktu habis',
                  message: 'Tagihan kedaluwarsa. Stok tidak terpotong — '
                      'silakan buat tagihan baru dari keranjang.',
                  onBack: () => _finish(false),
                ),
            },
          ],
        ),
      ),
    );
  }
}

/// Badge status di kanan atas kartu invoice.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
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

/// Status pending: QR + tombol buka pembayaran/simulator + polling.
class _PendingBody extends StatelessWidget {
  const _PendingBody({
    required this.qrImageUrl,
    this.paymentUrl,
    required this.theme,
    required this.scheme,
    required this.secondsLeft,
    required this.onOpenPaymentPage,
    required this.onOpenSimulator,
    required this.onCopyPaymentUrl,
  });

  final String? qrImageUrl;
  final String? paymentUrl;
  final TextTheme theme;
  final ColorScheme scheme;
  final int secondsLeft;
  final VoidCallback? onOpenPaymentPage;
  final VoidCallback onOpenSimulator;
  final ValueChanged<String> onCopyPaymentUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            child: qrImageUrl != null
                ? Image.network(
                    qrImageUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(Icons.qr_code_2, size: 96),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.qr_code_2, size: 96),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Menunggu pembayaran…',
              style: theme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Status diperiksa otomatis setiap 4 detik.',
          style: theme.bodySmall!
              .copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 20),
        if (onOpenPaymentPage != null) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenPaymentPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka Halaman Pembayaran'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (paymentUrl != null && paymentUrl!.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onCopyPaymentUrl(paymentUrl!),
              icon: const Icon(Icons.copy),
              label: const Text('Salin Link Tagihan'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenSimulator,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Buka Simulator Sandbox'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Untuk uji sandbox: buka simulator, tempel link pembayaran, '
          'lalu klik Bayar Sekarang.',
          textAlign: TextAlign.center,
          style: theme.bodySmall!
              .copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
        ),
      ],
    );
  }
}

/// Status lunas: kartu struk.
class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.theme,
    required this.scheme,
    required this.invoice,
    required this.paidAt,
    required this.total,
    required this.onDone,
  });

  final TextTheme theme;
  final ColorScheme scheme;
  final String invoice;
  final DateTime paidAt;
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.check_circle, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Pembayaran Berhasil!',
              style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                children: [
                  _row('No. Referensi', invoice, theme, scheme),
                  _row('Waktu bayar', formatDateTime(paidAt), theme, scheme),
                  _row('Metode', 'QRIS (MiomiPay)', theme, scheme),
                  const Divider(height: 16),
                  _row(
                    'Total terbayar',
                    formatRupiah(total),
                    theme,
                    scheme,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, TextTheme theme,
      ColorScheme scheme, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.bodyMedium!
                  .copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
          ),
          Text(
            value,
            style: theme.bodyMedium!.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status gagal/kedaluwarsa.
class _ClosedBody extends StatelessWidget {
  const _ClosedBody({
    required this.theme,
    required this.scheme,
    required this.icon,
    required this.title,
    required this.message,
    required this.onBack,
  });

  final TextTheme theme;
  final ColorScheme scheme;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.error.withValues(alpha: 0.12),
              child: Icon(icon, size: 40, color: scheme.error),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBack,
                child: const Text('Kembali ke Keranjang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
