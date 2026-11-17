import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';
import 'cart_panel.dart';
import 'checkout_dialog.dart';

/// Layar kasir: katalog + keranjang.
/// Layar lebar (tablet/desktop): katalog dan keranjang berdampingan.
/// Layar sempit (HP): floating cart bar di bawah + modal keranjang.
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir POS'),
        actions: const [_CartButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final catalog = const _CatalogArea();

          if (isWide) {
            return Row(
              children: [
                Expanded(child: catalog),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: scheme.outline),
                    ),
                  ),
                  child: CartPanel(
                    onCheckout: () => _startCheckout(context),
                  ),
                ),
              ],
            );
          }

          // Layar HP: katalog dengan Floating Bottom Bar
          return Stack(
            children: [
              catalog,
              if (cart.itemCount > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _FloatingCartBar(
                    cart: cart,
                    onTap: () => _openCartSheet(context, cart),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingCartBar extends StatelessWidget {
  const _FloatingCartBar({
    required this.cart,
    required this.onTap,
  });

  final CartController cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.itemCount} jenis (${cart.totalUnits} item)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatRupiah(cart.subtotal),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Lihat Keranjang',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: Text('${cart.itemCount}'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: () => _openCartSheet(context, cart),
    );
  }
}

void _openCartSheet(BuildContext context, CartController cart) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: cart,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CartPanel(onCheckout: () => _startCheckout(context)),
        ),
      ),
    ),
  );
}

void _startCheckout(BuildContext context) {
  final cart = context.read<CartController>();
  if (cart.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).push(CheckoutDialog.route()).then((result) {
    if (result == true) {
      cart.clear();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil diproses!'),
          backgroundColor: Color(0xFF10B981),
        ),
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ProductService _service = ProductService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // Search Bar di atas katalog
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari menu atau produk...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Filter Kategori Chips
        SizedBox(
          height: 48,
          child: StreamBuilder<List<CategoryModel>>(
            stream: _service.streamActiveCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              final chips = <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 6),
                  child: _CategoryChip(
                    label: 'Semua',
                    selected: _selectedCategoryId == null,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _CategoryChip(
                      label: category.name,
                      selected: _selectedCategoryId == category.id,
                      onTap: () => setState(() => _selectedCategoryId = category.id),
                    ),
                  ),
              ];
              return ListView(
                scrollDirection: Axis.horizontal,
                children: chips,
              );
            },
          ),
        ),

        // Grid Produk
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _service.streamProducts(activeOnly: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(label: 'Memuat menu...');
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Gagal memuat katalog',
                  message: '${snapshot.error}',
                );
              }
              var products = snapshot.data ?? const <ProductModel>[];

              // Filter kategori
              final categoryId = _selectedCategoryId;
              if (categoryId != null) {
                products = products.where((p) => p.categoryId == categoryId).toList();
              }

              // Filter pencarian
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (products.isEmpty) {
                return EmptyState(
                  icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.storefront_rounded,
                  title: _searchQuery.isNotEmpty ? 'Menu tidak ditemukan' : 'Katalog kosong',
                  message: _searchQuery.isNotEmpty
                      ? 'Coba gunakan kata kunci pencarian yang lain.'
                      : 'Belum ada produk aktif di kategori ini.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = (constraints.maxWidth / 190).floor().clamp(2, 6);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _ProductTile(product: products[index]),
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
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surface,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : scheme.onSurface,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outline,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductModel product;

  IconData _iconForCategory(String? categoryId) {
    // Memberi variasi ikon berdasarkan kategori
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cart = context.watch<CartController>();
    final inCart = cart.contains(product.id);
    final qty = cart.quantityOf(product.id);
    final isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCart ? scheme.primary : scheme.outline,
          width: inCart ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar / Icon Avatar
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: inCart ? scheme.primary.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _iconForCategory(product.categoryId),
                  size: 32,
                  color: inCart ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Nama Produk
            Text(
              product.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Harga
            Text(
              formatRupiah(product.price),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
                fontSize: 14,
              ),
            ),
            const Spacer(),

            // Info Stok
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOutOfStock
                        ? scheme.error
                        : (product.stock <= 5 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOutOfStock ? 'Habis' : 'Stok: ${product.stock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isOutOfStock ? scheme.error : scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Stepper Quantity in-card or Add Button
            if (isOutOfStock)
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Habis', style: TextStyle(fontSize: 12)),
                ),
              )
            else if (inCart)
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      color: scheme.primary,
                      padding: EdgeInsets.zero,
                      onPressed: () => context.read<CartController>().decrement(product.id),
                    ),
                    Text(
                      '$qty',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      color: scheme.primary,
                      padding: EdgeInsets.zero,
                      onPressed: () => context.read<CartController>().add(product),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton.tonal(
                  onPressed: () => context.read<CartController>().add(product),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: scheme.primary.withValues(alpha: 0.08),
                    foregroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 16),
                      SizedBox(width: 4),
                      Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
