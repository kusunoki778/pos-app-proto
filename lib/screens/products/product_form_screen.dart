import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/formatters.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';

/// Form tambah atau ubah produk. [product] null berarti mode tambah.
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
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder(
                stream: widget.productService.streamActiveCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const [];
                  return DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Kategori wajib dipilih' : null,
                  );
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama produk',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final v = int.tryParse((value ?? '').trim());
                  if (v == null) return 'Harga harus angka';
                  if (v < 0) return 'Harga tidak boleh negatif';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: (value) {
                  final v = int.tryParse((value ?? '').trim());
                  if (v == null) return 'Stok harus angka';
                  if (v < 0) return 'Stok tidak boleh negatif';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'URL gambar (opsional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Produk aktif'),
                subtitle: Text(
                  _isActive
                      ? 'Tampil di katalog kasir'
                      : 'Disembunyikan dari katalog kasir',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (!_isEdit && _priceController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Pratinjau harga: ${formatRupiah(
                      int.tryParse(_priceController.text.trim()) ?? 0,
                    )}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (_savingError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _savingError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              if (_saving)
                const LoadingView(label: 'Menyimpan...')
              else
                FilledButton(
                  onPressed: _save,
                  child: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
