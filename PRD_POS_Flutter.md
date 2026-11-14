# Product Requirements Document (PRD)

## Aplikasi Point of Sale (POS) -- Flutter

> **Catatan pembaruan (14 November 2026).** Beberapa keputusan di sesi
> pengembangan memodifikasi rancangan awal dokumen ini:
>
> 1. **Visual**: memakai arah "hangat seperti toko" (krem `#FAF6EE`,
>    hijau `#1F4D3A`, amber `#E0A526`, Plus Jakarta Sans). Lihat
>    `DESIGN_SYSTEM.md`. Usulan indigo `#4F46E5` + Inter di §8.1
>    digantikan.
> 2. **Platform**: Android saja. Web tidak dipakai karena FCM dan
>    debugging paling andal di Android (§9 arsitektur tetap berlaku,
>    bagian Web tidak diimplementasikan).
> 3. **Struktur folder**: target §13.4 (`features/`, `providers/`)
>    digantikan struktur yang benar-benar dipakai: `lib/{core,models,
>    services,state,screens,widgets}`.
> 4. **Pembayaran**: tetap MiomiPay sesuai dokumen ini. Checkout kasir
>    tunai hanya fase pengganti sementara sampai dokumentasi API
>    MiomiPay tersedia (§16).
> 5. **Nama package Android**: `com.pos.myapp` (menjawab §16 poin 6).
> 6. **Notifikasi FCM** naik status menjadi fitur inti (pengingat
>    transaksi baru ke admin), bukan opsional.
>
> Bagian yang tidak disebut di atas tetap berlaku.

  Informasi               Detail
  ----------------------- ---------------------------
  Nama project            POS Application
  Root project saat ini   `realtime_communication/`
  Platform target         Android dan Web
  Frontend                Flutter (Dart)
  Backend                 Node.js + Express.js
  Database                Firebase Cloud Firestore
  Authentication          Firebase Authentication
  Payment Gateway         MiomiPay API
  State Management        Provider
  Status                  Perencanaan

------------------------------------------------------------------------

## 1. Ringkasan Produk

Aplikasi Point of Sale (POS) berbasis Flutter untuk Android dan Web yang
membantu Admin mengelola produk serta Kasir memproses transaksi
penjualan dan pembayaran melalui MiomiPay. Firebase digunakan untuk
autentikasi dan penyimpanan data secara realtime, sedangkan Express.js
menjadi backend untuk proses yang membutuhkan validasi server dan
integrasi payment gateway.

## 2. Latar Belakang dan Masalah

Pencatatan penjualan secara manual berpotensi menimbulkan kesalahan
perhitungan, ketidaksesuaian informasi produk, dan kesulitan memantau
transaksi. Aplikasi POS ini menyediakan proses pengelolaan produk,
keranjang, checkout, dan pembayaran dalam satu sistem.

## 3. Tujuan Produk

1.  Menyediakan aplikasi kasir digital yang mudah digunakan.
2.  Memisahkan hak akses Admin dan Kasir.
3.  Memungkinkan Admin mengelola data produk.
4.  Memungkinkan Kasir melihat katalog dan membuat transaksi.
5.  Menyimpan data produk dan transaksi di Firebase.
6.  Mengintegrasikan pembayaran melalui MiomiPay sesuai dokumentasi API
    resminya.

## 4. Pengguna dan Hak Akses

### 4.1 Admin

-   Login dan logout.
-   Melihat dashboard.
-   Melihat daftar produk.
-   Menambahkan produk.
-   Mengubah nama, harga, kategori, dan stok produk.
-   Menghapus atau menonaktifkan produk.
-   Melihat data transaksi dan laporan jika fitur tersebut diaktifkan.

### 4.2 Kasir

-   Login dan logout.
-   Melihat katalog produk yang aktif.
-   Mencari dan memilih produk.
-   Menambahkan produk ke keranjang.
-   Mengubah kuantitas dan menghapus item dari keranjang.
-   Melihat subtotal dan total pembayaran.
-   Membuat checkout dan memproses pembayaran MiomiPay.
-   Melihat status pembayaran.

## 5. Ruang Lingkup Fitur

### 5.1 Fitur Wajib

-   Firebase Authentication menggunakan email dan password.
-   Role Admin dan Kasir.
-   Dashboard berdasarkan role.
-   CRUD produk untuk Admin.
-   Katalog produk untuk Kasir.
-   Keranjang belanja.
-   Checkout.
-   Integrasi API MiomiPay.
-   Penyimpanan data menggunakan Cloud Firestore.
-   Sinkronisasi perubahan data produk secara realtime.

### 5.2 Fitur Tambahan (Opsional)

-   Riwayat transaksi.
-   Laporan penjualan.
-   Manajemen stok.
-   Struk digital.
-   Notifikasi transaksi atau stok.

Fitur opsional dikerjakan setelah seluruh fitur wajib berjalan.

### 5.3 Di Luar Ruang Lingkup Awal

-   Multi-cabang.
-   Manajemen supplier.
-   Akuntansi lengkap.
-   Integrasi printer thermal.
-   Aplikasi iOS.
-   Program loyalitas pelanggan.

## 6. Alur Pengguna

### 6.1 Login dan Pengarahan Role

1.  Pengguna membuka aplikasi dan memasukkan email serta password.
2.  Firebase Authentication memverifikasi kredensial.
3.  Aplikasi mengambil profil dari `users/{uid}`.
4.  Aplikasi memeriksa role dan status akun.
5.  Admin diarahkan ke Dashboard Admin.
6.  Kasir diarahkan ke Dashboard Kasir.

### 6.2 Pengelolaan Produk

1.  Admin membuka halaman Products.
2.  Admin menambah, mengubah, atau menonaktifkan produk.
3.  Perubahan disimpan ke Cloud Firestore.
4.  Katalog Kasir menerima pembaruan melalui Firestore Stream.

### 6.3 Checkout dan Pembayaran

1.  Kasir memilih produk dan memasukkannya ke keranjang.
2.  Aplikasi menampilkan ringkasan pesanan.
3.  Aplikasi mengirim permintaan checkout ke backend.
4.  Backend memverifikasi identitas pengguna, role, harga, dan
    ketersediaan stok.
5.  Backend membuat transaksi berstatus `pending`.
6.  Backend meminta pembayaran ke MiomiPay menggunakan kredensial
    server.
7.  Backend mengembalikan instruksi atau informasi pembayaran kepada
    aplikasi.
8.  Pelanggan menyelesaikan pembayaran.
9.  MiomiPay mengirim webhook ke backend jika mekanisme tersebut
    disediakan.
10. Backend memverifikasi keaslian dan status pembayaran.
11. Backend memperbarui status transaksi dan stok secara konsisten.
12. Aplikasi menampilkan status pembayaran terbaru.

**Catatan:** Detail endpoint, autentikasi, format request/response,
metode pembayaran, dan webhook MiomiPay harus mengikuti dokumentasi
resmi penyedia. Jangan mengasumsikan format API sebelum dokumentasi
tersedia.

------------------------------------------------------------------------

## 7. Arsitektur Sistem

### 7.1 Gambaran Arsitektur

``` text
+-------------------------------------------+
|              Flutter App                  |
|              Android & Web               |
|                                           |
|  Admin UI | Cashier UI | Cart | Checkout  |
+---------------------+---------------------+
                      |
          +-----------+-----------+
          |                       |
          v                       v
+-------------------+   +-------------------+
| Firebase Auth     |   | Cloud Firestore   |
| Login & Identity  |   | Products          |
|                   |   | Categories        |
|                   |   | Users             |
|                   |   | Transactions      |
+-------------------+   +-------------------+
          |
          | HTTPS REST API + Firebase ID Token
          v
+-------------------------------------------+
|              Express.js Backend           |
|                                           |
| Authentication Middleware                 |
| Product/Transaction Validation            |
| Payment Service                           |
| Webhook Handler                           |
| Firebase Admin SDK                        |
+---------------------+---------------------+
                      |
                      | Payment API
                      v
              +---------------+
              |   MiomiPay    |
              | Payment       |
              | Gateway       |
              +---------------+
                      |
                      | Webhook / Callback
                      v
               Express.js Backend
                      |
                      v
                Cloud Firestore
```

### 7.2 Tanggung Jawab Komponen

  -----------------------------------------------------------------------
  Komponen                            Tanggung jawab
  ----------------------------------- -----------------------------------
  Flutter                             UI, navigasi, katalog, keranjang,
                                      checkout

  Provider                            State management

  Firebase Authentication             Autentikasi pengguna

  Cloud Firestore                     Data user, produk, kategori,
                                      transaksi

  Express.js                          REST API dan integrasi pembayaran

  Firebase Admin SDK                  Verifikasi Firebase ID Token dan
                                      akses server ke Firestore

  MiomiPay                            Pemrosesan pembayaran

  Webhook                             Penerimaan dan verifikasi pembaruan
                                      status pembayaran
  -----------------------------------------------------------------------

### 7.3 Pola Komunikasi

-   Flutter menggunakan Firebase SDK untuk autentikasi dan pembacaan
    data yang diizinkan.
-   Flutter menggunakan Firestore Streams untuk pembaruan data realtime.
-   Flutter mengirim permintaan pembayaran ke Express.js melalui HTTPS.
-   Flutter menyertakan Firebase ID Token pada request yang membutuhkan
    autentikasi.
-   Express.js memverifikasi token menggunakan Firebase Admin SDK.
-   Express.js berkomunikasi dengan MiomiPay menggunakan kredensial yang
    hanya disimpan di server.
-   Webhook MiomiPay diterima dan diverifikasi oleh backend sebelum
    status transaksi diperbarui.

### 7.4 Peran WebSocket

Project saat ini sudah menggunakan package `ws` dan WebSocket server.
WebSocket tidak wajib untuk fitur inti POS karena Firestore Streams
dapat menangani sinkronisasi realtime produk dan data yang diizinkan.
WebSocket boleh dipertahankan untuk kebutuhan komunikasi custom di masa
mendatang, tetapi jangan membuat dua mekanisme realtime untuk data yang
sama tanpa kebutuhan jelas.

------------------------------------------------------------------------

## 8. Desain UI/UX

### 8.1 Arah Visual

Konsep: **Modern Minimal POS Dashboard**.

  Elemen            Rekomendasi
  ----------------- -------------
  Primary           `#4F46E5`
  Background        `#F8FAFC`
  Surface           `#FFFFFF`
  Primary text      `#0F172A`
  Secondary text    `#64748B`
  Success           `#16A34A`
  Error             `#DC2626`
  Font              Inter
  Border radius     10--14 px
  Component style   Material 3

### 8.2 Halaman Admin

  Halaman              Isi
  -------------------- --------------------------------------
  Login                Email, password, tombol login
  Dashboard            Ringkasan produk dan transaksi
  Product Management   Tabel/list produk, pencarian, filter
  Add Product          Form nama, harga, kategori, stok
  Edit Product         Form perubahan data produk
  Profile              Informasi akun dan logout

### 8.3 Halaman Kasir

  Halaman          Isi
  ---------------- ----------------------------------------------
  Login            Email dan password
  POS Dashboard    Katalog produk dan kategori
  Product Detail   Informasi produk, harga, stok
  Cart             Item, kuantitas, subtotal
  Checkout         Ringkasan dan total pembayaran
  Payment          Instruksi atau informasi pembayaran MiomiPay
  Payment Status   Status pending, paid, failed, atau expired

### 8.4 Perilaku Responsive

-   Web: gunakan sidebar untuk navigasi dashboard.
-   Android: gunakan drawer atau bottom navigation sesuai kebutuhan
    halaman.
-   Layout kasir Web dapat menampilkan katalog dan keranjang
    berdampingan.
-   Layout Android dapat menampilkan katalog dan membuka keranjang pada
    halaman atau panel terpisah.
-   Form dan tabel harus tetap nyaman digunakan pada ukuran layar yang
    berbeda.

------------------------------------------------------------------------

## 9. Desain Database -- Cloud Firestore

Database yang direkomendasikan adalah Cloud Firestore karena mendukung
collection/document, query, realtime listener, dan transaksi database.

### 9.1 Struktur Collection

``` text
firestore/
|
+-- users/
|   +-- {uid}
|       +-- name
|       +-- email
|       +-- role              // admin | cashier
|       +-- isActive
|       +-- createdAt
|
+-- categories/
|   +-- {categoryId}
|       +-- name
|       +-- isActive
|       +-- createdAt
|
+-- products/
|   +-- {productId}
|       +-- name
|       +-- price
|       +-- categoryId
|       +-- stock
|       +-- isActive
|       +-- createdAt
|       +-- updatedAt
|
+-- transactions/
|   +-- {transactionId}
|       +-- cashierId
|       +-- items
|       +-- subtotal
|       +-- total
|       +-- paymentMethod
|       +-- paymentStatus
|       +-- paymentReference
|       +-- createdAt
|       +-- updatedAt
|
+-- payment_attempts/
    +-- {paymentId}
        +-- transactionId
        +-- provider
        +-- providerReference
        +-- amount
        +-- status
        +-- createdAt
        +-- updatedAt
```

### 9.2 Contoh Dokumen Product

``` json
{
  "name": "Kopi Susu",
  "price": 15000,
  "categoryId": "cat_drink",
  "stock": 50,
  "isActive": true,
  "createdAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

### 9.3 Contoh Dokumen Transaction

``` json
{
  "cashierId": "user_123",
  "items": [
    {
      "productId": "prod_001",
      "name": "Kopi Susu",
      "price": 15000,
      "quantity": 2,
      "subtotal": 30000
    }
  ],
  "subtotal": 30000,
  "total": 30000,
  "paymentMethod": "miomipay",
  "paymentStatus": "pending",
  "paymentReference": null,
  "createdAt": "Firestore Timestamp"
}
```

### 9.4 Ketentuan Database

-   Kredensial login dikelola Firebase Authentication, bukan disimpan
    sebagai password di `users`.
-   Harga disimpan sebagai integer dalam rupiah.
-   `items` menyimpan snapshot nama dan harga saat transaksi dibuat.
-   `payment_attempts` memisahkan percobaan pembayaran dari transaksi
    utama.
-   Gunakan server timestamp untuk waktu pencatatan yang tepercaya.
-   Role dan status akun harus diperiksa oleh backend dan Firestore
    Security Rules.
-   Dokumen transaksi tidak boleh dapat diubah status pembayarannya
    secara bebas oleh aplikasi Kasir.

### 9.5 Relasi Data

``` text
users
  |
  +-- uid
       |
       +-- transactions.cashierId

products
  |
  +-- categoryId --> categories

transactions
  |
  +-- items[] --> productId
  |
  +-- paymentReference --> payment_attempts
```

------------------------------------------------------------------------

## 10. Payment Flow dan Konsistensi Stok

### 10.1 Status Transaksi

Status minimum yang disiapkan:

-   `pending`: pembayaran belum terkonfirmasi.
-   `paid`: pembayaran sudah diverifikasi berhasil.
-   `failed`: pembayaran gagal.
-   `expired`: pembayaran kedaluwarsa.
-   `cancelled`: transaksi dibatalkan jika alur provider mendukungnya.

### 10.2 Aturan Penting

1.  Harga dan total harus divalidasi ulang di backend dari data produk,
    bukan mempercayai total dari Flutter.
2.  Backend harus memverifikasi Firebase ID Token dan role pengguna.
3.  Secret key MiomiPay hanya berada di server.
4.  Webhook harus diverifikasi sesuai mekanisme resmi MiomiPay.
5.  Proses webhook harus idempotent agar event yang sama tidak diproses
    berulang.
6.  Pengurangan stok dilakukan setelah pembayaran terverifikasi,
    menggunakan transaksi Firestore.
7.  Jika stok tidak tersedia saat konfirmasi pembayaran, backend harus
    memiliki kebijakan penanganan yang jelas dan tidak boleh diam-diam
    menghasilkan stok negatif.
8.  Pembatalan atau kedaluwarsa tidak boleh mengurangi stok.

------------------------------------------------------------------------

## 11. Security dan Authorization

  Operasi                                Admin   Kasir            Backend
  ------------------------------------ ------- ------- ------------------
  Login                                     Ya      Ya   Verifikasi token
  Read produk                               Ya      Ya                 Ya
  Create produk                             Ya   Tidak           Validasi
  Update produk                             Ya   Tidak           Validasi
  Delete/nonaktifkan produk                 Ya   Tidak           Validasi
  Membuat checkout                       Tidak      Ya           Validasi
  Mengubah status pembayaran             Tidak   Tidak                 Ya
  Mengurangi stok setelah pembayaran     Tidak   Tidak                 Ya

Ketentuan keamanan:

-   Terapkan Firebase Security Rules dengan prinsip least privilege.
-   Jangan mengandalkan proteksi UI saja.
-   Gunakan Firebase ID Token untuk autentikasi REST API.
-   Gunakan HTTPS pada deployment.
-   Simpan service account JSON dan secret MiomiPay di environment
    server yang aman.
-   Jangan commit file `.env` atau service account JSON ke Git.
-   Validasi input, nominal, stok, dan identitas transaksi di backend.

------------------------------------------------------------------------

## 12. Tech Stack

  Layer                 Teknologi           Kegunaan
  --------------------- ------------------- --------------------------------
  Frontend              Flutter             Aplikasi Android dan Web
  Language              Dart                Bahasa pemrograman
  UI                    Material 3          Komponen UI
  State Management      Provider            Pengelolaan state
  Routing               GoRouter            Navigasi
  Authentication        Firebase Auth       Login pengguna
  Database              Cloud Firestore     Penyimpanan data
  Backend Runtime       Node.js             Runtime server
  Backend Framework     Express.js          REST API
  CORS                  cors                Pengaturan akses lintas origin
  Firebase Server SDK   firebase-admin      Akses Firebase dari backend
  HTTP Client           http / Dio          Request dari Flutter
  Server HTTP Client    axios (opsional)    Request ke MiomiPay
  Payment Gateway       MiomiPay API        Pembayaran
  Realtime              Firestore Streams   Sinkronisasi data
  Version Control       Git & GitHub        Pengelolaan source code

### 12.1 Dependensi Flutter

Dependensi yang direkomendasikan:

``` bash
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add provider
flutter pub add go_router
flutter pub add http
flutter pub add intl
```

`flutter_dotenv` hanya boleh digunakan untuk konfigurasi non-rahasia di
sisi aplikasi. Secret key payment gateway tidak boleh berada di Flutter.

### 12.2 Dependensi Backend

**Sudah tersedia di project saat ini:**

-   `express`
-   `cors`
-   `ws`

Berdasarkan `server/package.json` yang ada, Express, CORS, dan WebSocket
sudah terpasang. Tidak perlu menginstal ulang ketiganya.

**Dependensi tambahan yang direkomendasikan:**

``` bash
cd server
npm install firebase-admin dotenv axios
```

`axios` digunakan jika dipilih sebagai HTTP client untuk request ke
MiomiPay. `ws` dapat dipertahankan jika masih ada kebutuhan WebSocket
custom.

------------------------------------------------------------------------

## 13. Analisis Root Project Saat Ini

Struktur yang terlihat dari project saat ini:

``` text
realtime_communication/
|
+-- android/
+-- ios/
+-- lib/
|   +-- services/
|   |   +-- api_service.dart
|   +-- widget/
|   +-- config.dart
|   +-- firebase_options.dart
|   +-- main.dart
|   +-- theme.dart
|
+-- server/
|   +-- node_modules/
|   +-- package-lock.json
|   +-- package.json
|   +-- server.js
|
+-- test/
+-- web/
+-- windows/
+-- linux/
+-- macos/
```

### 13.1 Analisis File Flutter

  -----------------------------------------------------------------------
  File                                Kondisi/Fungsi
  ----------------------------------- -----------------------------------
  `lib/config.dart`                   Konfigurasi host, port, REST URL,
                                      WebSocket URL, dan gRPC host

  `lib/services/api_service.dart`     HTTP GET data, GET history, dan
                                      POST message

  `lib/firebase_options.dart`         Konfigurasi Firebase hasil
                                      FlutterFire

  `lib/main.dart`                     Entry point aplikasi

  `lib/theme.dart`                    Konfigurasi tema

  `lib/widget/`                       Komponen UI yang sudah ada
  -----------------------------------------------------------------------

### 13.2 Analisis Backend

`server.js` saat ini:

-   Menggunakan Express.js.
-   Mengaktifkan CORS.
-   Menggunakan JSON middleware.
-   Membuat HTTP server.
-   Menjalankan WebSocket server menggunakan package `ws`.
-   Menghasilkan data acak setiap dua detik.
-   Menyimpan maksimal 100 data pada array in-memory.
-   Menyediakan `GET /api/data`.
-   Menyediakan `POST /api/message`.
-   Melakukan broadcast data melalui WebSocket.

### 13.3 Hal yang Perlu Diperbaiki

-   Endpoint `/api/history` sudah dipanggil Flutter tetapi belum
    tersedia pada `server.js` yang diberikan.
-   Endpoint `/api/long-poll` belum tersedia.
-   Endpoint `/api/events` atau SSE belum tersedia.
-   `grpcPort` sudah didefinisikan di konfigurasi Flutter, tetapi belum
    ada implementasi server gRPC pada kode yang diberikan.
-   Data acak dan array in-memory perlu digantikan atau dipisahkan dari
    penyimpanan data POS.
-   Firebase Auth, Firestore, dan payment flow perlu diimplementasikan.

### 13.4 Rencana Pengembangan Struktur Folder

Struktur target yang disarankan:

``` text
realtime_communication/
|
+-- lib/
|   +-- core/
|   |   +-- config/
|   |   +-- constants/
|   |   +-- theme/
|   |   +-- utils/
|   |
|   +-- models/
|   |   +-- user_model.dart
|   |   +-- product_model.dart
|   |   +-- category_model.dart
|   |   +-- cart_item_model.dart
|   |   +-- transaction_model.dart
|   |
|   +-- services/
|   |   +-- firebase_service.dart
|   |   +-- auth_service.dart
|   |   +-- product_service.dart
|   |   +-- transaction_service.dart
|   |   +-- api_service.dart
|   |
|   +-- providers/
|   |   +-- auth_provider.dart
|   |   +-- product_provider.dart
|   |   +-- cart_provider.dart
|   |   +-- transaction_provider.dart
|   |
|   +-- features/
|   |   +-- auth/
|   |   +-- admin/
|   |   |   +-- dashboard/
|   |   |   +-- products/
|   |   |   +-- profile/
|   |   |
|   |   +-- cashier/
|   |   |   +-- dashboard/
|   |   |   +-- catalog/
|   |   |   +-- cart/
|   |   |   +-- checkout/
|   |   |
|   |   +-- payment/
|   |
|   +-- widgets/
|   +-- firebase_options.dart
|   +-- main.dart
|
+-- server/
|   +-- src/
|   |   +-- config/
|   |   +-- middleware/
|   |   +-- routes/
|   |   +-- controllers/
|   |   +-- services/
|   |   +-- utils/
|   |
|   +-- .env
|   +-- .gitignore
|   +-- package.json
|   +-- server.js
|
+-- test/
+-- README.md
```

Struktur ini merupakan target pengembangan, bukan gambaran file yang
sudah tersedia.

------------------------------------------------------------------------

## 14. Development Roadmap

  Tahap   Pekerjaan                            Prioritas
  ------- ------------------------------------ -----------
  1       Setup Firebase Auth dan Firestore    Tinggi
  2       Implementasi login dan role          Tinggi
  3       Dashboard Admin dan Kasir            Tinggi
  4       CRUD produk                          Tinggi
  5       Katalog dan keranjang                Tinggi
  6       Checkout dan penyimpanan transaksi   Tinggi
  7       Integrasi MiomiPay                   Tinggi
  8       Webhook dan validasi pembayaran      Tinggi
  9       Firebase Security Rules              Tinggi
  10      Testing Android dan Web              Tinggi
  11      UI polishing dan dokumentasi         Menengah

## 15. Acceptance Criteria

Project dianggap memenuhi kebutuhan utama apabila:

-   [ ] Admin dapat login.
-   [ ] Kasir dapat login.
-   [ ] Pengguna diarahkan berdasarkan role.
-   [ ] Admin dapat melakukan CRUD produk.
-   [ ] Kasir hanya dapat melihat produk yang tersedia.
-   [ ] Perubahan produk tersinkronisasi secara realtime.
-   [ ] Kasir dapat mengelola keranjang.
-   [ ] Total pembayaran dihitung dengan benar.
-   [ ] Backend dapat membuat permintaan pembayaran MiomiPay.
-   [ ] Status pembayaran diverifikasi sebelum transaksi ditandai
    berhasil.
-   [ ] Stok diperbarui secara konsisten setelah pembayaran berhasil.
-   [ ] Aplikasi dapat berjalan pada Android dan Web.
-   [ ] Security Rules dan backend authorization sudah diterapkan.

## 16. Informasi yang Masih Dibutuhkan

Sebelum integrasi pembayaran dan deployment, diperlukan:

1.  Firebase project yang akan digunakan.
2.  Konfigurasi Firebase untuk Android dan Web.
3.  Dokumentasi resmi API MiomiPay.
4.  Kredensial sandbox MiomiPay jika tersedia.
5.  Informasi metode pembayaran dan mekanisme webhook yang didukung.
6.  Nama package Android yang akan dipertahankan.

------------------------------------------------------------------------

## 17. Kesimpulan

Aplikasi POS dibangun menggunakan Flutter sebagai frontend, Firebase
Authentication untuk autentikasi, Cloud Firestore untuk penyimpanan
data, serta Express.js sebagai backend untuk validasi transaksi dan
integrasi MiomiPay.

Arsitektur memisahkan tanggung jawab frontend, database, dan backend
agar sistem lebih terstruktur, aman, dan mudah dikembangkan.
Pengembangan dilakukan secara bertahap dengan memprioritaskan
autentikasi, role pengguna, CRUD produk, katalog, keranjang, checkout,
dan pembayaran.

**Dokumen ini merupakan rancangan target pengembangan. Fitur dan
integrasi yang belum terlihat pada source code tidak dianggap sudah
selesai atau tersedia.**
