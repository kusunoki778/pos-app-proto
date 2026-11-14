# ROADMAP — Aplikasi POS Sederhana (Flutter)

| | |
|---|---|
| **Proyek** | `realtime_communication/` (POS Flutter) |
| **Referensi PRD** | `PRD_POS_Flutter.md` + 6 dokumen teknis |
| **Update terakhir** | 14 November 2026 |

> Checklist ini adalah sumber kebenaran progres. Update tiap kali 1 tahap selesai.

---

## Status Cepat

| Tahap | Nama | Status |
|---|---|---|
| 1 | Setup & Environment | ✅ 100% |
| 2 | Firebase Init + Models | ✅ 100% |
| 3 | Auth + Role (Login) | ⏳ 90% (menunggu uji login di HP) |
| 4 | Dashboard Admin (CRUD Produk) | ⏳ 80% (dashboard ringkasan belum) |
| 5 | Katalog + Keranjang Kasir | ✅ 100% |
| 6 | Checkout + Transaksi Firestore | ✅ 90% (versi tunai; MiomiPay menyusul Tahap 7-8) |
| 7 | Backend Express (validasi + MiomiPay) | ⏳ 60% (server notifikasi FCM jadi; validasi checkout + MiomiPay belum) |
| 8 | Webhook + Verifikasi Pembayaran | ❌ Belum |
| 9 | Stok Konsisten + Security Rules | ⏳ 70% (stok atomik jadi; uji rules belum) |
| 10 | Testing Android & Web | ❌ Belum |
| 11 | UI Polish + Dokumentasi | ❌ Belum |

> Detail progres tiap tahap ada di bawah. Keputusan final soal PRD ada
> di bagian "Deviasi dari PRD".

---

## Tahap 1 — Setup & Environment ✅ 100%

- [x] Flutter 3.38.3 terinstal (Dart 3.10.1) ✅
      Catatan: ada dua SDK. Jalankan `C:\fluttersdk\flutter\bin\flutter.bat`;
      Flutter di `C:\flutter` (3.35.2) tidak cocok dengan `sdk: ^3.10.1`.
- [x] Dependencies Flutter terinstal ✅
  - `firebase_core` 5.1.0, `firebase_auth` 7.0.1, `cloud_firestore` 7.1.0
  - `firebase_messaging` 17.0.1, `flutter_local_notifications` 22.3.3
  - `provider` 6.1.5, `google_fonts` 8.2.1, `http`, `intl` 0.20.3
- [x] `lib/firebase_options.dart` ter-generate ✅ (Android saja,
      project `pelatihanpos`, app ID `22d5422364c9f90c8b031b`)
- [x] `android/app/google-services.json` untuk package `com.pos.myapp` ✅
- [x] Package Android diubah ke `com.pos.myapp` ✅
      (namespace + applicationId + folder `kotlin/com/pos/myapp`)
- [x] Kredensial backend ✅ `server/serviceAccountKey.json`
      (path dipakai: `server/serviceAccountKey.json`, bukan
      `firebase-service-account.json`; sudah masuk `.gitignore`)
- [x] Plugin Google Services ✅ (ditambahkan otomatis oleh FlutterFire CLI)
- [x] `flutter build apk --debug` berhasil ✅ (2 November 2026, build 1)
      Perbaikan yang diperlukan: core library desugaring + Kotlin 2.4.21.
      Build ulang 14 November 2026 setelah Tahap 5-6 (layout kasir, FCM,
      notifikasi lokal) — sukses.
- [x] `flutter analyze` bersih, `flutter test` hijau
      (8 tes formatter + 8 tes CartController) ✅

Sisa pembersihan (tidak menghalangi build):
- [ ] Hapus app Android `com.example.realtime_communication` yang ikut
      terdaftar saat `flutterfire configure` pertama. Di Console:
      Project settings → Your apps. Jangan hapus `com.pos.myapp`.

---

## Tahap 2 — Firebase Init + Models ✅ 100%

- [x] Inisialisasi `Firebase.initializeApp` di `main.dart` ✅
- [x] Folder struktur: `core/`, `models/`, `services/`, `state/`,
      `screens/`, `widgets/` ✅ (keputusan: struktur sekarang, PRD 13.4
      digantikan, lihat Deviasi #5)
- [x] Models ✅ mengikuti `DATABASE_SCHEMA.md`:
      `app_user.dart` (field `isActive`, samakan dengan schema),
      `product_model.dart`, `category_model.dart`,
      `cart_item_model.dart` (lineTotal terhitung otomatis),
      `transaction_model.dart` (transactionNumber, unitPrice,
      lineTotal, paymentStatus, providerReference)
- [x] `theme.dart` ✅ arah "hangat seperti toko", token lengkap di
      `DESIGN_SYSTEM.md`

## Tahap 3 — Auth + Role (Login) ⏳ 90%

- [x] `services/auth_service.dart`: login email/password via Firebase Auth ✅
- [x] Baca profil `users/{uid}` → `role` (admin | cashier) + `isActive` ✅
- [x] `state/auth_controller.dart`: loading / unauthenticated /
      authenticated + pesan error yang bisa dipahami ✅
- [x] Halaman login dengan validasi dan keadaan loading ✅
- [x] Routing per role: AuthGate + NavigationBar
      (admin: Kasir, Produk, Riwayat, Laporan, Pengaturan;
      kasir: Kasir, Riwayat, Pengaturan) ✅
- [x] Logout + pesan bila akun tidak terdaftar/dinonaktifkan ✅
- [x] `server/seed.js` ✅ sudah dijalankan:
      - admin@pos.test / admin123456 (role admin)
      - kasir@pos.test / kasir123456 (role cashier)
      - 3 kategori + 8 produk contoh
- [ ] Uji login asli di HP Android (menunggu sesi testing)

## Tahap 4 — Dashboard Admin (CRUD Produk) ⏳ 80%

- [x] Daftar produk realtime (Firestore Stream) + pencarian ✅
- [x] Form tambah produk (kategori dropdown, nama, harga, stok,
      keterangan, URL gambar, aktif) ✅
- [x] Form edit produk ✅
- [x] Nonaktifkan/aktifkan produk ✅
- [x] Hapus produk dengan dialog konfirmasi + peringatan ✅
- [x] Halaman profil + logout (di menu Pengaturan) ✅
- [ ] Dashboard ringkasan (jumlah produk, transaksi hari ini) ❌
- [ ] Filter per kategori di daftar produk ❌

## Tahap 9 — Stok Konsisten + Security Rules ⏳ 70%

- [x] `firestore.rules` dasar ter-deploy ✅:
      - default tolak
      - users: baca sendiri atau admin, tulis hanya Admin SDK
      - categories/products: baca staff, tulis admin;
        kasir hanya boleh mengurangi stok (tidak bisa menaikkan)
      - transactions: kasir baca miliknya, admin baca semua;
        update pembayaran hanya backend
- [x] Pengurangan stok atomik via Firestore Transaction ✅
      (`TransactionService.checkoutCash`: baca semua produk dulu,
      kurangi stok + simpan transaksi dalam satu transaksi)
- [ ] Aturan dites dengan emulator rules / kasus nyata
- [ ] Kebijakan stok saat checkout pending (menunggu keputusan MiomiPay)

## Tahap 5 — Katalog + Keranjang Kasir ✅ 100%

- [x] Katalog produk kasir (realtime Stream, hanya `isActive = true`) ✅
      (`_CatalogBody` di `cashier_screen.dart`)
- [x] Kategori tab/filter (chip kategori, horizontal scroll) ✅
- [x] Keranjang: tambah item, ubah kuantitas, hapus item ✅
      (`state/cart_controller.dart`)
- [x] Keranjang subtotal & total terhitung otomatis ✅
- [x] Layout responsive: layar ≥900px katalog + panel keranjang
      berdampingan; HP pakai tombol keranjang (bottom sheet) ✅

## Tahap 6 — Checkout + Transaksi Firestore ✅ 90%

- [x] Halaman checkout (ringkasan item + total) ✅ (`checkout_dialog.dart`)
- [x] Pilih metode: tunai / QRIS / debit; chip uang cepat;
      hitung kembalian otomatis ✅
- [x] Simpan transaksi ke Firestore `paid` + kurangi stok atomik ✅
      (pengganti sementara MiomiPay — lihat Deviasi #3)
- [x] Struk ringkas setelah pembayaran sukses ✅
- [x] Halaman Payment Status (status `pending / paid / failed /
      expired` di riwayat + detail) ✅
- [x] Riwayat transaksi: admin semua, kasir hanya miliknya ✅
- [x] Notifikasi FCM saat checkout sukses → server `POST /api/notify`
      → topik `admin-alerts` ✅
- [x] Notifikasi foreground (notifikasi lokal) + tap notifikasi
      membuka detail transaksi (`/transaction/{id}`) ✅
- [x] Layar Pengaturan: status token FCM + tombol "Tes Notifikasi" ✅
- [ ] Kirim checkout ke backend `POST /api/checkout` + Firebase ID Token
      (menunggu Tahap 7)
- [ ] Backend verifikasi token + role + harga (Tahap 7, setelah MiomiPay)

## Tahap 7 — Backend Express (validasi + MiomiPay) ⏳ 60%

- [x] Server Express `server/server.js` ✅:
      `GET /api/health`, `POST /api/notify` (kirim FCM via
      firebase-admin `getMessaging`), `POST /api/notify-test`
- [x] Proteksi endpoint via header `X-API-Key` ✅ (`server/.env.example`)
- [ ] Struktur server: `src/{config,middleware,routes,controllers,services}`
- [ ] Middleware verifikasi Firebase ID Token (firebase-admin)
- [ ] `POST /api/checkout` → validasi → request tagihan ke MiomiPay (`POST /payment/create`)
- [ ] Simpan `payment_attempts` (providerReference, amount, status)
- [ ] `GET /api/transactions/:id/status` untuk polling app
- [ ] Secret key MiomiPay HANYA di server (tidak pernah di Flutter)

## Tahap 8 — Webhook + Verifikasi Pembayaran ❌

- [ ] Endpoint `POST /api/webhook/miomipay` (verifikasi signature sesuai docs resmi)
- [ ] Idempotent: event sama tidak diproses 2x
- [ ] Update `paymentStatus` transaksi: paid / failed / expired
- [ ] Note: webhook ke localhost tak bisa masuk → fallback polling dari app (jaring pengaman)

## Tahap 9 — Stok Konsisten + Security Rules

Progres dan sisa pekerjaan tahap ini ada di bagian atas (dikelompokkan
bersama Tahap 2-4 supaya urutan pengerjaan terbaca). Ringkasannya:
stok berkurang atomik saat checkout `paid`, dan aturan rules dasar
sudah terpasang.

## Tahap 10 — Testing Android ❌

> Web dicabut (Deviasi #2) — hanya uji Android (perangkat asli / emulator).

- [ ] `flutter run` di Android (emulator/device) — alur lengkap: login → CRUD → cart → checkout → paid
- [ ] Test realtime: admin ubah produk → katalog kasir update tanpa refresh
- [ ] Test role: kasir tidak bisa akses halaman/route admin
- [ ] Test pembayaran: pending → paid (sandbox MiomiPay) + stok berkurang benar

## Tahap 11 — UI Polish + Dokumentasi ❌

- [ ] Konsistensi design system (warna, radius, spacing) di semua halaman
- [ ] Empty state, loading state, error state semua halaman
- [ ] Update README (cara setup, jalankan, akun demo admin/kasir)
- [ ] Update ROADMAP.md status akhir

---

## Kriteria Selesai (dari PRD §15)

- [ ] Admin login + CRUD produk (realtime ke Firestore)
- [ ] Kasir login + katalog + keranjang + checkout
- [ ] Redirect otomatis sesuai role
- [ ] Total dihitung benar (divalidasi backend)
- [ ] MiomiPay tagihan dibuat dari backend
- [ ] Status pembayaran diverifikasi (webhook/polling) sebelum `paid`
- [ ] Stok berkurang konsisten setelah paid
- [ ] Jalan di Android & Web
- [ ] Security Rules + backend authorization aktif

---

## Blocker / Dibutuhkan Dari Kamu

| # | Item | Status | Instruksi |
|---|---|---|---|
| 1 | Firebase project + `flutterfire configure` | ✅ Selesai | Project `pelatihanpos`, Android saja |
| 2 | Service account JSON | ✅ Selesai | `server/serviceAccountKey.json`, jangan di-commit |
| 3 | Buat akun demo di Firebase Auth + dokumen `users/{uid}` | ✅ Selesai | `server/seed.js`: admin@pos.test / admin123456, kasir@pos.test / kasir123456 + 3 kategori + 8 produk |
| 4 | MiomiPay sandbox key | ❌ Menunggu | Dibutuhkan sebelum Tahap 7 |
| 5 | Dokumentasi API MiomiPay | ❌ Menunggu | Wajib sebelum Tahap 7-8 (endpoint + signature webhook) |
| 6 | Hapus app Android `com.example.realtime_communication` di Console | ❌ Belum | Project settings → Your apps (opsional, tidak menghalangi) |

---

## Deviasi dari PRD — sudah diputuskan pemilik (14 November 2026)

| # | Topik | Keputusan |
|---|---|---|
| 1 | Tema | **Tema hangat menang.** `DESIGN_SYSTEM.md` sudah diisi, PRD §8.1 dicatat digantikan |
| 2 | Platform | **Android saja.** Web dicabut, dicatat di PRD |
| 3 | Pembayaran | **MiomiPay sesuai PRD.** Checkout tunai hanya sementara sampai dokumen API MiomiPay diberikan. Tahap 6 sementara menyimpan transaksi `paid` tunai agar Tahap 9-11 bisa jalan, lalu Tahap 7-8 menyusul |
| 4 | Routing | **Tanpa GoRouter untuk saat ini.** AuthGate + NavigationBar cukup; GoRouter hanya kalau deep-link notifikasi butuh nama route |
| 5 | Struktur folder | **Struktur sekarang menang** (`screens/`, `state/`, `services/`). PRD §13.4 dicatat digantikan |
| 6 | Notifikasi | **FCM jadi fitur inti** (dicatat di PRD). Koleksi `device_tokens` ditambahkan ke schema saat Tahap 6 |
| 7 | Nama field user | **Samakan ke `isActive`** pada saat membuat seed dan Security Rules (schema/PRD menang) |
