/**
 * Script cepat untuk memperbarui field imageUrl seluruh produk
 * yang ada di koleksi Firestore agar terisi gambar CDN berkualitas tinggi.
 *
 * Jalankan:
 *   node server/update-product-images.js
 */
const path = require("path");
const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
const app = admin.initializeApp({
  credential: admin.cert(require(serviceAccountPath)),
});

const db = getFirestore(app);

const CDN_MAPPING = {
  "nasi ayam geprek": "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80",
  "mie goreng spesial": "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&q=80",
  "roti bakar cokelat": "https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=500&q=80",
  "es teh manis": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80",
  "kopi susu gula aren": "https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=500&q=80",
  "air mineral 600ml": "https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500&q=80",
  "keripik kentang": "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500&q=80",
  "wafer cokelat": "https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=500&q=80",
};

(async () => {
  try {
    console.log("Memeriksa koleksi produk di Firestore...");
    const snap = await db.collection("products").get();
    console.log(`Ditemukan ${snap.size} produk.`);

    let updatedCount = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const nameKey = (data.name || "").toLowerCase().trim();

      let targetUrl = data.imageUrl;
      for (const [key, url] of Object.entries(CDN_MAPPING)) {
        if (nameKey.includes(key) || key.includes(nameKey)) {
          targetUrl = url;
          break;
        }
      }

      if (targetUrl && targetUrl !== data.imageUrl) {
        await doc.ref.update({
          imageUrl: targetUrl,
          updatedAt: FieldValue.serverTimestamp(),
        });
        console.log(`[OK] Diperbarui: "${data.name}" -> ${targetUrl}`);
        updatedCount++;
      } else {
        console.log(`[-] Dilewati: "${data.name}" (imageUrl: ${data.imageUrl ? "sudah ada" : "tidak cocok"})`);
      }
    }

    console.log(`\nSelesai! Berhasil memperbarui ${updatedCount} produk di database Firestore.`);
    process.exit(0);
  } catch (err) {
    console.error("Gagal memperbarui produk:", err);
    process.exit(1);
  }
})();
