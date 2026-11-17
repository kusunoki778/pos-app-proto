# ROADMAP — Aplikasi POS Sederhana (Flutter)

| | |
|---|---|
| **Proyek** | `realtime_communication/` (POS Flutter) |
| **Referensi PRD** | `PRD_POS_Flutter.md` + 6 dokumen teknis |
| **Update terakhir** | 15 November 2026 |

> Checklist ini adalah sumber kebenaran progres. Update tiap kali 1 tahap selesai.

---

## Status Cepat

| Tahap | Nama | Status |
|---|---|---|
| 1 | Setup & Environment | ✅ 100% |
| 2 | Firebase Init + Models | ✅ 100% |
| 3 | Auth + Role (Login) | ⏳ 90% (menunggu uji login di HP) |
| 4 | Dashboard Admin (CRUD Produk) | ✅ 100% (CRUD + dashboard ringkasan + filter kategori) |
| 5 | Katalog + Keranjang Kasir | ✅ 100% |
| 6 | Checkout + Transaksi Firestore | ✅ 100% (tunai + QRIS via MiomiPay) |
| 7 | Backend Express (validasi + MiomiPay) | ✅ 95% (semua endpoint jadi; struktur folder src/ opsional) |
| 8 | Webhook + Verifikasi Pembayaran | ✅ 100% (webhook + polling fallback di app) |
| 9 | Stok Konsisten + Security Rules | ⏳ 70% (stok atomik jadi; uji rules belum) |
| 10 | Testing Android & Web | ❌ Belum |
| 11 | UI Polish + Dokumentasi | ⏳ 80% (README + design system ✅; status akhir tunggu Tahap 10) |

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

## Tahap 4 — Dashboard Admin (CRUD Produk) ✅ 100%

- [x] Daftar produk realtime (Firestore Stream) + pencarian ✅
- [x] Form tambah produk (kategori dropdown, nama, harga, stok,
      keterangan, URL gambar, aktif) ✅
- [x] Form edit produk ✅
- [x] Nonaktifkan/aktifkan produk ✅
- [x] Hapus produk dengan dialog konfirmasi + peringatan ✅
- [x] Halaman profil + logout (di menu Pengaturan) ✅
- [x] Dashboard ringkasan (omzet/transaksi/item hari ini, 5 transaksi
      terakhir, stok kritis < 5) ✅ 15 Nov 2026
- [x] Filter per kategori di daftar produk ✅

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
- [x] Kebijakan stok saat checkout pending ✅ (diputuskan: stok berkurang
      HANYA saat webhook PAID; stok kurang saat dibayar → transaksi
      `failed`, tidak pernah stok minus)

## Tahap 5 — Katalog + Keranjang Kasir ✅ 100%

- [x] Katalog produk kasir (realtime Stream, hanya `isActive = true`) ✅
      (`_CatalogBody` di `cashier_screen.dart`)
- [x] Kategori tab/filter (chip kategori, horizontal scroll) ✅
- [x] Keranjang: tambah item, ubah kuantitas, hapus item ✅
      (`state/cart_controller.dart`)
- [x] Keranjang subtotal & total terhitung otomatis ✅
- [x] Layout responsive: layar ≥900px katalog + panel keranjang
      berdampingan; HP pakai tombol keranjang (bottom sheet) ✅

## Tahap 6 — Checkout + Transaksi Firestore ✅ 100%

- [x] Halaman checkout (ringkasan item + total) ✅ (`checkout_dialog.dart`)
- [x] Pilih metode: tunai / QRIS (debit ditiadakan karena MiomiPay
      hanya QRIS); chip uang cepat; hitung kembalian otomatis ✅
- [x] Simpan transaksi ke Firestore `paid` + kurangi stok atomik ✅
      (tunai: langsung dari app; QRIS: stok berkurang saat webhook PAID)
- [x] Struk ringkas setelah pembayaran sukses ✅
- [x] Halaman Payment Status (status `pending / paid / failed /
      expired` di riwayat + detail) ✅
- [x] Riwayat transaksi: admin semua, kasir hanya miliknya ✅
- [x] Notifikasi FCM saat checkout sukses → server `POST /api/notify`
      → topik `admin-alerts` ✅
- [x] Notifikasi foreground (notifikasi lokal) + tap notifikasi
      membuka detail transaksi (`/transaction/{id}`) ✅
- [x] Layar Pengaturan: status token FCM + tombol "Tes Notifikasi" ✅
- [x] Kirim checkout ke backend `POST /api/checkout` + Firebase ID Token ✅
      (tunai tetap via Firestore dari app; QRIS via server)
- [x] Backend verifikasi token + role + harga ✅ (server re-read harga &
      stok dari Firestore — tidak percaya data dari klien)

## Tahap 7 — Backend Express (validasi + MiomiPay) ✅ 95%

- [x] Server Express `server/server.js` ✅:
      `GET /api/health`, `POST /api/notify` (kirim FCM via
      firebase-admin `getMessaging`), `POST /api/notify-test`
- [x] Proteksi endpoint via header `X-API-Key` ✅ (`server/.env.example`)
- [ ] Struktur server: `src/{config,middleware,routes,controllers,services}`
      (satu file masih mudah dikelola; opsional)
- [x] Middleware verifikasi Firebase ID Token (firebase-admin
      `verifyIdToken` + cek role/isActive di dokumen `users`) ✅
- [x] `POST /api/checkout` → validasi → request tagihan ke MiomiPay
      (`POST /payment/create`) ✅ — checkout tunai tetap di Firestore
      dari app; QRIS lewat server
- [x] Simpan `payment_attempts` (providerReference, amount, status) ✅
- [x] `GET /api/transactions/:id/status` untuk polling app ✅
- [x] Secret key MiomiPay HANYA di server (tidak pernah di Flutter) ✅
      (env `MIOMIPAY_API_KEY`, app hanya pakai Firebase ID Token)

## Tahap 8 — Webhook + Verifikasi Pembayaran ✅ 100%

- [x] Endpoint `POST /api/webhook/miomipay` (verifikasi signature
      HMAC-SHA256 `timingSafeEqual` sesuai docs resmi) ✅
- [x] Idempotent: event sama tidak diproses 2x (koleksi `webhook_events`) ✅
- [x] Update `paymentStatus` transaksi: paid / failed / expired ✅
      (PAID → kurangi stok atomik Admin SDK; stok kurang → `failed`)
- [x] Note: webhook ke localhost tak bisa masuk → fallback polling dari
      app (jaring pengaman) ✅ — `QrisPaymentScreen` polling 3 detik

## Tahap 9 — Stok Konsisten + Security Rules

Progres dan sisa pekerjaan tahap ini ada di bagian atas (dikelompokkan
bersama Tahap 2-4 supaya urutan pengerjaan terbaca). Ringkasannya:
stok berkurang atomik saat checkout `paid`, dan aturan rules dasar
sudah terpasang.

## Tahap 10 — Testing Android & Web (uji lokal) ❌

> Deliverable = Android (penugasan Mobile Apps). Web hanya **alat uji
> lokal** di Chrome (`flutter run -d chrome`) untuk mempercepat QA tanpa
> HP. Build web sudah sukses (15 Nov 2026).

- [ ] `flutter run` di Chrome — alur lengkap: login → CRUD → cart → checkout → paid
- [ ] `flutter run` di Android (emulator/device) — alur lengkap: login → CRUD → cart → checkout → paid
- [ ] Test realtime: admin ubah produk → katalog kasir update tanpa refresh
- [ ] Test role: kasir tidak bisa akses halaman/route admin
- [ ] Test pembayaran: pending → paid (sandbox MiomiPay) + stok berkurang benar

## Tahap 11 — UI Polish + Dokumentasi ⏳

- [x] Konsistensi design system (warna, radius, spacing) di semua halaman ✅
      (theme.dart tunggal, semua layar pakai colorScheme/textTheme)
- [x] Empty state, loading state, error state semua halaman ✅
      (widgets/common.dart: EmptyState, LoadingView)
- [x] Update README (cara setup, jalankan, akun demo admin/kasir) ✅ 15 Nov 2026
- [ ] Update ROADMAP.md status akhir (setelah Tahap 10)

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
| 4 | MiomiPay sandbox key | ✅ Selesai | `MP-SB-xMmS…` (15 Nov 2026), dipakai server via env `MIOMIPAY_API_KEY` |
| 5 | Dokumentasi API MiomiPay | ✅ Selesai | https://pg.miomidev.com/docs; webhook secret `whsec_…` di env `MIOMIPAY_WEBHOOK_SECRET` |
| 6 | Hapus app Android `com.example.realtime_communication` di Console | ❌ Belum | Project settings → Your apps (opsional, tidak menghalangi) |
| 7 | VAPID key untuk notifikasi web | ✅ Selesai | Key pair sudah dibuat, public key terpasang di `lib/config.dart` (`webVapidKey`) |

---

## Deviasi dari PRD — sudah diputuskan pemilik (14 November 2026)

| # | Topik | Keputusan |
|---|---|---|
| 1 | Tema | **Tema hangat menang.** `DESIGN_SYSTEM.md` sudah diisi, PRD §8.1 dicatat digantikan |
| 2 | Platform | **Android sebagai deliverable utama** (sesuai penugasan Mobile Apps). Web ditambahkan lagi **15 Nov 2026 sebagai alat uji lokal di Chrome** — bukan target rilis. Config web `1:1011542709250:web:26bae3dd13b144cf8b031b` + service worker `web/firebase-messaging-sw.js` |
| 3 | Pembayaran | **MiomiPay sesuai PRD — terpasang (15 Nov 2026).** Sandbox `MP-SB-xMmS…` di server (`pg.miomidev.com/api/v1`), tagihan QRIS dibuat backend, webhook HMAC + polling app. Checkout tunai tetap tersedia; stok berkurang hanya saat webhook PAID (stok kurang → transaksi `failed`) |
| 4 | Routing | **Tanpa GoRouter untuk saat ini.** AuthGate + NavigationBar cukup; GoRouter hanya kalau deep-link notifikasi butuh nama route |
| 5 | Struktur folder | **Struktur sekarang menang** (`screens/`, `state/`, `services/`). PRD §13.4 dicatat digantikan |
| 6 | Notifikasi | **FCM jadi fitur inti** (dicatat di PRD). Koleksi `device_tokens` ditambahkan ke schema saat Tahap 6 |
| 7 | Nama field user | **Samakan ke `isActive`** pada saat membuat seed dan Security Rules (schema/PRD menang) |
