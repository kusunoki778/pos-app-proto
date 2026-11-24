import 'package:flutter/material.dart';

/// Widget tampilan gambar produk serbaguna:
/// - Mendukung URL gambar CDN (Unsplash, Firebase Storage, link internet umum)
/// - Menampilkan fallback ikon kategori jika gambar tidak tersedia atau gagal dimuat
/// - Animasi transisi dan indikator loading yang mulus
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.categoryId,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String? categoryId;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  IconData _iconForCategory(String? catId) {
    if (catId == null) return Icons.restaurant_rounded;
    final lower = catId.toLowerCase();
    if (lower.contains('minum') || lower.contains('drink') || lower.contains('beverage')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('snack') || lower.contains('camilan')) {
      return Icons.cookie_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget placeholderWidget({bool isError = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFFEE2E2)
              : scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(
            _iconForCategory(categoryId),
            size: (height != null && height! < 60) ? 22 : 32,
            color: isError
                ? const Color(0xFFEF4444)
                : scheme.primary.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (!hasValidUrl) {
      return placeholderWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!.trim(),
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return placeholderWidget(isError: true);
        },
      ),
    );
  }
}
