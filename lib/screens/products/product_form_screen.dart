import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/formatters.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';

/// Form tambah atau ubah produk dengan Live Preview interaktif.
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.restaurant_rounded, color: scheme.primary, size: 28),
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
                    value: _categoryId,
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
                  activeColor: scheme.primary,
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
