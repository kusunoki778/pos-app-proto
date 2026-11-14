UI Interaction Flow
Dokumen ini menjelaskan alur pengguna dan respons aplikasi pada fitur inti POS. Gunakan bersama UI_SCREEN_SPEC.md, DATABASE_SCHEMA.md, dan API_CONTRACT.md.
1. Role-Based Entry Flow
App Launch
   |
Check Firebase Auth Session
   |
   +-- No session --> Login Screen
   |
   +-- Session exists
          |
      Load user profile
          |
      Check isActive and role
          |
          +-- Admin --> Admin Dashboard
          |
          +-- Cashier --> Cashier Catalog
          |
          +-- Invalid/Inactive --> Access denied / Sign out
Aturan:
- Role harus berasal dari sumber tepercaya.
- Navigasi berdasarkan role bukan pengganti backend authorization.
- Jika profil tidak ditemukan atau role tidak valid, jangan memberi akses default.
2. Login Flow
Login Screen
   |
Enter email and password
   |
Client-side validation
   |
Firebase Authentication sign-in
   |
Load user profile
   |
Check account active + role
   |
   +-- Admin --> Admin Dashboard
   |
   +-- Cashier --> Cashier Catalog
   |
   +-- Failure --> Show error
Respons UI:
- Input invalid: tampilkan pesan dekat field.
- Kredensial salah: tampilkan pesan autentikasi yang aman.
- Jaringan bermasalah: tampilkan opsi coba lagi.
- Proses berjalan: disable tombol login dan tampilkan loading.
- Akun nonaktif: tampilkan pesan akses ditolak.
3. Admin Product Management Flow
Admin Dashboard
   |
Open Products
   |
Product List
   |
   +-- Add --> Product Form --> Validate --> Save --> Product List
   |
   +-- Edit --> Product Form --> Validate --> Update --> Product List
   |
   +-- Deactivate/Delete --> Confirmation --> Update status --> Product List
Aturan:
- Setelah simpan sukses, tampilkan feedback singkat.
- Jika validasi gagal, pertahankan nilai input dan tampilkan error.
- Jika request gagal, jangan menghapus input form.
- Konfirmasi aksi destruktif.
- Operasi harus ditolak backend jika role bukan Admin.
4. Cashier Catalog to Cart Flow
Cashier Catalog
   |
Search / Filter products
   |
Select product
   |
Check active status and available stock
   |
Add to Cart
   |
Cart Summary updated
   |
Open Cart
   |
Change quantity / Remove item
   |
Continue to Checkout
Aturan:
- Jika produk nonaktif atau stok tidak cukup, tampilkan alasan dan jangan menambahkan kuantitas yang tidak tersedia.
- Jika harga berubah saat user sedang memilih produk, backend tetap menggunakan harga terbaru saat checkout dan mengembalikan total yang dihitung server.
- Keranjang kosong tidak dapat dilanjutkan ke checkout.
5. Checkout and Payment Flow
Cart
  |
Review order
  |
Confirm checkout
  |
Flutter sends productId + quantity + paymentMethod
  |
Backend verifies Firebase token and cashier role
  |
Backend reads current product price and stock
  |
Backend calculates total
  |
Create pending transaction
  |
Request payment to MiomiPay
  |
Return safe payment information
  |
User completes payment with provider
  |
MiomiPay sends webhook
  |
Backend verifies webhook
  |
Backend updates payment status and stock safely
  |
Flutter reads refreshed transaction status
  |
Show result
Aturan penting:
- Jangan tandai pembayaran sukses dari query parameter redirect.
- Jangan kurangi stok dari Flutter.
- Backend memverifikasi webhook dan mencegah event diproses dua kali.
- Kebijakan reservasi stok saat status pending masih TBD dan harus diputuskan sebelum implementasi final.
- Jika payment request gagal, tampilkan status yang konsisten dan jangan menampilkan instruksi pembayaran yang tidak valid.
6. Payment Status UI Flow
Transaction created
   |
Status = pending
   |
Wait / refresh transaction status
   |
   +-- paid --> Success state
   |
   +-- failed --> Failed state
   |
   +-- expired --> Expired state
   |
   +-- still pending --> Pending state
Status diambil dari backend/database setelah proses verifikasi provider. Sediakan batas waktu polling yang wajar jika polling digunakan; jangan melakukan request tanpa henti.
7. Error and Recovery Flows
Network error
- Tampilkan pesan bahwa request belum berhasil.
- Sediakan aksi coba lagi.
- Jangan menganggap operasi gagal atau sukses jika hasil server belum diketahui; cek status transaksi sebelum mengulangi checkout.
Checkout timeout
- Hindari membuat transaksi kedua secara otomatis.
- Gunakan idempotency key jika dirancang pada API.
- Periksa transaksi sebelumnya sebelum mengulang proses.
Insufficient stock
- Tampilkan produk yang stoknya tidak mencukupi.
- Minta kasir memperbarui keranjang.
- Jangan melanjutkan checkout dengan kuantitas yang tidak valid.
Session expired
- Hentikan operasi privat.
- Arahkan pengguna login kembali.
- Jangan menyimpan token secara manual di tempat yang tidak aman.
Payment provider error
- Tampilkan pesan bahwa pembayaran belum dapat dimulai atau status belum dapat dipastikan.
- Jangan menampilkan status berhasil.
- Sediakan cara memeriksa status transaksi jika transaksi sudah dibuat.
8. Navigation Flow by Role
Admin
Admin Dashboard
  ├── Products
  │     ├── Add Product
  │     └── Edit Product
  ├── Categories (if enabled)
  ├── Transactions (if permitted)
  └── Profile
        └── Logout
Cashier
Cashier Catalog
  ├── Cart
  │     └── Checkout
  │           └── Payment Status
  ├── Transaction History (if permitted)
  │     └── Transaction Detail
  └── Profile
        └── Logout
9. Interaction Rules
- Setiap aksi asynchronous memiliki loading, success, dan error handling yang sesuai.
- Disable tombol submit ketika request yang sama sedang berjalan.
- Berikan feedback setelah aksi penting.
- Hindari dialog bertumpuk.
- Pertahankan input pengguna ketika validasi/server gagal, selama aman.
- Konfirmasi untuk aksi destruktif dan checkout.
- Jangan tampilkan status pembayaran yang belum diverifikasi.
- UI tidak boleh menjadi satu-satunya lapisan validasi keamanan.
10. Acceptance Checklist
- [ ] Pengguna diarahkan ke area sesuai role setelah login.
- [ ] Pengguna tidak dapat membuka area role lain melalui navigasi langsung.
- [ ] Admin dapat menjalankan alur CRUD produk.
- [ ] Kasir dapat mencari produk dan mengelola keranjang.
- [ ] Keranjang kosong tidak dapat checkout.
- [ ] Checkout mengirim item ID dan quantity.
- [ ] Aplikasi menangani pending, paid, failed, dan expired.
- [ ] Redirect pembayaran tidak langsung dianggap sukses.
- [ ] Error jaringan dan timeout memiliki alur pemulihan.
- [ ] Request ganda tidak membuat transaksi atau pengurangan stok ganda.