# Database Schema

Dokumen ini mendefinisikan rancangan struktur data untuk aplikasi POS Flutter. Database utama yang digunakan dalam rancangan ini adalah **Cloud Firestore**.

Schema ini merupakan rancangan awal berdasarkan requirement proyek. Sesuaikan keputusan yang masih TBD setelah aturan bisnis dan kebutuhan MiomiPay dikonfirmasi.

## 1. Prinsip Desain

- Gunakan Firestore sebagai sumber data utama untuk user profile, kategori, produk, dan transaksi.
- Gunakan Firebase Authentication untuk kredensial login. Password tidak disimpan di Firestore.
- Simpan nominal uang sebagai integer dalam satuan mata uang terkecil yang digunakan sistem (misalnya Rupiah tanpa desimal), bukan floating point.
- Simpan waktu sebagai Firestore Timestamp dan gunakan UTC di penyimpanan.
- Gunakan document ID yang stabil; hindari menjadikan nama produk sebagai document ID.
- Data pembayaran yang sensitif dan hasil verifikasi provider hanya boleh ditulis backend.
- Semua harga, total, dan stok harus divalidasi di server saat checkout.

## 2. Struktur Collection

```text
Firestore
├── users/{uid}
├── categories/{categoryId}
├── products/{productId}
├── transactions/{transactionId}
└── payment_events/{eventId}
```

## 3. Collection: `users`

Document ID menggunakan Firebase Authentication UID.

Contoh:

```json
{
  "uid": "firebase-auth-uid",
  "name": "Nama Pengguna",
  "email": "user@example.com",
  "role": "cashier",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---:|---|
| `uid` | string | Ya | Sama dengan Firebase Auth UID |
| `name` | string | Ya | Nama pengguna |
| `email` | string | Ya | Email pengguna |
| `role` | string | Ya | `admin` atau `cashier` |
| `isActive` | boolean | Ya | Status akun |
| `createdAt` | timestamp | Ya | Waktu pembuatan |
| `updatedAt` | timestamp | Ya | Waktu perubahan terakhir |

Aturan:
- Dokumen dibuat melalui proses provisioning akun yang tepercaya.
- Pengguna tidak boleh mengubah field `role` atau `isActive` miliknya sendiri.
- Role dari dokumen ini tetap harus diperiksa oleh backend atau Security Rules sebelum akses data sensitif.
- Password dikelola Firebase Authentication, bukan disimpan di dokumen ini.

## 4. Collection: `categories`

Contoh:

```json
{
  "name": "Minuman",
  "description": "Kategori minuman",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---:|---|
| `name` | string | Ya | Nama kategori |
| `description` | string/null | Tidak | Deskripsi |
| `isActive` | boolean | Ya | Status kategori |
| `createdAt` | timestamp | Ya | Waktu dibuat |
| `updatedAt` | timestamp | Ya | Waktu diubah |

Catatan:
- Kategori yang sudah digunakan produk sebaiknya dinonaktifkan, bukan langsung dihapus.
- Backend perlu memvalidasi bahwa kategori aktif saat produk dibuat atau diubah.

## 5. Collection: `products`

Contoh:

```json
{
  "name": "Kopi Susu",
  "description": "Kopi susu dingin",
  "categoryId": "category-id",
  "price": 18000,
  "stock": 25,
  "imageUrl": "https://example.com/product.jpg",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---:|---|
| `name` | string | Ya | Nama produk |
| `description` | string/null | Tidak | Deskripsi produk |
| `categoryId` | string | Ya | Referensi ID kategori |
| `price` | integer | Ya | Harga satuan |
| `stock` | integer | Ya | Jumlah stok tersedia |
| `imageUrl` | string/null | Tidak | URL gambar produk |
| `isActive` | boolean | Ya | Status produk |
| `createdAt` | timestamp | Ya | Waktu dibuat |
| `updatedAt` | timestamp | Ya | Waktu diubah |

Validasi:
- `name` tidak boleh kosong.
- `price` harus integer dan lebih besar atau sama dengan nol.
- `stock` harus integer dan tidak boleh negatif.
- `categoryId` harus mengarah ke kategori yang valid.
- Produk nonaktif tidak dapat ditambahkan ke transaksi baru.
- Perubahan stok dilakukan melalui proses backend yang tervalidasi.

## 6. Collection: `transactions`

Satu dokumen mewakili satu transaksi checkout. ID transaksi dibuat oleh backend.

Contoh:

```json
{
  "transactionNumber": "POS-20261114-000001",
  "cashierId": "firebase-auth-uid",
  "items": [
    {
      "productId": "product-id",
      "productName": "Kopi Susu",
      "unitPrice": 18000,
      "quantity": 2,
      "lineTotal": 36000
    }
  ],
  "subtotal": 36000,
  "discount": 0,
  "total": 36000,
  "currency": "IDR",
  "paymentMethod": "miomipay",
  "paymentStatus": "pending",
  "transactionStatus": "pending",
  "providerReference": null,
  "paymentUrl": null,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "paidAt": null
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---:|---|
| `transactionNumber` | string | Ya | Nomor transaksi yang ditampilkan |
| `cashierId` | string | Ya | UID kasir pembuat transaksi |
| `items` | array/map | Ya | Snapshot item ketika checkout |
| `items[].productId` | string | Ya | ID produk |
| `items[].productName` | string | Ya | Snapshot nama produk |
| `items[].unitPrice` | integer | Ya | Snapshot harga server |
| `items[].quantity` | integer | Ya | Jumlah item |
| `items[].lineTotal` | integer | Ya | `unitPrice × quantity` |
| `subtotal` | integer | Ya | Total sebelum diskon |
| `discount` | integer | Ya | Nilai diskon; default 0 jika belum ada fitur diskon |
| `total` | integer | Ya | Total akhir yang dihitung backend |
| `currency` | string | Ya | Misalnya `IDR` |
| `paymentMethod` | string | Ya | Metode pembayaran |
| `paymentStatus` | string | Ya | `pending`, `paid`, `failed`, `expired`, atau `refunded` sesuai dukungan provider |
| `transactionStatus` | string | Ya | Status proses transaksi internal |
| `providerReference` | string/null | Tidak | ID transaksi dari MiomiPay |
| `paymentUrl` | string/null | Tidak | URL pembayaran jika disediakan provider |
| `createdAt` | timestamp | Ya | Waktu dibuat |
| `updatedAt` | timestamp | Ya | Waktu terakhir diubah |
| `paidAt` | timestamp/null | Tidak | Waktu pembayaran terkonfirmasi |

Catatan:
- `items` menyimpan snapshot nama dan harga agar riwayat tidak berubah ketika data produk diperbarui.
- Jangan menerima `unitPrice`, `lineTotal`, `subtotal`, atau `total` sebagai nilai tepercaya dari Flutter.
- Field provider tambahan hanya ditambahkan setelah format resmi MiomiPay diketahui.
- Hindari menyimpan data kartu atau data pembayaran sensitif.

## 7. Collection: `payment_events`

Collection ini menyimpan catatan webhook/event pembayaran yang sudah diterima backend untuk mendukung audit dan idempotensi.

Contoh konseptual:

```json
{
  "provider": "miomipay",
  "providerEventId": "provider-event-id",
  "providerReference": "provider-payment-reference",
  "transactionId": "firestore-transaction-id",
  "eventType": "payment_status_update",
  "processingStatus": "processed",
  "receivedAt": "Timestamp",
  "processedAt": "Timestamp"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---:|---|
| `provider` | string | Ya | Nama provider |
| `providerEventId` | string | Sesuai provider | ID unik event dari provider |
| `providerReference` | string/null | Tidak | Referensi pembayaran provider |
| `transactionId` | string | Ya | ID transaksi internal |
| `eventType` | string | Ya | Jenis event |
| `processingStatus` | string | Ya | `received`, `processed`, atau `failed` |
| `receivedAt` | timestamp | Ya | Waktu diterima |
| `processedAt` | timestamp/null | Tidak | Waktu selesai diproses |

Aturan:
- Backend memverifikasi webhook sebelum memperbarui transaksi.
- Gunakan ID event provider sebagai dasar deduplikasi jika tersedia.
- Jika provider tidak menyediakan event ID, tentukan strategi idempotensi berdasarkan dokumentasi resminya.
- Simpan payload mentah hanya jika diperlukan untuk audit, aman, dan sudah disaring dari data sensitif.

## 8. Relasi Data

```text
users (1) -------- (*) transactions
categories (1) --- (*) products
products (1) ------ (*) transaction items [snapshot]
transactions (1) -- (*) payment_events
```

Relasi di Firestore bersifat referensi melalui ID, bukan foreign key otomatis. Backend bertanggung jawab memastikan referensi yang digunakan valid.

## 9. Status Transaksi dan Pembayaran

Status berikut adalah rancangan internal awal, bukan klaim bahwa semua status didukung MiomiPay.

| Status | Makna |
|---|---|
| `pending` | Transaksi dibuat dan menunggu hasil pembayaran |
| `paid` | Pembayaran sudah diverifikasi backend |
| `failed` | Pembayaran gagal |
| `expired` | Pembayaran melewati batas waktu |
| `cancelled` | Transaksi dibatalkan sesuai aturan bisnis |
| `refunded` | Dana dikembalikan, jika fitur refund didukung |

Jangan mengubah transaksi menjadi `paid` berdasarkan redirect browser atau respons dari aplikasi Flutter.

## 10. Aturan Stok

Kebijakan stok ketika pembayaran pending masih perlu diputuskan.

Pilihan yang perlu dipertimbangkan:
1. **Kurangi stok setelah pembayaran sukses**: lebih sederhana, tetapi beberapa checkout pending dapat bersaing atas stok yang sama.
2. **Reservasi stok saat checkout**: perlu field/collection reservasi, batas waktu, dan proses pelepasan reservasi ketika gagal/expired.

Apa pun pilihannya:
- Operasi stok dilakukan backend.
- Validasi stok dan perubahan stok harus atomik menggunakan Firestore transaction.
- Event pembayaran duplikat tidak boleh mengurangi stok dua kali.
- Jangan mengurangi stok dari Flutter.

## 11. Index dan Query

Query yang kemungkinan dibutuhkan:
- Produk aktif berdasarkan kategori.
- Daftar transaksi berdasarkan `createdAt` terbaru.
- Transaksi berdasarkan `cashierId` dan rentang waktu.
- Transaksi berdasarkan `paymentStatus`.
- Payment event berdasarkan `providerEventId` atau `transactionId`.

Buat composite index Firestore hanya ketika query yang benar-benar digunakan memerlukannya. Ikuti pesan error Firestore untuk konfigurasi index yang tepat.

## 12. Keamanan Firestore

- Default akses harus ditolak kecuali ada rule yang secara eksplisit mengizinkan.
- Pengguna hanya dapat membaca data yang memang diperlukan role-nya.
- Perubahan role, status pembayaran, dan stok tidak boleh dilakukan oleh client.
- Jika Flutter mengakses Firestore secara langsung, rules wajib membatasi create/update/delete berdasarkan role dan field yang boleh berubah.
- Firebase Admin SDK di backend melewati Firestore Security Rules; karena itu backend wajib melakukan autentikasi, otorisasi, dan validasi sendiri.

## 13. TODO Konfirmasi

- Apakah kasir dapat melihat semua transaksi atau hanya transaksi miliknya?
- Apakah admin dapat mengelola akun kasir dari aplikasi?
- Apakah kategori wajib untuk setiap produk?
- Apakah diskon, pajak, service charge, dan biaya tambahan termasuk requirement?
- Apakah stok diaktifkan untuk semua produk?
- Bagaimana kebijakan reservasi stok selama pembayaran pending?
- Status dan field apa saja yang benar-benar dikirim MiomiPay?
- Apakah aplikasi hanya untuk satu outlet atau mendukung banyak outlet?
