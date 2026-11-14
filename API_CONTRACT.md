API Contract
Dokumen ini mendefinisikan kontrak REST API internal antara Flutter POS dan backend Node.js/Express.

Penting: endpoint di dokumen ini adalah rancangan API internal aplikasi, bukan endpoint resmi MiomiPay. Endpoint, request, response, autentikasi provider, dan webhook MiomiPay harus mengikuti dokumentasi resmi provider.
1. Konvensi Umum
- Base URL disediakan melalui konfigurasi environment aplikasi.
- Gunakan HTTPS di environment selain local development.
- Format request dan response menggunakan JSON.
- Prefix endpoint: /api/v1.
- Waktu menggunakan ISO 8601 UTC dalam response JSON.
- Nominal uang menggunakan integer.
- Gunakan HTTP status code sesuai hasil request.
- Jangan mengirim secret MiomiPay ke Flutter.
Contoh header:
Authorization: Bearer <firebase-id-token>
Content-Type: application/json
Accept: application/json
Endpoint privat harus memverifikasi Firebase ID Token. Role diperiksa oleh backend, bukan hanya oleh Flutter.
2. Format Response
Sukses
{
  "success": true,
  "data": {},
  "message": "Request berhasil"
}
Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data yang dikirim tidak valid",
    "details": {}
  }
}
details boleh dihilangkan jika tidak diperlukan. Jangan mengirim stack trace, secret, atau detail internal server kepada client.
3. HTTP Status Code
Status	Penggunaan
200 OK	Request berhasil
201 Created	Resource berhasil dibuat
400 Bad Request	Format atau parameter tidak valid
401 Unauthorized	Token tidak ada, tidak valid, atau kedaluwarsa
403 Forbidden	User tidak memiliki izin
404 Not Found	Resource tidak ditemukan
409 Conflict	Konflik stok/status atau request duplikat
422 Unprocessable Entity	Data valid secara format tetapi tidak dapat diproses
500 Internal Server Error	Kesalahan server


4. Authentication dan Authorization
Semua endpoint privat menerima Firebase ID Token melalui header Authorization.

Backend:
1. Mengambil bearer token.
2. Memverifikasi token dengan Firebase Admin SDK.
3. Mengambil UID dari token.
4. Membaca profil user/role dari sumber data tepercaya.
5. Memastikan akun aktif.
6. Memeriksa role yang diizinkan untuk endpoint.
Role:
- admin: mengelola kategori dan produk; akses tambahan mengikuti requirement.
- cashier: membaca katalog dan membuat checkout; akses riwayat mengikuti kebijakan yang dikonfirmasi.
Jangan menerima uid, role, atau status akun sebagai bukti identitas dari body request.
5. Endpoint Overview
Method	Endpoint	Role	Fungsi
GET	/api/v1/me	Admin, Cashier	Profil user yang sedang login
GET	/api/v1/categories	Admin, Cashier	Daftar kategori
POST	/api/v1/categories	Admin	Membuat kategori
PATCH	/api/v1/categories/:id	Admin	Mengubah kategori
GET	/api/v1/products	Admin, Cashier	Daftar produk
POST	/api/v1/products	Admin	Membuat produk
GET	/api/v1/products/:id	Admin, Cashier	Detail produk
PATCH	/api/v1/products/:id	Admin	Mengubah produk
DELETE	/api/v1/products/:id	Admin	Menghapus/nonaktifkan produk
POST	/api/v1/checkout	Cashier	Membuat transaksi dan memulai pembayaran
GET	/api/v1/transactions	Admin, Cashier*	Daftar transaksi
GET	/api/v1/transactions/:id	Admin, Cashier*	Detail transaksi
POST	/api/v1/webhooks/miomipay	Provider	Menerima notifikasi pembayaran terverifikasi


* Akses kasir ke transaksi perlu dibatasi sesuai keputusan bisnis, misalnya hanya transaksi miliknya. Webhook tidak menggunakan Firebase ID Token; verifikasi mengikuti mekanisme resmi MiomiPay.
6. Endpoint Detail
6.1 Get Current User
GET /api/v1/me

Role: Admin, Cashier.

Response 200:
{
  "success": true,
  "data": {
    "uid": "firebase-auth-uid",
    "name": "Nama Pengguna",
    "email": "user@example.com",
    "role": "cashier",
    "isActive": true
  }
}
Backend mengambil identitas dari token dan profil tepercaya, bukan dari query/body client.
6.2 List Categories
GET /api/v1/categories

Role: Admin, Cashier.

Query opsional:
- activeOnly=true|false
Response 200:
{
  "success": true,
  "data": [
    {
      "id": "category-id",
      "name": "Minuman",
      "description": "Kategori minuman",
      "isActive": true
    }
  ]
}
6.3 Create Category
POST /api/v1/categories

Role: Admin.

Request:
{
  "name": "Minuman",
  "description": "Kategori minuman"
}
Response 201:
{
  "success": true,
  "data": {
    "id": "new-category-id",
    "name": "Minuman",
    "description": "Kategori minuman",
    "isActive": true
  },
  "message": "Kategori berhasil dibuat"
}
6.4 Update Category
PATCH /api/v1/categories/:id

Role: Admin.

Request:
{
  "name": "Minuman Dingin",
  "description": "Minuman dingin",
  "isActive": true
}
Semua field bersifat opsional, tetapi minimal satu field yang dapat diubah harus dikirim. Backend memvalidasi tipe dan nilai field.
6.5 List Products
GET /api/v1/products

Role: Admin, Cashier.

Query opsional:
- categoryId=<id>
- activeOnly=true|false
- search=<keyword>
- limit=<number>
- cursor=<opaque-cursor>
Response 200:
{
  "success": true,
  "data": [
    {
      "id": "product-id",
      "name": "Kopi Susu",
      "description": "Kopi susu dingin",
      "categoryId": "category-id",
      "price": 18000,
      "stock": 25,
      "imageUrl": "https://example.com/product.jpg",
      "isActive": true
    }
  ],
  "meta": {
    "nextCursor": null
  }
}
Kasir hanya menerima produk yang dapat dijual. Admin dapat melihat produk nonaktif jika diperlukan.
6.6 Create Product
POST /api/v1/products

Role: Admin.

Request:
{
  "name": "Kopi Susu",
  "description": "Kopi susu dingin",
  "categoryId": "category-id",
  "price": 18000,
  "stock": 25,
  "imageUrl": "https://example.com/product.jpg"
}
Response 201 mengembalikan produk yang sudah disimpan. Backend memvalidasi kategori, harga, stok, dan URL gambar.
6.7 Get Product Detail
GET /api/v1/products/:id

Role: Admin, Cashier.

Response 200 mengembalikan satu object produk. Produk nonaktif tidak boleh digunakan untuk checkout.
6.8 Update Product
PATCH /api/v1/products/:id

Role: Admin.

Request contoh:
{
  "name": "Kopi Susu Large",
  "price": 22000,
  "stock": 20,
  "isActive": true
}
Backend hanya mengizinkan field yang tercantum dalam kontrak. Jangan izinkan client mengubah field internal yang tidak didefinisikan.
6.9 Delete Product
DELETE /api/v1/products/:id

Role: Admin.

Rekomendasi implementasi: soft delete dengan mengubah isActive menjadi false, agar histori transaksi tetap konsisten.

Response 200:
{
  "success": true,
  "data": {
    "id": "product-id",
    "isActive": false
  },
  "message": "Produk berhasil dinonaktifkan"
}
6.10 Checkout
POST /api/v1/checkout

Role: Cashier.

Request dari Flutter hanya mengirim identitas produk dan kuantitas. Jangan kirim harga/total sebagai nilai yang dipercaya.
{
  "items": [
    {
      "productId": "product-id",
      "quantity": 2
    }
  ],
  "paymentMethod": "miomipay"
}
Response konseptual 201:
{
  "success": true,
  "data": {
    "transactionId": "internal-transaction-id",
    "transactionNumber": "POS-20261114-000001",
    "paymentStatus": "pending",
    "subtotal": 36000,
    "discount": 0,
    "total": 36000,
    "currency": "IDR",
    "payment": {
      "provider": "miomipay",
      "paymentUrl": "https://provider-payment-url.example"
    }
  },
  "message": "Transaksi berhasil dibuat, menunggu pembayaran"
}
Response di atas hanya contoh bentuk internal. Nama field dan cara membuka pembayaran harus disesuaikan dengan respons resmi MiomiPay.

Backend wajib:
1. Memverifikasi token dan role kasir.
2. Memvalidasi item dan kuantitas.
3. Mengambil harga, status, dan stok dari Firestore.
4. Menolak produk nonaktif atau stok tidak mencukupi.
5. Menghitung ulang seluruh nilai transaksi.
6. Membuat transaksi internal dengan status pending.
7. Memanggil API MiomiPay menggunakan secret backend.
8. Menyimpan referensi provider dan informasi pembayaran yang aman.
9. Menangani kegagalan provider tanpa meninggalkan transaksi dalam status yang menyesatkan.
10. Menggunakan idempotency key untuk mencegah checkout ganda jika mekanisme tersebut diterapkan.
6.11 List Transactions
GET /api/v1/transactions

Role: Admin, Cashier dengan pembatasan.

Query opsional:
- status=<payment-status>
- from=<ISO-8601>
- to=<ISO-8601>
- limit=<number>
- cursor=<opaque-cursor>
Backend harus membatasi hasil berdasarkan role dan kebijakan akses. Jangan mengandalkan filter di Flutter sebagai kontrol keamanan.
6.12 Transaction Detail
GET /api/v1/transactions/:id

Role: Admin, Cashier dengan pembatasan.

Backend memastikan user berhak melihat transaksi tersebut sebelum mengembalikan detailnya.
6.13 MiomiPay Webhook
POST /api/v1/webhooks/miomipay

Endpoint ini dipanggil oleh MiomiPay, bukan oleh Flutter.

Ketentuan:
- Terapkan verifikasi signature/token sesuai dokumentasi resmi MiomiPay.
- Jangan menganggap request valid hanya karena endpoint menerima JSON.
- Cocokkan referensi pembayaran dengan transaksi internal.
- Validasi nominal, mata uang, dan status terhadap data transaksi.
- Proses event secara idempotent.
- Update transaksi dan stok secara atomik sesuai kebijakan stok.
- Simpan catatan event yang sudah diproses untuk audit.
- Balas status HTTP sesuai ketentuan webhook provider.
Bentuk payload webhook sengaja tidak ditentukan di dokumen ini karena harus diambil dari dokumentasi resmi MiomiPay.
7. Error Codes Internal
Code	Arti
AUTH_REQUIRED	Token tidak tersedia
INVALID_TOKEN	Token tidak valid
ACCOUNT_DISABLED	Akun tidak aktif
FORBIDDEN	Role tidak memiliki akses
VALIDATION_ERROR	Input tidak valid
RESOURCE_NOT_FOUND	Data tidak ditemukan
PRODUCT_INACTIVE	Produk tidak aktif
INSUFFICIENT_STOCK	Stok tidak mencukupi
CHECKOUT_CONFLICT	Konflik saat checkout
PAYMENT_PROVIDER_ERROR	Provider pembayaran gagal/tidak tersedia
PAYMENT_VERIFICATION_FAILED	Verifikasi pembayaran gagal
INTERNAL_ERROR	Kesalahan internal


8. Keamanan API
- Gunakan HTTPS.
- Verifikasi Firebase ID Token pada semua endpoint privat.
- Terapkan role authorization di backend.
- Validasi dan sanitasi semua input.
- Terapkan rate limit pada endpoint login terkait, checkout, dan endpoint publik.
- Jangan pernah menerima total transaksi sebagai nilai final dari client.
- Jangan expose secret MiomiPay atau Firebase service account ke Flutter.
- Jangan menandai pembayaran lunas dari callback client.
- Verifikasi webhook dan terapkan idempotensi.
- Hindari menampilkan stack trace atau informasi internal kepada client.
- Batasi CORS ke origin yang diperlukan pada production.
9. Konfigurasi Environment Backend
Contoh nama environment variable, bukan nilai credential:
PORT=3000
NODE_ENV=development

FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

MIOMIPAY_BASE_URL=
MIOMIPAY_API_KEY=
MIOMIPAY_SECRET_KEY=
MIOMIPAY_WEBHOOK_SECRET=
Nama variabel dan kebutuhan credential MiomiPay harus disesuaikan dengan dokumentasi provider. Jangan commit file .env. Sediakan .env.example tanpa nilai rahasia.
10. API yang Sudah Ada pada Starter Project
Kode starter yang sebelumnya dibagikan menggunakan:
- GET /api/data
- GET /api/history
- POST /api/message
- WebSocket pada server yang sama.
Endpoint tersebut merupakan bagian dari starter realtime/demo dan bukan kontrak POS di atas. Implementasi server yang dibagikan belum menunjukkan seluruh endpoint POS. Sebelum menghapus atau mengganti endpoint lama:
1. Cari semua pemanggilnya di Flutter.
2. Pastikan tidak ada halaman/fitur yang masih bergantung.
3. Implementasikan endpoint pengganti.
4. Uji endpoint pengganti.
5. Hapus kode demo secara bertahap jika sudah tidak digunakan.
11. Testing Checklist
- [ ] Request privat tanpa token ditolak.
- [ ] Token invalid/expired ditolak.
- [ ] Kasir tidak dapat membuat atau mengubah produk.
- [ ] Admin dapat membuat, membaca, mengubah, dan menonaktifkan produk.
- [ ] Produk nonaktif tidak dapat di-checkout.
- [ ] Checkout menolak quantity nol/negatif.
- [ ] Checkout menolak stok tidak mencukupi.
- [ ] Backend menghitung ulang harga dan total.
- [ ] Secret provider tidak pernah dikirim ke Flutter.
- [ ] Kegagalan provider ditangani dengan status transaksi yang konsisten.
- [ ] Webhook invalid ditolak.
- [ ] Webhook duplikat tidak memproses pembayaran/stok dua kali.
- [ ] User tidak dapat membaca transaksi milik user lain jika akses dibatasi per kasir.
12. TODO Konfirmasi
- Dokumentasi resmi MiomiPay: base URL, endpoint, authentication, request/response, signature, webhook, status, timeout, dan sandbox.
- Apakah checkout memakai idempotency key.
- Kebijakan stok untuk transaksi pending.
- Kebijakan kasir melihat riwayat transaksi.
- Apakah fitur diskon/pajak diperlukan.
- Apakah admin perlu endpoint untuk mengelola user/kasir.
- Apakah upload gambar produk ditangani layanan storage terpisah.