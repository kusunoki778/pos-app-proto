UI Screen Specification
Dokumen ini merinci halaman dan elemen UI yang diperlukan untuk aplikasi POS Flutter. Rancangan berfokus pada kebutuhan Admin dan Kasir. Detail visual mengikuti DESIGN_SYSTEM.md.
1. Ruang Lingkup
Platform target:
- Android.
- Web/responsive layout bila termasuk target build project.
Role:
- Admin.
- Kasir.
Fitur inti:
- Login.
- Dashboard sesuai role.
- Admin mengelola produk/menu.
- Kasir melihat katalog.
- Kasir mengelola keranjang.
- Kasir checkout dan melihat status pembayaran.
- Riwayat/detail transaksi sesuai hak akses yang ditetapkan.
2. Global UI Requirements
Setiap halaman harus:
- Menampilkan loading state saat mengambil data.
- Menampilkan empty state ketika data kosong.
- Menampilkan error state yang dapat dipahami.
- Menangani sesi login yang berakhir.
- Tidak menampilkan menu yang tidak relevan dengan role.
- Tetap memvalidasi izin di backend/database; menyembunyikan menu bukan kontrol keamanan.
Komponen global:
- App navigation.
- Page title/header.
- User profile/logout entry.
- Confirmation dialog.
- Snackbar/toast untuk hasil operasi.
- Loading indicator.
- Empty/error state.
3. Screen Inventory
ID	Halaman	Role	Prioritas
AUTH-01	Login	Admin, Kasir	Must
ADM-01	Dashboard Admin	Admin	Should
ADM-02	Daftar Produk	Admin	Must
ADM-03	Tambah/Edit Produk	Admin	Must
ADM-04	Daftar Kategori	Admin	Should, jika kategori dipakai
CAS-01	Halaman Kasir/Katalog	Kasir	Must
CAS-02	Keranjang	Kasir	Must
CAS-03	Checkout/Pembayaran	Kasir	Must
CAS-04	Hasil/Status Pembayaran	Kasir	Must
TRX-01	Riwayat Transaksi	Sesuai hak akses	Should
TRX-02	Detail Transaksi	Sesuai hak akses	Should
PROF-01	Profil/Logout	Admin, Kasir	Should


4. Screen Specifications
AUTH-01 — Login
Tujuan: mengautentikasi Admin atau Kasir.

Elemen:
- Logo/nama aplikasi.
- Input email.
- Input password dengan opsi tampil/sembunyikan.
- Tombol Login.
- Pesan validasi dan error autentikasi.
- Loading state saat proses login.
Perilaku:
- Validasi input dasar sebelum request.
- Gunakan Firebase Authentication.
- Setelah login, ambil profil dan role dari sumber data tepercaya.
- Arahkan ke halaman sesuai role.
- Jika akun tidak aktif atau role tidak valid, jangan masuk ke area aplikasi.
Tidak termasuk kecuali diminta:
- Registrasi publik.
- Lupa password.
- Login sosial.
ADM-01 — Dashboard Admin
Tujuan: memberikan ringkasan dan akses cepat ke pengelolaan.

Elemen yang disarankan:
- Sapaan/nama admin.
- Ringkasan jumlah produk aktif.
- Ringkasan jumlah transaksi jika tersedia.
- Shortcut ke Produk dan Kategori.
- Ringkasan transaksi terbaru jika hak akses dan data tersedia.
Catatan:
- Jangan menampilkan angka statistik palsu atau hardcoded sebagai data nyata.
- Jika statistik belum diimplementasikan, tampilkan shortcut fitur inti terlebih dahulu.
ADM-02 — Daftar Produk
Tujuan: melihat dan mengelola daftar produk/menu.

Elemen:
- Judul halaman.
- Search produk.
- Filter kategori/status jika tersedia.
- Tombol Tambah Produk.
- Daftar produk atau tabel responsif.
- Setiap item menampilkan nama, harga, kategori, stok, status, dan aksi.
Perilaku:
- Admin dapat membuka form edit.
- Admin dapat menonaktifkan/menghapus produk dengan konfirmasi.
- Tampilkan loading, empty, dan error state.
- Perubahan data harus tersinkron dengan database.
ADM-03 — Tambah/Edit Produk
Tujuan: membuat atau memperbarui produk.

Field:
- Nama produk (wajib).
- Deskripsi (opsional).
- Kategori (sesuai aturan kategori).
- Harga (wajib, angka nonnegatif).
- Stok (wajib jika stok digunakan).
- URL gambar (opsional jika upload gambar belum tersedia).
- Status aktif/nonaktif pada mode edit bila diizinkan.
Perilaku:
- Validasi field dan format angka.
- Tombol Simpan memiliki loading state.
- Cegah submit ganda.
- Tampilkan error validasi dari backend dengan jelas.
- Kembali ke daftar setelah sukses.
ADM-04 — Daftar Kategori
Tujuan: mengelola kategori produk jika fitur kategori digunakan.

Elemen:
- Daftar nama kategori.
- Status aktif/nonaktif.
- Aksi tambah/edit/nonaktifkan.
- Form kategori dengan nama dan deskripsi.
Perilaku:
- Kategori yang masih dipakai produk sebaiknya dinonaktifkan, bukan dihapus permanen.
- Validasi nama kategori.
- Tampilkan konfirmasi sebelum menonaktifkan.
CAS-01 — Halaman Kasir/Katalog
Tujuan: membantu kasir menemukan produk dan menambahkannya ke keranjang.

Elemen:
- Search produk.
- Filter kategori jika tersedia.
- Grid/list produk.
- Nama produk.
- Harga.
- Gambar bila tersedia.
- Informasi stok atau label habis.
- Tombol tambah produk.
- Ringkasan jumlah item dan total sementara keranjang.
Perilaku:
- Hanya produk aktif yang dapat ditambahkan.
- Produk dengan stok tidak mencukupi tidak dapat ditambahkan melebihi stok.
- Update katalog dapat menggunakan Firestore Streams.
- Total sementara merupakan informasi UI; backend menghitung ulang saat checkout.
Responsive:
- Android: grid satu atau dua kolom sesuai lebar.
- Web: katalog dapat menggunakan grid dan panel keranjang di sisi kanan.
CAS-02 — Keranjang
Tujuan: memeriksa item sebelum checkout.

Elemen:
- Daftar item.
- Nama produk dan harga satuan.
- Kontrol tambah/kurangi kuantitas.
- Hapus item.
- Subtotal.
- Total sementara.
- Tombol Lanjut Checkout.
Perilaku:
- Kuantitas minimal satu; jika menjadi nol, item dihapus atau minta konfirmasi sesuai pola UI.
- Tampilkan peringatan jika stok berubah dan jumlah keranjang tidak lagi tersedia.
- Keranjang kosong menampilkan empty state.
- Jangan menganggap harga/total dari state keranjang sebagai nilai final.
CAS-03 — Checkout/Pembayaran
Tujuan: mengonfirmasi transaksi dan memulai pembayaran.

Elemen:
- Ringkasan item.
- Subtotal dan total.
- Metode pembayaran yang tersedia.
- Tombol Buat Pembayaran/Proses Pembayaran.
- Informasi bahwa pembayaran diproses melalui MiomiPay.
Perilaku:
- Minta konfirmasi sebelum membuat transaksi.
- Kirim product ID dan quantity ke backend.
- Backend menghitung ulang harga, stok, dan total.
- Tampilkan loading state dan cegah request ganda.
- Jika backend/provider gagal, tampilkan pesan dan status yang jelas.
CAS-04 — Hasil/Status Pembayaran
Tujuan: menampilkan status pembayaran dari data yang sudah diverifikasi backend.

Status yang mungkin:
- Menunggu pembayaran.
- Berhasil.
- Gagal.
- Kedaluwarsa.
- Dibatalkan, jika didukung.
Elemen:
- Status dengan label dan ikon.
- Nomor transaksi.
- Total pembayaran.
- Instruksi atau tautan pembayaran jika diberikan MiomiPay.
- Tombol cek status/refresh bila diperlukan.
- Tombol kembali ke katalog setelah status sesuai.
Perilaku:
- Jangan menganggap redirect kembali ke aplikasi sebagai bukti pembayaran.
- Ambil status terbaru dari backend/database.
- Status paid hanya ditampilkan setelah backend memverifikasi konfirmasi provider.
TRX-01 — Riwayat Transaksi
Tujuan: mencari transaksi sebelumnya sesuai izin role.

Elemen:
- Daftar transaksi.
- Nomor transaksi.
- Tanggal/waktu.
- Total.
- Status pembayaran.
- Filter tanggal/status jika diperlukan.
Perilaku:
- Batasi data sesuai hak akses user.
- Gunakan pagination untuk data banyak.
- Sediakan empty dan error state.
TRX-02 — Detail Transaksi
Tujuan: melihat detail satu transaksi.

Elemen:
- Nomor transaksi.
- Nama kasir bila boleh ditampilkan.
- Daftar item dan kuantitas.
- Harga snapshot.
- Subtotal, diskon, dan total.
- Metode dan status pembayaran.
- Waktu transaksi dan pembayaran bila tersedia.
Perilaku:
- Data riwayat berasal dari snapshot transaksi.
- Jangan mengambil harga produk terbaru untuk menggantikan harga transaksi lama.
PROF-01 — Profil/Logout
Tujuan: menampilkan informasi akun dan mengakhiri sesi.

Elemen:
- Nama pengguna.
- Email.
- Role.
- Tombol Logout.
Perilaku:
- Konfirmasi logout bila diperlukan.
- Hapus sesi lokal melalui Firebase Auth sign out.
- Kembali ke halaman login.
5. Responsive Layout Rules
Android
- Navigasi ringkas.
- Form satu kolom.
- Tombol aksi utama mudah dijangkau.
- Katalog memakai grid/list yang nyaman untuk layar sentuh.
- Checkout dan status pembayaran harus jelas tanpa perlu scroll berlebihan.
Web
- Gunakan sidebar/navigation rail untuk menu utama bila sesuai.
- Gunakan area konten terpusat.
- Halaman kasir dapat menggunakan split layout katalog + keranjang.
- Daftar admin dapat menggunakan tabel dengan kolom yang tidak terlalu padat.
- Tetap dukung lebar viewport yang lebih kecil.
6. Screen Acceptance Checklist
- [ ] Login berhasil mengarahkan user berdasarkan role.
- [ ] Admin dapat mengakses halaman pengelolaan produk.
- [ ] Kasir tidak melihat menu admin.
- [ ] Form produk memvalidasi input.
- [ ] Katalog hanya menawarkan produk yang dapat dijual.
- [ ] Keranjang dapat menambah, mengurangi, dan menghapus item.
- [ ] Checkout mengirim product ID dan quantity, bukan total tepercaya.
- [ ] Status pembayaran berasal dari backend.
- [ ] Loading, empty, dan error states tersedia.
- [ ] Layout tidak overflow pada ukuran Android dan Web yang didukung.