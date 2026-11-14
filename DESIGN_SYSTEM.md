# Design System — Kasir Toko

Arah desain final yang dipakai aplikasi POS ini. Menggantikan usulan
indigo `#4F46E5` di PRD §8.1 (keputusan pemilik, 14 November 2026).

Arah: **hangat seperti toko**. Dial: ENERGY 2 / RHYTHM 2 / MOTION 1.

## 1. Palet Warna

| Token | Nilai | Pemakaian |
|---|---|---|
| `cream` | `#FAF6EE` | Latar halaman (mengurangi silau, seperti kertas kas) |
| `surface` | `#FFFDF7` | Kartu dan input di atas krem |
| `green` | `#1F4D3A` | Warna utama: app bar terisi ikon, tombol primer |
| `greenSoft` | `#E4EDE5` | Latar chip ikon, indikator navigasi |
| `amber` | `#E0A526` | Satu-satunya aksen: total, tombol bayar |
| `ink` | `#1C1B18` | Teks utama |
| `inkMuted` | `#5C564A` | Teks sekunder |
| `outline` | `#DCD3C2` | Garis batas kartu dan input |
| `error` | `#B3261E` | Error |

Kontras: `ink` di atas `cream` ≈ 13.8:1, `green` di atas `cream` ≈ 8.9:1,
`onPrimary` `#F7F3E8` di atas `green` ≈ 9.1:1. Semua lolos WCAG AA.

Tema gelap:

| Token | Nilai |
|---|---|
| `darkBg` | `#17150F` |
| `darkSurface` | `#211E17` |
| `darkGreen` (primer) | `#8CC7A6` |
| `darkInk` | `#EFEAE0` |
| `darkInkMuted` | `#A89F8F` |
| `darkOutline` | `#3B372C` |

Aturan palet: 3 warna inti (krem, hijau, amber) + netral. Amber hanya
dipakai untuk satu momen penting per layar (total atau tombol bayar).

## 2. Tipografi

| Item | Nilai | Alasan |
|---|---|---|
| Font | Plus Jakarta Sans | Rupa huruf dari Indonesia, ramah, bukan font default AI |
| Angka | `fontFeatures: tabularFigures()` | Digit harga rata, kolom total mudah dipindai |
| Judul layar | `headlineSmall` w700 | |
| Judul kartu | `titleMedium` w700 | |
| Teks isi | `bodyMedium` | |
| Label sekunder | `bodySmall`, `inkMuted` | |

## 3. Bentuk dan Spasi

| Item | Nilai | Alasan |
|---|---|---|
| Radius input/tombol | 10 px | Pilih dari satu nilai, tidak campur |
| Radius kartu | 12 px | Sedikit lebih besar dari kontrol |
| Radius chip | 100 px | Hanya untuk chip status |
| Elevation kartu | 0 + garis `outline` | Kartu datar seperti kertas, bukan kartu mengambang |
| Padding layar | 16 px | |
| Padding layar login | 24 px horizontal | |
| Jarak antar elemen | 4 / 14 / 20 / 28 | Skala bertingkat, bukan spasi seragam |

## 4. Komponen

### Tombol

- Primer: `FilledButton`, latar `green`, tinggi minimum 48 px, radius 10.
- Teks tombol spesifik konteks: "Masuk", "Bayar", "Simpan produk".
  Dilarang "Get Started" dan sejenisnya.
- Tombol bayar memakai `amber` sebagai penanda aksi terpenting.

### Input

- `InputDecorationTheme`: latar `surface`, border `outline`,
  fokus memakai `green` 1.6 px.
- Setiap field punya label terlihat.
- Password punya toggle tampil/sembunyi dengan tooltip.

### Navigasi

- `NavigationBar` di bawah, latar `surface`, indikator `greenSoft`.
- Menu admin: Kasir, Produk, Riwayat, Laporan, Pengaturan.
- Menu kasir: Kasir, Riwayat, Pengaturan.

### Kartu

- Latar `surface`, border `outline`, radius 12, elevation 0.

## 5. Keadaan Wajib

| Keadaan | Tampilan |
|---|---|
| Loading | `LoadingView` (spinner + label, mis. "Memeriksa sesi...") |
| Kosong | `EmptyState` (ikon relevan + judul + pesan jujur, bukan ilustrasi) |
| Error | SnackBar atau teks inline dengan pesan yang bisa dipahami kasir |
| Disabled | Kontrol dinonaktifkan dengan subtitle alasan (mis. "Akan aktif pada Fase 4") |

## 6. Motif Identitas

Satu motif: **garis putus-putus struk**. Dipakai hanya sebagai pemisah
di ringkasan pembayaran/struk. Tidak dipakai di tempat lain.

## 7. Dilarang

- Gradasi biru-ungu, glow, glassmorphism.
- Lebih dari satu aksen warna per layar.
- Ikon dekoratif yang tidak nyambung dengan konteks.
- Shadow besar yang membuat seluruh halaman mengambang.

## 8. Implementasi

Semua token di atas hidup di `lib/theme.dart` (kelas `AppColors`,
`buildLightTheme()`, `buildDarkTheme()`). Komponen dasar di
`lib/widgets/common.dart` (`EmptyState`, `LoadingView`).
