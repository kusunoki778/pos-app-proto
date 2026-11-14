import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Text(
                  'Keranjang',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton(
                    onPressed: cart.clear,
                    child: const Text('Kosongkan'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Keranjang kosong',
                    message: 'Pilih produk dari katalog untuk mulai transaksi.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemRow(item: item);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outline),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        formatRupiah(cart.subtotal),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      // Amber dipakai di satu momen penting: tombol bayar.
                      backgroundColor: const Color(0xFFE0A526),
                      foregroundColor: const Color(0xFF1C1B18),
                    ),
                    onPressed: cart.isEmpty ? null : onCheckout,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text('Bayar ${formatRupiah(cart.subtotal)}'),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${formatRupiah(item.unitPrice)} x ${item.quantity} = '
                '${formatRupiah(item.lineTotal)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Kurangi',
          onPressed: () => cart.decrement(item.productId),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${item.quantity}', style: theme.textTheme.titleMedium),
        IconButton(
          tooltip: 'Tambah',
          onPressed: () => cart.add(_productOf(item)),
          icon: const Icon(Icons.add_circle_outline),
        ),
        IconButton(
          tooltip: 'Hapus item',
          onPressed: () => cart.remove(item.productId),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  /// Keranjang menyimpan snapshot, tapi penambahan kuantitas tetap
  /// dibatasi stok produk terkini.
  ProductModel _productOf(CartItemModel item) {
    return ProductModel(
      id: item.productId,
      name: item.productName,
      categoryId: '',
      price: item.unitPrice,
      // Stok sengaja besar di sisi UI; batas sebenarnya diperiksa
      // saat checkout di Firestore transaction.
      stock: 9999,
    );
  }
}
