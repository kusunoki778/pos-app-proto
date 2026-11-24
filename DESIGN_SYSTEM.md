# Design System — Kasir Toko

Arah desain yang dipakai aplikasi POS ini. Tema "hangat seperti toko"
(14 November 2026) diganti oleh pemilik lewat commit `tugas pos`:
**Modern FinTech / SaaS POS** — bersih, segar, profesional, berenergi
tinggi, supaya tidak terasa membosankan.

Arah: ENERGY 3 / RHYTHM 2 / MOTION 2.

## 1. Palet Warna

| Token | Nilai | Pemakaian |
|---|---|---|
| `primary` | `#4F46E5` (Indigo 600) | Warna utama: tombol primer, harga, indikator nav, fokus input |
| `primaryHover` | `#4338CA` (Indigo 700) | State tekan tombol primer |
| `primarySoft` | `#EEF2FF` (Indigo 50) | Latar chip ikon, indikator navigasi |
| `emerald` | `#10B981` (Emerald 500) | Penanda uang/sukses: stok aman, snackbar sukses, metode tunai |
| `emeraldSoft` | `#ECFDF5` | Latar ikon status sukses |
| `amber` | `#F59E0B` | Aksen tunggal: stok menipis, notifikasi, peringatan |
| `amberSoft` | `#FEF3C7` | Latar ikon peringatan |
| `bgLight` | `#F8FAFC` (Slate 50) | Latar halaman |
| `surfaceLight` | `#FFFFFF` | Kartu dan input |
| `outline` | `#E2E8F0` (Slate 200) | Garis batas kartu dan input |
| `ink` | `#0F172A` (Slate 900) | Teks utama |
| `inkMuted` | `#64748B` (Slate 500) | Teks sekunder |
| `error` | `#EF4444` | Error, stok habis |

Tema gelap: `darkBg #0F172A`, `darkSurface #1E293B`,
`darkPrimary #818CF8`, `darkOutline #334155`.

Aturan palet: indigo = aksi utama, emerald = uang/berhasil,
amber = peringatan. Maksimal satu aksen per momen.

## 2. Tipografi

| Item | Nilai | Alasan |
|---|---|---|
| Font | Plus Jakarta Sans | Rupa huruf Indonesia, ramah, bukan font default AI |
| Angka | `fontFeatures: tabularFigures()` | Digit harga rata, kolom total mudah dipindai |
| Judul layar | 18 px w700 (AppBar) | |
| Judul kartu | `titleMedium` w600–w700 | |
| Angka statistik | w800, 16 px+ | Meniru dashboard POS (Kasir Pintar/Moka): angka besar |
| Teks isi | `bodyMedium` | |
| Label sekunder | `bodySmall`, `inkMuted` | |

## 3. Bentuk dan Spasi

| Item | Nilai | Alasan |
|---|---|---|
| Radius input/tombol | 12 px | |
| Radius kartu global | 14 px | |
| Radius kartu produk/metrik | 16 px | Sedikit lebih bulat, terasa modern |
| Radius ikon brand login | 18 px | |
| Elevation kartu | 0 + garis `outline` | Kartu datar, tidak mengambang |
| Padding layar | 16–20 px | |
| Jarak antar elemen | 4 / 12 / 16 / 20 / 28 | Skala bertingkat |

## 4. Komponen

### Tombol

- Primer: `FilledButton`, latar `primary`, tinggi minimum 48 px, radius 12.
- Label spesifik konteks: "Masuk ke Aplikasi", "Bayar", "Lanjut ke Pembayaran".
  Dilarang "Get Started" dan sejenisnya.
- Tombol lebar penuh dibungkus `SizedBox(width: double.infinity)`.

### Input

- `InputDecorationTheme`: latar putih, border `outline` radius 12,
  fokus `primary` 1.8 px.
- Setiap field punya label terlihat; password punya toggle dengan tooltip.

### Navigasi

- `NavigationBar` di bawah, latar putih, tinggi 68,
  indikator `primarySoft`, label terpilih `primary` w700.
- Menu admin: Kasir, Produk, Riwayat, Laporan, Pengaturan.
- Menu kasir: Kasir, Riwayat, Pengaturan.

### Kartu

- Latar putih, border `outline`, radius 14 (global) / 16 (produk, metrik).

## 5. Animasi

Motion halus, bukan dekoratif — dipakai untuk feedback dan orientasi.

| Pemakaian | Teknik | Lokasi |
|---|---|---|
| Entrance bertahap (fade + geser ke atas) | `StaggerEnter` (`lib/widgets/animasi.dart`) | Login, grid produk, kartu statistik, daftar produk |
| Muncul/hilang bar keranjang | `AnimatedSlide` 280 ms easeOutCubic | `cashier_screen.dart` |
| Angka total berganti | `AnimatedSwitcher` 220 ms fade + slide | `cart_panel.dart` |
| Transisi antar halaman | `pageTransitionsTheme` fade-upwards (Android) | `theme.dart` |
| SnackBar | `floating`, radius 12 | `theme.dart` |
| Indikator tab | bawaan `NavigationBar` | Material 3 |

Aturan: jeda antar elemen bertahap 45–90 ms; durasi 220–450 ms;
kurva `easeOutCubic`. Tanpa animasi yang menunda input pengguna.

## 6. Keadaan Wajib

| Keadaan | Tampilan |
|---|---|
| Loading | `LoadingView` (spinner + label, mis. "Memuat menu...") |
| Kosong | `EmptyState` (ikon relevan + judul + pesan jujur) |
| Error | SnackBar atau teks inline dengan pesan yang bisa dipahami kasir |
| Disabled | Kontrol dinonaktifkan (mis. tombol "Habis", bayar saat keranjang kosong) |

## 7. Dilarang

- Gradasi dekoratif di luar ikon brand (login) dan bar keranjang.
- Lebih dari satu aksen warna untuk satu momen.
- Shadow besar yang membuat seluruh halaman mengambang.
- Ikon dekoratif yang tidak nyambung dengan konteks.
- Font selain Plus Jakarta Sans.

## 8. Implementasi

Semua token hidup di `lib/theme.dart` (kelas `AppColors`,
`buildLightTheme()`, `buildDarkTheme()`). Komponen dasar di
`lib/widgets/common.dart` (`EmptyState`, `LoadingView`) dan
`lib/widgets/animasi.dart` (`StaggerEnter`). Warna statis di layar
harus memakai nilai token `AppColors` (mis. `#EEF2FF` = `primarySoft`).
