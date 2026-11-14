/**
 * Server Kasir Toko: menerima permintaan dari aplikasi Flutter,
 * lalu mengirim notifikasi FCM ke topik admin-alerts.
 *
 * Jalankan:  node server.js
 * Wajib: file serviceAccountKey.json di folder ini.
 */
const express = require("express");
const cors = require("cors");
const { cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: cert(serviceAccount),
});

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
// Kunci sederhana agar endpoint tidak dipanggil sembarangan.
// Aplikasi mengirim via header X-API-Key (dart-define API_KEY).
const API_KEY = process.env.API_KEY || "kasir-toko-dev-key";

function checkKey(req, res, next) {
  const key = req.get("X-API-Key");
  if (key !== API_KEY) {
    res.status(401).json({ error: "API key tidak valid" });
    return;
  }
  next();
}

/**
 * Kirim ke topik admin-alerts. Fallback: bila data transaksi
 * menyebut perangkat tertentu, kirim ke token tersebut.
 */
async function sendSaleNotification(transactionId) {
  const db = getFirestore();
  let title = "Transaksi baru";
  let body = "Ada transaksi baru di toko.";
  try {
    const snap = await db.collection("transactions").doc(transactionId).get();
    if (snap.exists) {
      const data = snap.data();
      const items = Array.isArray(data.items) ? data.items.length : 0;
      title = `Transaksi baru ${data.transactionNumber || ""}`.trim();
      body = `${data.cashierName || "Kasir"} mencatat ${items} item, ` +
        `total Rp${(data.total ?? 0).toLocaleString("id-ID")}`;
    }
  } catch (err) {
    console.warn("Gagal membaca transaksi, pakai teks default:", err.message);
  }

  const message = {
    topic: "admin-alerts",
    notification: { title, body },
    data: { type: "sale", transactionId },
    android: { priority: "high" },
  };

  const response = await getMessaging().send(message, true);
  return response;
}

// Kesehatan server, dipakai aplikasi untuk status koneksi di Pengaturan.
app.get("/api/health", (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

// Notifikasi transaksi baru (dipanggil saat checkout sukses).
app.post("/api/notify", checkKey, async (req, res) => {
  const { transactionId } = req.body || {};
  if (!transactionId || typeof transactionId !== "string") {
    res.status(400).json({ error: "transactionId wajib diisi" });
    return;
  }
  try {
    const messageId = await sendSaleNotification(transactionId);
    res.json({ ok: true, messageId });
  } catch (err) {
    console.error("Gagal kirim notifikasi:", err);
    res.status(500).json({ error: err.message });
  }
});

// Tombol "Tes Notifikasi" di layar Pengaturan.
app.post("/api/notify-test", checkKey, async (req, res) => {
  try {
    const messageId = await getMessaging().send({
      topic: "admin-alerts",
      notification: {
        title: "Tes notifikasi",
        body: "Server terhubung, FCM berfungsi.",
      },
      android: { priority: "high" },
    });
    res.json({ ok: true, messageId });
  } catch (err) {
    console.error("Gagal kirim tes:", err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server notifikasi berjalan pada port ${PORT}`);
});
