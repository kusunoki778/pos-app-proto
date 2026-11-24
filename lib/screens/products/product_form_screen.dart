import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/cdn_images.dart';
import '../../core/formatters.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';
import '../../widgets/product_image.dart';

/// Form tambah atau ubah produk dengan Live Preview interaktif & integrasi CDN Gambar.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.productService,
    this.product,
  });

  final ProductService productService;
  final ProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;

  bool get _isEdit => widget.product != null;
  String? _categoryId;
  bool _isActive = true;
  bool _saving = false;
  String? _savingError;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController =
        TextEditingController(text: product == null ? '' : '${product.price}');
    _stockController =
        TextEditingController(text: product == null ? '' : '${product.stock}');
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    _categoryId = product?.categoryId;
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _applyAutoSuggestion() {
    final suggestion = suggestCdnImage(_nameController.text, _categoryId);
    if (suggestion != null) {
      setState(() {
        _imageUrlController.text = suggestion.url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gambar "${suggestion.title}" terpilih otomatis dari CDN!'),
          backgroundColor: const Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada saran otomatis yang cocok. Silakan pilih dari katalog CDN.'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCdnPicker() async {
    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CdnImagePickerSheet(initialCategoryId: _categoryId),
    );

    if (selectedUrl != null && mounted) {
      setState(() {
        _imageUrlController.text = selectedUrl;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori produk terlebih dahulu'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _savingError = null;
    });
    final product = ProductModel(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      categoryId: _categoryId!,
      price: int.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      isActive: _isActive,
    );
    try {
      if (_isEdit) {
        await widget.productService.updateProduct(product);
      } else {
        await widget.productService.addProduct(product);
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      setState(() {
        _saving = false;
        _savingError = 'Gagal menyimpan: ${e.message ?? e.code}';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _savingError = 'Gagal menyimpan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final parsedPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    final parsedStock = int.tryParse(_stockController.text.trim()) ?? 0;
    final currentImageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk Baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Live Preview Card
              Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ProductImage(
                        imageUrl: currentImageUrl.isEmpty ? null : currentImageUrl,
                        categoryId: _categoryId,
                        width: 56,
                        height: 56,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRATINJAU KATALOG KASIR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _nameController.text.trim().isEmpty
                                   ? 'Nama Produk'
                                   : _nameController.text.trim(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRupiah(parsedPrice),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isActive ? 'Stok: $parsedStock' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown Kategori
              StreamBuilder(
                stream: widget.productService.streamActiveCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const [];
                  return DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Produk',
                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? 'Pilih kategori produk' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Nama Produk
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 20),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Foto / Gambar Produk Terintegrasi CDN & Database
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image_outlined, color: scheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Foto / Gambar Produk',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (currentImageUrl.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _imageUrlController.clear());
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preview Banner Gambar
                    if (currentImageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          child: ProductImage(
                            imageUrl: currentImageUrl,
                            categoryId: _categoryId,
                            height: 140,
                            width: double.infinity,
                            borderRadius: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tombol Aksi: Pilih dari CDN & Saran Otomatis
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _openCdnPicker,
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Pilih dari CDN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _applyAutoSuggestion,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text('Saran Otomatis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Input URL Gambar Manual
                    TextFormField(
                      controller: _imageUrlController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'URL Gambar (CDN / Web)',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link_rounded, size: 20),
                        suffixIcon: currentImageUrl.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() => _imageUrlController.clear());
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bisa pilih foto langsung dari katalog CDN di atas atau tempel tautan gambar bebas (JPG, PNG, WebP, SVG).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Harga & Stok side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixIcon: Icon(Icons.payments_rounded, size: 20),
                      ),
                      validator: (value) {
                        final v = int.tryParse((value ?? '').trim());
                        if (v == null) return 'Harus angka';
                        if (v < 0) return 'Tidak boleh negatif';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        prefixIcon: Icon(Icons.inventory_2_rounded, size: 20),
                      ),
                      validator: (value) {
                        final v = int.tryParse((value ?? '').trim());
                        if (v == null) return 'Harus angka';
                        if (v < 0) return 'Tidak boleh negatif';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Produk (Opsional)',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Switch Status Aktif
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Status Produk Aktif', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isActive
                        ? 'Produk akan muncul di katalog kasir'
                        : 'Produk disembunyikan dari katalog kasir',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  value: _isActive,
                  activeThumbColor: scheme.primary,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),

              if (_savingError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _savingError!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              if (_saving)
                const LoadingView(label: 'Menyimpan data produk ke Firebase...')
              else
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Produk Sekarang'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet untuk memilih gambar CDN sesuai katalog database
class _CdnImagePickerSheet extends StatefulWidget {
  const _CdnImagePickerSheet({this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<_CdnImagePickerSheet> createState() => _CdnImagePickerSheetState();
}

class _CdnImagePickerSheetState extends State<_CdnImagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    var filtered = kCatalogCdnImages;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((img) => img.categoryId == _selectedCategory).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((img) {
        return img.title.toLowerCase().contains(q) ||
            img.keywords.any((kw) => kw.toLowerCase().contains(q));
      }).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Sheet
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Gambar CDN',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Pilih foto berkualitas tinggi sesuai menu POS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _search = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari foto (ayam, mie, kopi, teh, keripik...)...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Semua', null),
                const SizedBox(width: 6),
                _buildCategoryChip('Makanan', 'cat_makanan'),
                const SizedBox(width: 6),
                _buildCategoryChip('Minuman', 'cat_minuman'),
                const SizedBox(width: 6),
                _buildCategoryChip('Snack', 'cat_snack'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Grid Foto
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.image_not_supported_outlined,
                    title: 'Foto tidak ditemukan',
                    message: 'Coba gunakan kata kunci pencarian yang lain.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(item.url),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                  child: Image.network(
                                    item.url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.categoryName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: scheme.onSurface.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? catId) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _selectedCategory == catId;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = catId),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : scheme.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? scheme.primary : scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
