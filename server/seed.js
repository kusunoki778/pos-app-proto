/**
 * Seed data awal untuk project pelatihanpos.
 *
 * Membuat:
 *  - akun admin dan kasir di Firebase Auth + dokumen users/{uid}
 *  - kategori contoh
 *  - produk contoh
 *
 * Pakai service account: server/serviceAccountKey.json (jangan di-commit).
 *
 * Pemakaian:
 *   ADMIN_EMAIL=admin@pos.test ADMIN_PASSWORD=rahasia123 \
 *   KASIR_EMAIL=kasir@pos.test KASIR_PASSWORD=rahasia123 \
 *   node server/seed.js
 *
 * Script aman dijalankan ulang: akun yang sudah ada dilewati,
 * kategori/produk dibuat hanya kalau belum ada (berdasar nama).
 */
const path = require("path");
const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
const adminSdk = admin.initializeApp({
  // firebase-admin 14: credential cert ada di root, bukan admin.credential.
  credential: admin.cert(require(serviceAccountPath)),
});

const db = getFirestore(adminSdk);
const auth = getAuth(adminSdk);
const now = () => FieldValue.serverTimestamp();

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@pos.test";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "admin123456";
const KASIR_EMAIL = process.env.KASIR_EMAIL || "kasir@pos.test";
const KASIR_PASSWORD = process.env.KASIR_PASSWORD || "kasir123456";

const CATEGORIES = [
  { id: "cat_makanan", name: "Makanan", description: "Makanan ringan dan berat" },
  { id: "cat_minuman", name: "Minuman", description: "Minuman dingin dan panas" },
  { id: "cat_snack", name: "Snack", description: "Camilan" },
];

const PRODUCTS = [
  { name: "Nasi Ayam Geprek", description: "Nasi + ayam geprek sambal bawang", categoryId: "cat_makanan", price: 18000, stock: 25 },
  { name: "Mie Goreng Spesial", description: "Mie goreng telur + acar", categoryId: "cat_makanan", price: 15000, stock: 20 },
  { name: "Roti Bakar Cokelat", description: "Roti bakar mentega cokelat", categoryId: "cat_makanan", price: 12000, stock: 15 },
  { name: "Es Teh Manis", description: "Teh tawar + gula, gelas 300ml", categoryId: "cat_minuman", price: 5000, stock: 60 },
  { name: "Kopi Susu Gula Aren", description: "Es kopi susu aren 250ml", categoryId: "cat_minuman", price: 13000, stock: 40 },
  { name: "Air Mineral 600ml", description: "Botol air mineral", categoryId: "cat_minuman", price: 4000, stock: 80 },
  { name: "Keripik Kentang", description: "Keripik kemasan 80gr", categoryId: "cat_snack", price: 9000, stock: 30 },
  { name: "Wafer Cokelat", description: "Wafer isi 5", categoryId: "cat_snack", price: 2500, stock: 50 },
];

async function ensureAuthUser(email, password, name, role) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log(`= Akun sudah ada: ${email} (${user.uid})`);
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
    user = await auth.createUser({ email, password, displayName: name });
    console.log(`+ Akun dibuat: ${email} (${user.uid})`);
  }

  const ts = now();
  await db.collection("users").doc(user.uid).set(
    {
      uid: user.uid,
      name,
      email,
      role, // "admin" | "cashier"
      isActive: true,
      createdAt: ts,
      updatedAt: ts,
    },
    { merge: true }
  );
  console.log(`+ Dokumen users/${user.uid} (role: ${role})`);
  return user.uid;
}

async function ensureCategory(category) {
  const ref = db.collection("categories").doc(category.id);
  const snap = await ref.get();
  if (snap.exists) {
    console.log(`= Kategori sudah ada: ${category.name}`);
    return;
  }
  const ts = now();
  await ref.set({
    name: category.name,
    description: category.description ?? null,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  });
  console.log(`+ Kategori: ${category.name}`);
}

async function ensureProduct(product) {
  const query = await db
    .collection("products")
    .where("name", "==", product.name)
    .limit(1)
    .get();
  if (!query.empty) {
    console.log(`= Produk sudah ada: ${product.name}`);
    return;
  }
  const ts = now();
  await db.collection("products").add({
    name: product.name,
    description: product.description ?? null,
    categoryId: product.categoryId,
    price: product.price,
    stock: product.stock,
    imageUrl: null,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  });
  console.log(`+ Produk: ${product.name} (Rp${product.price}, stok ${product.stock})`);
}

(async () => {
  try {
    console.log("Seed dimulai...");
    await ensureAuthUser(ADMIN_EMAIL, ADMIN_PASSWORD, "Admin Toko", "admin");
    await ensureAuthUser(KASIR_EMAIL, KASIR_PASSWORD, "Kasir Satu", "cashier");
    for (const category of CATEGORIES) await ensureCategory(category);
    for (const product of PRODUCTS) await ensureProduct(product);
    console.log("Seed selesai.");
    process.exit(0);
  } catch (err) {
    console.error("Seed gagal:", err);
    process.exit(1);
  }
})();


