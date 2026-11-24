import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/product_image.dart';

/// Panel keranjang: dipakai sebagai panel samping (layar lebar)
/// atau bottom sheet (HP).
class CartPanel extends StatelessWidget {
  const CartPanel({super.key, required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Keranjang
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_bag_outlined, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keranjang Pesanan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${cart.itemCount} jenis produk',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton.icon(
                    onPressed: cart.clear,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Kosongkan', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Items
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Keranjang Masih Kosong',
                    message: 'Pilih produk dari katalog untuk memulai transaksi penjualan.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemRow(item: item);
                    },
                  ),
          ),

          // Footer Checkout
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outline),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tagihan',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: cart.isEmpty ? null : onCheckout,
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: Text(
                      'Lanjut ke Pembayaran (${formatRupiah(cart.subtotal)})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            ProductImage(
              imageUrl: item.imageUrl,
              width: 44,
              height: 44,
              borderRadius: 8,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatRupiah(item.unitPrice)} x ${item.quantity}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(item.lineTotal),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Stepper Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Kurangi',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () => cart.decrement(item.productId),
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () => cart.add(_productOf(item)),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Hapus item',
            iconSize: 20,
            color: scheme.error.withValues(alpha: 0.7),
            onPressed: () => cart.remove(item.productId),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  ProductModel _productOf(CartItemModel item) {
    return ProductModel(
      id: item.productId,
      name: item.productName,
      categoryId: '',
      price: item.unitPrice,
      stock: 9999,
    );
  }
}
