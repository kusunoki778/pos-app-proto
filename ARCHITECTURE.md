# System Architecture

Dokumen ini menjelaskan bagaimana aplikasi POS dibangun, bagaimana setiap komponen berkomunikasi, serta teknologi yang digunakan. Dokumen ini menjadi acuan implementasi untuk developer maupun AI coding agent.

## 1. Gambaran Sistem

Aplikasi POS memiliki dua jenis pengguna:

- **Admin**: mengelola produk/menu dan melihat data yang menjadi kewenangannya.
- **Kasir**: melihat katalog, mengelola keranjang, melakukan checkout, dan memproses pembayaran.

Aplikasi berjalan pada Android dan Web menggunakan satu codebase Flutter. Firebase digunakan untuk autentikasi dan penyimpanan data. Backend Node.js/Express menangani proses yang membutuhkan validasi server dan integrasi MiomiPay.

## 2. Technology Stack

Teknologi berikut merupakan stack yang direkomendasikan untuk proyek ini. Jika implementasi aktual berbeda, perbarui dokumen ini sebelum melakukan refactor besar.

| Area | Teknologi | Penggunaan |
|---|---|---|
| Frontend | Flutter | Satu aplikasi untuk Android dan Web |
| Bahasa frontend | Dart | Bahasa utama Flutter |
| UI | Material 3 | Komponen dan tema antarmuka |
| State management | Provider | State halaman dan alur fitur |
| Routing | GoRouter | Navigasi dan proteksi halaman berdasarkan status login/role |
| Backend runtime | Node.js | Menjalankan server backend |
| Backend framework | Express.js | REST API, middleware, dan webhook |
| Authentication | Firebase Authentication | Login dan identitas pengguna |
| Database | Cloud Firestore | Data user, produk, kategori, dan transaksi |
| Server Firebase SDK | Firebase Admin SDK | Verifikasi token dan akses Firestore dari backend |
| Payment gateway | MiomiPay API | Membuat dan memverifikasi proses pembayaran sesuai dokumentasi resmi |
| Komunikasi | HTTPS REST API | Komunikasi Flutter ke backend |
| Realtime data | Firestore Streams | Memperbarui data Firestore secara realtime |
| Version control | Git dan GitHub | Pengelolaan source code |
| API testing | Postman | Pengujian endpoint backend |
| IDE | Visual Studio Code | Pengembangan aplikasi |

### Catatan pemilihan teknologi

- **Provider** dan **GoRouter** adalah pilihan awal yang disarankan, bukan kewajiban jika project sudah menggunakan solusi lain secara konsisten.
- Gunakan **Cloud Firestore** sebagai database utama sesuai rancangan saat ini. Jangan mencampur Firestore dan Realtime Database tanpa kebutuhan yang jelas.
- WebSocket bukan kebutuhan utama POS. Gunakan Firestore Streams untuk perubahan data Firestore. WebSocket hanya dipertahankan jika ada kebutuhan realtime khusus yang tidak dapat dipenuhi Firestore.
- FCM/push notification bukan kebutuhan inti berdasarkan requirement proyek saat ini. Tambahkan hanya jika ada requirement tambahan.
- Integrasi MiomiPay harus mengikuti dokumentasi resmi dan kredensial sandbox yang diberikan. Jangan menebak endpoint, format signature, atau mekanisme verifikasi.

## 3. Diagram Arsitektur

```text
                    +---------------------------+
                    |     Flutter Application   |
                    |       Android / Web       |
                    |                           |
                    | Login, Dashboard, Catalog |
                    | Cart, Checkout, Admin UI  |
                    +-------------+-------------+
                                  |
                  +---------------+----------------+
                  |                                |
             Firebase Auth                   HTTPS REST API
                  |                         + Firebase ID Token
                  v                                |
        +---------------------+                     v
        | Firebase            |          +------------------------+
        | Authentication      |          | Node.js + Express      |
        +---------------------+          | Backend                |
                                         |                        |
                                         | Verify ID Token        |
                                         | Check user role        |
                                         | Validate product/stock |
                                         | Payment orchestration  |
                                         +-----+-------------+----+
                                               |             |
                                      Admin SDK|             |Payment API
                                               v             v
                                     +----------------+  +----------+
                                     | Cloud Firestore|  | MiomiPay |
                                     |                |  |          |
                                     | users          |  +----+-----+
                                     | products       |       |
                                     | categories     |       | Webhook/
                                     | transactions  |       | callback
                                     | payment_events |       |
                                     +-------^--------+       |
                                             |                |
                                             +----------------+
                                               Verified event
                                               and transaction
                                               update
```

## 4. Tanggung Jawab Setiap Komponen

| Komponen | Tanggung jawab |
|---|---|
| Flutter UI | Menampilkan halaman login, dashboard, katalog, keranjang, checkout, dan halaman admin |
| Flutter state layer | Mengelola state UI dan memanggil repository/service |
| Flutter repository/service | Membungkus akses Firebase dan pemanggilan REST API |
| Firebase Authentication | Mendaftarkan dan mengautentikasi pengguna |
| Cloud Firestore | Menyimpan profil/role pengguna, produk, kategori, transaksi, dan catatan event pembayaran |
| Express.js | Menyediakan API, memvalidasi request, menjalankan aturan bisnis sensitif, dan menerima webhook |
| Firebase Admin SDK | Memverifikasi Firebase ID Token dan mengakses Firestore dari backend |
| MiomiPay | Memproses pembayaran melalui API resmi |
| Postman | Menguji endpoint dan skenario integrasi |

## 5. Alur Komunikasi dan Data

### 5.1 Login

1. Pengguna memasukkan kredensial pada aplikasi Flutter.
2. Flutter melakukan autentikasi melalui Firebase Authentication.
3. Firebase mengembalikan sesi pengguna.
4. Aplikasi membaca profil pengguna dari Firestore untuk mendapatkan role.
5. Aplikasi mengarahkan pengguna ke area Admin atau Kasir sesuai role.
6. Backend tetap wajib memverifikasi token dan role untuk setiap endpoint yang dilindungi. Menyembunyikan tombol atau halaman di Flutter bukan mekanisme keamanan.

### 5.2 Pengelolaan Produk oleh Admin

1. Admin membuka halaman pengelolaan produk.
2. Flutter mengirim operasi baca/tambah/ubah/hapus melalui jalur data yang ditentukan project.
3. Operasi yang menggunakan backend harus membawa Firebase ID Token.
4. Backend memverifikasi token dan memastikan pengguna memiliki role Admin.
5. Backend memvalidasi data lalu menyimpan perubahan ke Firestore.
6. Flutter memperbarui tampilan berdasarkan hasil operasi atau Firestore Stream.

Jika akses Firestore langsung dari Flutter dipilih untuk operasi tertentu, Firestore Security Rules wajib membatasi operasi berdasarkan autentikasi dan role. Jangan mengandalkan pemeriksaan role di UI.

### 5.3 Katalog dan Keranjang Kasir

1. Kasir mengambil daftar produk aktif dari Firestore melalui repository.
2. Firestore Streams dapat digunakan agar perubahan katalog tampil tanpa refresh manual.
3. Kasir menambahkan produk ke keranjang.
4. Keranjang merupakan state sementara di sisi aplikasi; nilainya bukan sumber kebenaran untuk harga atau stok.
5. Saat checkout, aplikasi mengirim daftar ID produk dan kuantitas ke backend.

### 5.4 Checkout dan Pembayaran MiomiPay

1. Flutter mengirim permintaan checkout ke backend menggunakan HTTPS dan Firebase ID Token.
2. Backend memverifikasi token, role Kasir, format request, dan kuantitas.
3. Backend mengambil harga serta status/stok produk dari Firestore. Backend tidak mempercayai total harga yang dikirim client.
4. Backend menghitung ulang subtotal dan total berdasarkan data server.
5. Backend membuat transaksi berstatus awal yang sesuai dengan alur pembayaran.
6. Backend memanggil MiomiPay menggunakan kredensial yang disimpan di environment backend.
7. Backend mengembalikan informasi pembayaran yang aman untuk ditampilkan Flutter.
8. Status pembayaran diperbarui setelah backend menerima dan memverifikasi konfirmasi resmi dari MiomiPay.
9. Backend memperbarui transaksi dan stok dengan operasi yang aman terhadap retry/duplikasi.
10. Flutter menampilkan status berdasarkan data transaksi yang sudah tersimpan, bukan hanya berdasarkan redirect atau respons client.

**Penting:** jangan pernah menyimpan secret key MiomiPay di Flutter, menganggap redirect sukses sebagai bukti pembayaran, atau mengizinkan client mengubah status transaksi menjadi `paid`.

## 6. Struktur Folder yang Disarankan

Struktur ini adalah target organisasi kode. Sesuaikan dengan struktur project yang sudah ada dan lakukan perubahan bertahap.

### Flutter

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── models/
├── services/
│   ├── firebase/
│   └── api/
├── repositories/
├── providers/
├── features/
│   ├── auth/
│   ├── admin/
│   │   └── products/
│   └── cashier/
│       ├── catalog/
│       ├── cart/
│       └── checkout/
└── shared/
    └── widgets/
```

Aturan:
- Widget bertanggung jawab pada tampilan dan interaksi UI.
- Aturan bisnis tidak diletakkan langsung di widget.
- Provider mengelola state dan mengoordinasikan pemanggilan repository.
- Repository menjadi batas akses data agar UI tidak terikat pada detail Firebase atau HTTP.
- Model digunakan untuk representasi data dan serialisasi.
- Jangan membuat abstraksi berlebihan untuk fitur yang masih sederhana.

### Backend

```text
server/
├── src/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   │   ├── firebase.js
│   │   └── env.js
│   ├── routes/
│   ├── middleware/
│   │   ├── authenticate.js
│   │   └── authorize.js
│   ├── controllers/
│   ├── services/
│   │   └── payment/
│   ├── validators/
│   └── utils/
├── .env
├── .env.example
└── package.json
```

Aturan:
- `routes/` mendefinisikan endpoint.
- `middleware/` menangani autentikasi dan otorisasi.
- `controllers/` menangani request dan response HTTP.
- `services/` memuat aturan bisnis dan integrasi MiomiPay.
- `validators/` memvalidasi input.
- `config/` menginisialisasi Firebase Admin dan membaca environment.
- Jangan menaruh secret di source code atau file yang masuk Git.

## 7. Keamanan dan Konsistensi Data

1. Semua endpoint privat harus memverifikasi Firebase ID Token di backend.
2. Otorisasi role dilakukan di backend dan/atau Firestore Security Rules sesuai jalur akses data.
3. Role tidak boleh dipercaya hanya dari nilai yang dikirim client.
4. Harga, diskon, total transaksi, dan stok harus divalidasi dari data server.
5. Secret MiomiPay hanya berada di environment backend.
6. Webhook harus diverifikasi menggunakan mekanisme resmi MiomiPay.
7. Pemrosesan webhook dan pengurangan stok harus idempotent agar event yang sama tidak diproses dua kali.
8. Gunakan transaksi/batch Firestore untuk perubahan data yang harus konsisten.
9. Batasi CORS ke origin yang diperlukan ketika aplikasi mulai dipublikasikan.
10. Jangan mencatat password, token, secret, atau data pembayaran sensitif ke log.

## 8. Realtime dan WebSocket

Starter backend project saat ini telah menggunakan Express dan `ws` untuk contoh komunikasi realtime. Fitur tersebut belum otomatis menjadi bagian dari kebutuhan POS.

Arah implementasi:
- Gunakan Firestore Streams untuk perubahan produk dan transaksi yang disimpan di Firestore.
- Pertahankan WebSocket hanya jika ada fitur khusus yang memang memerlukannya.
- Hindari mengirim data yang sama melalui Firestore Streams dan WebSocket tanpa alasan.
- Jangan menganggap endpoint history, long-polling, SSE, atau gRPC sudah tersedia hanya karena konfigurasi URL/port-nya ada. Periksa implementasi server sebelum menggunakannya.

## 9. Kondisi Project Saat Ini dan Strategi Integrasi

Berdasarkan struktur kode yang telah dibagikan sebelumnya:
- `lib/config.dart` mengatur alamat host dan endpoint backend.
- `lib/services/api_service.dart` memiliki pemanggilan `/api/data`, `/api/history`, dan `/api/message`.
- `server/server.js` merupakan starter Express + WebSocket yang menghasilkan data contoh dan menyimpan history di memori.
- Implementasi server yang dibagikan belum menunjukkan endpoint POS, integrasi Firebase Admin, atau integrasi MiomiPay.
- `firebase_options.dart` sudah ada, tetapi keberadaannya sendiri belum membuktikan bahwa Firebase Authentication, Firestore, dan Security Rules sudah selesai dikonfigurasi.
- Konfigurasi port gRPC saja tidak membuktikan bahwa gRPC server telah dibuat.

Strategi:
1. Audit pemakaian `Config`, `ApiService`, route, dan WebSocket sebelum menghapus atau mengganti kode.
2. Pertahankan fitur starter yang masih digunakan sampai penggantinya diuji.
3. Tambahkan konfigurasi Firebase Admin di backend.
4. Implementasikan autentikasi dan role guard.
5. Implementasikan model dan akses data produk.
6. Implementasikan alur katalog, keranjang, dan checkout.
7. Integrasikan MiomiPay setelah dokumentasi resmi dan kredensial sandbox tersedia.
8. Hapus endpoint/data contoh hanya setelah dipastikan tidak lagi digunakan.

## 10. Keputusan yang Masih Perlu Dikonfirmasi

Keputusan berikut tidak boleh ditebak oleh AI coding agent:

- Versi dan detail endpoint/API MiomiPay, autentikasi, signature, webhook, serta status pembayaran.
- Kebijakan stok ketika pembayaran masih pending: apakah stok direservasi sementara atau baru dikurangi setelah pembayaran terkonfirmasi.
- Apakah semua operasi produk dilakukan melalui backend atau sebagian melalui Firestore SDK dengan Security Rules.
- Apakah kasir dapat melihat seluruh transaksi atau hanya transaksi miliknya.
- Aturan pembatalan, timeout, refund, dan pembayaran gagal.
- Apakah aplikasi membutuhkan multi-outlet/cabang atau hanya satu outlet.
- Format nomor transaksi dan kebutuhan laporan.

Jika informasi belum tersedia, tandai sebagai TODO dan jangan membuat asumsi yang berdampak pada uang, stok, atau keamanan.

## 11. Panduan untuk AI Coding Agent

- Baca `PRD_POS_Flutter.md`, `DATABASE_SCHEMA.md`, `API_CONTRACT.md`, dan `SECURITY_RULES.md` sebelum mengubah implementasi.
- Periksa kode yang sudah ada sebelum membuat file atau service baru.
- Jangan mengganti arsitektur atau dependency besar tanpa alasan dan persetujuan.
- Jangan mengarang endpoint MiomiPay atau mengarang konfigurasi credential.
- Jangan menyimpan secret dalam source code.
- Kerjakan per fitur kecil dan jalankan analyzer/test yang relevan setelah perubahan.
- Jangan commit atau push ke GitHub kecuali diminta secara eksplisit.
