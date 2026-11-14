import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';
import 'cart_panel.dart';
import 'checkout_dialog.dart';

/// Layar kasir: katalog + keranjang.
/// Layar lebar (tablet/desktop): katalog dan keranjang berdampingan.
/// Layar sempit (HP): keranjang lewat tombol di app bar.
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: const [_CartButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final catalog = const _CatalogArea();
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: catalog),
                SizedBox(
                  width: 360,
                  child: CartPanel(
                    onCheckout: () => _startCheckout(context),
                  ),
                ),
              ],
            );
          }
          return catalog;
        },
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    return IconButton(
      tooltip: 'Keranjang',
      icon: Badge(
        isLabelVisible: cart.itemCount > 0,
        label: Text('${cart.itemCount}'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => ChangeNotifierProvider.value(
            value: cart,
            child: FractionallySizedBox(
              heightFactor: 0.85,
              child: CartPanel(onCheckout: () => _startCheckout(context)),
            ),
          ),
        );
      },
    );
  }
}

void _startCheckout(BuildContext context) {
  final cart = context.read<CartController>();
  if (cart.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context)
      .push(CheckoutDialog.route())
      .then((result) {
    if (result == true) {
      cart.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan')),
      );
    }
  });
}

class _CatalogArea extends StatelessWidget {
  const _CatalogArea();

  @override
  Widget build(BuildContext context) {
    return const _CatalogBody();
  }
}

class _CatalogBody extends StatefulWidget {
  const _CatalogBody();

  @override
  State<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends State<_CatalogBody> {
  String? _selectedCategoryId;
  final ProductService _service = ProductService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: StreamBuilder(
            stream: _service.streamActiveCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              final chips = <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _CategoryChip(
                    label: 'Semua',
                    selected: _selectedCategoryId == null,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category.name,
                    selected: _selectedCategoryId == category.id,
                    onTap: () =>
                        setState(() => _selectedCategoryId = category.id),
                  ),
              ];
              return ListView(
                scrollDirection: Axis.horizontal,
                children: chips,
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _service.streamProducts(activeOnly: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(label: 'Memuat katalog...');
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Gagal memuat katalog',
                  message: '${snapshot.error}',
                );
              }
              var products = snapshot.data ?? const <ProductModel>[];
              final categoryId = _selectedCategoryId;
              if (categoryId != null) {
                products =
                    products.where((p) => p.categoryId == categoryId).toList();
              }
              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.storefront,
                  title: 'Katalog kosong',
                  message: 'Belum ada produk aktif untuk kategori ini.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      (constraints.maxWidth / 180).floor().clamp(2, 5);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        _ProductTile(product: products[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primary.withValues(alpha: 0.15),
        checkmarkColor: scheme.primary,
        labelStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartController>();
    final inCart = cart.contains(product.id);
    final qty = cart.quantityOf(product.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(product.price),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    product.stock > 0 ? 'Stok ${product.stock}' : 'Stok habis',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: product.stock > 0
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: product.stock > 0
                  ? FilledButton.tonalIcon(
                      onPressed: () =>
                          context.read<CartController>().add(product),
                      icon: inCart
                          ? const Icon(Icons.check)
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(inCart ? 'Di keranjang ($qty)' : 'Tambah'),
                    )
                  : OutlinedButton(
                      onPressed: null,
                      child: const Text('Habis'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
