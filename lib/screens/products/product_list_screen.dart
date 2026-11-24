import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/formatters.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'product_form_screen.dart';
import '../../widgets/common.dart';
import '../../widgets/product_image.dart';

/// Daftar produk untuk admin: realtime CRUD Firestore, filter kategori, pencarian.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _service = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String? _categoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([ProductModel? product]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          productService: _service,
          product: product,
        ),
      ),
    );
  }

  Future<void> _toggleActive(ProductModel product) async {
    final active = !product.isActive;
    try {
      await _service.setProductActive(product, active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Produk diaktifkan di katalog' : 'Produk dinonaktifkan'),
          backgroundColor: active ? const Color(0xFF10B981) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah produk: ${e.message ?? e.code}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Hapus Produk?'),
          ],
        ),
        content: Text(
          'Produk "${product.name}" akan dihapus permanen dari Firebase Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _service.deleteProduct(product);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } on FirebaseException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${e.message ?? e.code}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk & Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Produk', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Bersihkan pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
              onChanged: (value) => setState(() => _search = value.trim()),
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 48,
            child: StreamBuilder<List<CategoryModel>>(
              stream: _service.streamActiveCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <CategoryModel>[];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('Semua'),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surface,
                        labelStyle: TextStyle(
                          color: _categoryId == null ? Colors.white : scheme.onSurface,
                          fontWeight: _categoryId == null ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: _categoryId == null ? scheme.primary : scheme.outline,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                      ),
                    ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: _categoryId == category.id,
                          onSelected: (_) => setState(() {
                            _categoryId = _categoryId == category.id ? null : category.id;
                          }),
                          selectedColor: scheme.primary,
                          backgroundColor: scheme.surface,
                          labelStyle: TextStyle(
                            color: _categoryId == category.id ? Colors.white : scheme.onSurface,
                            fontWeight: _categoryId == category.id ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: _categoryId == category.id ? scheme.primary : scheme.outline,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Product List
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _service.streamProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(label: 'Memuat daftar produk...');
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Gagal memuat produk',
                    message: '${snapshot.error}',
                  );
                }
                final products = snapshot.data ?? const <ProductModel>[];
                var filtered = _categoryId == null
                    ? products
                    : products.where((p) => p.categoryId == _categoryId).toList();

                if (_search.isNotEmpty) {
                  final query = _search.toLowerCase();
                  filtered = filtered
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: _search.isEmpty && _categoryId == null
                        ? Icons.inventory_2_outlined
                        : Icons.search_off_rounded,
                    title: _search.isEmpty && _categoryId == null
                        ? 'Belum ada produk'
                        : 'Produk tidak ditemukan',
                    message: _search.isEmpty && _categoryId == null
                        ? 'Tekan tombol "Tambah Produk" untuk menambahkan menu baru.'
                        : 'Coba gunakan kata kunci pencarian yang lain.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _ProductCard(
                        product: product,
                        onTap: () => _openForm(product),
                        onToggleActive: () => _toggleActive(product),
                        onDelete: () => _confirmDelete(product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: product.isActive ? scheme.outline : scheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto / Thumbnail Produk
              ProductImage(
                imageUrl: product.imageUrl,
                categoryId: product.categoryId,
                width: 52,
                height: 52,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),

              // Detail Produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: product.isActive ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Nonaktif',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(product.price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: product.isActive ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOutOfStock
                                ? const Color(0xFFEF4444)
                                : (product.stock <= 5 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOutOfStock ? 'Stok Habis' : 'Stok: ${product.stock}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock
                                ? const Color(0xFFEF4444)
                                : scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu Aksi
              PopupMenuButton<String>(
                tooltip: 'Aksi produk',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') onTap();
                  if (value == 'toggle') onToggleActive();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Ubah Produk'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(product.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 10),
                        Text('Hapus', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
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
