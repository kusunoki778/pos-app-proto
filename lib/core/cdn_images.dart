class CdnImageItem {
  const CdnImageItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.url,
    required this.keywords,
  });

  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String url;
  final List<String> keywords;
}

/// Koleksi gambar CDN makanan, minuman, dan snack berkualitas tinggi
/// yang disesuaikan dengan katalog produk di Firebase POS.
const List<CdnImageItem> kCatalogCdnImages = [
  // --- MAKANAN ---
  CdnImageItem(
    id: 'cdn_ayam_geprek',
    title: 'Ayam Geprek / Ayam Krispi',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80',
    keywords: ['ayam', 'geprek', 'krispi', 'goreng', 'sambal'],
  ),
  CdnImageItem(
    id: 'cdn_mie_goreng',
    title: 'Mie Goreng Spesial',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&q=80',
    keywords: ['mie', 'goreng', 'spesial', 'bakmi', 'noodle', 'kuah', 'ramen'],
  ),
  CdnImageItem(
    id: 'cdn_roti_bakar',
    title: 'Roti Bakar Cokelat',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=500&q=80',
    keywords: ['roti', 'bakar', 'toast', 'cokelat', 'keju', 'sandwich'],
  ),
  CdnImageItem(
    id: 'cdn_nasi_goreng',
    title: 'Nasi Goreng Spesial',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&q=80',
    keywords: ['nasi', 'goreng', 'rice', 'telur', 'spesial'],
  ),
  CdnImageItem(
    id: 'cdn_burger',
    title: 'Burger Sapi Keju',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&q=80',
    keywords: ['burger', 'beef', 'keju', 'cheese', 'daging'],
  ),
  CdnImageItem(
    id: 'cdn_pizza',
    title: 'Pizza Margherita',
    categoryId: 'cat_makanan',
    categoryName: 'Makanan',
    url: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
    keywords: ['pizza', 'keju', 'mozzarella', 'roti'],
  ),

  // --- MINUMAN ---
  CdnImageItem(
    id: 'cdn_es_teh',
    title: 'Es Teh Manis',
    categoryId: 'cat_minuman',
    categoryName: 'Minuman',
    url: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80',
    keywords: ['teh', 'tea', 'es teh', 'manis', 'iced tea'],
  ),
  CdnImageItem(
    id: 'cdn_kopi_susu',
    title: 'Kopi Susu Gula Aren',
    categoryId: 'cat_minuman',
    categoryName: 'Minuman',
    url: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80',
    keywords: ['kopi', 'coffee', 'susu', 'aren', 'latte', 'espresso', 'cappuccino'],
  ),
  CdnImageItem(
    id: 'cdn_air_mineral',
    title: 'Air Mineral 600ml',
    categoryId: 'cat_minuman',
    categoryName: 'Minuman',
    url: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500&q=80',
    keywords: ['air', 'mineral', 'water', 'botol', 'aqua', 'segar'],
  ),
  CdnImageItem(
    id: 'cdn_jus_buah',
    title: 'Jus Buah Segar / Mocktail',
    categoryId: 'cat_minuman',
    categoryName: 'Minuman',
    url: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&q=80',
    keywords: ['jus', 'juice', 'jeruk', 'buah', 'orange', 'fresh', 'mocktail'],
  ),
  CdnImageItem(
    id: 'cdn_matcha_latte',
    title: 'Matcha Green Tea Latte',
    categoryId: 'cat_minuman',
    categoryName: 'Minuman',
    url: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&q=80',
    keywords: ['matcha', 'green tea', 'hijau', 'latte', 'susu'],
  ),

  // --- SNACK ---
  CdnImageItem(
    id: 'cdn_keripik_kentang',
    title: 'Keripik Kentang',
    categoryId: 'cat_snack',
    categoryName: 'Snack',
    url: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80',
    keywords: ['keripik', 'kentang', 'chips', 'crisps', 'snack', 'camilan', 'asin'],
  ),
  CdnImageItem(
    id: 'cdn_french_fries',
    title: 'Kentang Goreng / French Fries',
    categoryId: 'cat_snack',
    categoryName: 'Snack',
    url: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&q=80',
    keywords: ['kentang', 'fries', 'french', 'goreng', 'saus'],
  ),
  CdnImageItem(
    id: 'cdn_wafer_cokelat',
    title: 'Wafer Cokelat & Biscuit',
    categoryId: 'cat_snack',
    categoryName: 'Snack',
    url: 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=500&q=80',
    keywords: ['wafer', 'cokelat', 'chocolate', 'biskuit', 'manis', 'bar'],
  ),
  CdnImageItem(
    id: 'cdn_donat',
    title: 'Donat Cokelat Tabur',
    categoryId: 'cat_snack',
    categoryName: 'Snack',
    url: 'https://images.unsplash.com/photo-1527515862127-a4fc05baf7a5?w=500&q=80',
    keywords: ['donat', 'donut', 'cokelat', 'glaze', 'pastry'],
  ),
  CdnImageItem(
    id: 'cdn_cookies',
    title: 'Cookies Choco Chip',
    categoryId: 'cat_snack',
    categoryName: 'Snack',
    url: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=500&q=80',
    keywords: ['cookies', 'kue', 'choco', 'chip', 'biskuit'],
  ),
];

/// Mencari saran gambar CDN otomatis berdasarkan nama produk & kategori
CdnImageItem? suggestCdnImage(String productName, [String? categoryId]) {
  if (productName.trim().isEmpty) return null;
  final q = productName.toLowerCase();

  // Cocokkan keyword spesifik terlebih dahulu
  for (final item in kCatalogCdnImages) {
    for (final kw in item.keywords) {
      if (q.contains(kw)) {
        return item;
      }
    }
  }

  // Jika tidak ada keyword yang cocok, ambil berdasarkan kategori
  if (categoryId != null && categoryId.isNotEmpty) {
    for (final item in kCatalogCdnImages) {
      if (item.categoryId == categoryId) {
        return item;
      }
    }
  }

  return null;
}
