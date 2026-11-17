/**
 * Server Kasir Toko: Express + firebase-admin (FCM + Firestore Admin)
 * + MiomiPay sebagai payment gateway QRIS.
 *
 * Jalankan:  node server.js
 * Wajib: file serviceAccountKey.json di folder ini.
 *
 * Endpoint:
 *   GET  /api/health                     cek server hidup
 *   POST /api/notify                     kirim notifikasi transaksi (X-API-Key)
 *   POST /api/notify-test                tes notifikasi ke admin-alerts (X-API-Key)
 *   POST /api/checkout                   buat tagihan MiomiPay (Bearer ID token)
 *   GET  /api/transactions/:id/status    status pembayaran (Bearer ID token)
 *   POST /api/webhook/miomipay           callback dari MiomiPay (HMAC signature)
 */
const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const admin = require("firebase-admin/app");
const { cert } = admin;
const { getMessaging } = require("firebase-admin/messaging");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: cert(serviceAccount) });

const app = express();
app.use(cors());
app.use(express.json({ verify: (req, res, buf) => { req.rawBody = buf; } }));

const PORT = process.env.PORT || 3000;

// Kunci endpoint utilitas (dipakai aplikasi Flutter via header X-API-Key).
const API_KEY = process.env.API_KEY || "kasir-toko-dev-key";

// Kredensial MiomiPay sandbox. Saat produksi, isi dari environment
// dengan key MP-LIVE- dan webhook secret live.
const MIOMIPAY_BASE_URL =
  process.env.MIOMIPAY_BASE_URL || "https://pg.miomidev.com/api/v1";
const MIOMIPAY_API_KEY =
  process.env.MIOMIPAY_API_KEY || "MP-SB-xMmSCXcLzI7qMJQeJIEAFOUxoVqqvwMp";
const MIOMIPAY_WEBHOOK_SECRET =
  process.env.MIOMIPAY_WEBHOOK_SECRET ||
  "whsec_PTnF5lcOePvJxIGTqmgfJMH0CvhWlfYX";

const db = getFirestore();

function checkKey(req, res, next) {
  const key = req.get("X-API-Key");
  if (key !== API_KEY) {
    res.status(401).json({ error: "API key tidak valid" });
    return;
  }
  next();
}

/**
 * Verifikasi Firebase ID token dari aplikasi, lalu ambil profil user.
 * Menolak akun nonaktif.
 */
async function requireStaff(req, res, next) {
  const header = req.get("Authorization") || "";
  const idToken = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!idToken) {
    res.status(401).json({ error: "ID token wajib dikirim" });
    return;
  }
  try {
    const decoded = await getAuth().verifyIdToken(idToken);
    const profile = await db.collection("users").doc(decoded.uid).get();
    if (!profile.exists) {
      res.status(403).json({ error: "Profil pengguna tidak ditemukan" });
      return;
    }
    const user = profile.data();
    if (!user.isActive) {
      res.status(403).json({ error: "Akun dinonaktifkan" });
      return;
    }
    req.user = { uid: decoded.uid, ...user };
    next();
  } catch (err) {
    res.status(401).json({ error: "ID token tidak valid: " + err.message });
  }
}

// ---------------------------------------------------------------------------
// Notifikasi FCM
// ---------------------------------------------------------------------------

async function sendSaleNotification(transactionId, title, body) {
  const message = {
    topic: "admin-alerts",
    notification: { title, body },
    data: { type: "sale", transactionId },
    android: { priority: "high" },
  };
  return getMessaging().send(message, true);
}

app.get("/api/health", (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

app.post("/api/notify", checkKey, async (req, res) => {
  const { transactionId } = req.body || {};
  if (!transactionId || typeof transactionId !== "string") {
    res.status(400).json({ error: "transactionId wajib diisi" });
    return;
  }
  try {
    const snap = await db.collection("transactions").doc(transactionId).get();
    const data = snap.exists ? snap.data() : {};
    const title = `Transaksi baru ${data.transactionNumber || ""}`.trim();
    const items = Array.isArray(data.items) ? data.items.length : 0;
    const body = `${data.cashierName || "Kasir"} mencatat ${items} item, total Rp${(data.total ?? 0).toLocaleString("id-ID")}`;
    const messageId = await sendSaleNotification(transactionId, title, body);
    res.json({ ok: true, messageId });
  } catch (err) {
    console.error("Gagal kirim notifikasi:", err);
    res.status(500).json({ error: err.message });
  }
});

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

// ---------------------------------------------------------------------------
// Checkout via MiomiPay (QRIS)
// ---------------------------------------------------------------------------

/**
 * Harga dan stok dihitung ulang dari Firestore (BUKAN dari app).
 * Harga: dari dokumen produk. Stok belum dikurangi — baru dikurangi
 * saat webhook PAID, sesuai keputusan kebijakan stok.
 */
async function validateItems(itemInput) {
  if (!Array.isArray(itemInput) || itemInput.length === 0) {
    throw Object.assign(new Error("Keranjang kosong"), { status: 400 });
  }
  const checks = [];
  let subtotal = 0;
  for (const item of itemInput) {
    const quantity = Number(item?.quantity);
    if (!item?.productId || !Number.isInteger(quantity) || quantity < 1) {
      throw Object.assign(new Error("Item tidak valid"), { status: 400 });
    }
    const snap = await db.collection("products").doc(item.productId).get();
    if (!snap.exists) {
      throw Object.assign(new Error(`Produk tidak ditemukan: ${item.productId}`), { status: 400 });
    }
    const product = snap.data();
    if (!product.isActive) {
      throw Object.assign(new Error(`Produk nonaktif: ${product.name}`), { status: 400 });
    }
    if (product.stock < quantity) {
      throw Object.assign(new Error(`Stok ${product.name} tinggal ${product.stock}`), { status: 400 });
    }
    const lineTotal = product.price * quantity;
    subtotal += lineTotal;
    checks.push({ product: { id: snap.id, ...product }, quantity, lineTotal });
  }
  return { checks, subtotal };
}

async function createMiomiPayInvoice({ externalId, amount, user }) {
  const response = await fetch(`${MIOMIPAY_BASE_URL}/payment/create`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${MIOMIPAY_API_KEY}`,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      external_id: externalId,
      amount,
      customer_name: user.name,
      customer_email: user.email ?? null,
      description: "Pembayaran Kasir Toko",
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok || !payload?.data) {
    throw Object.assign(
      new Error(`MiomiPay menolak tagihan: ${payload?.message || response.status}`),
      { status: 502 },
    );
  }
  return payload.data;
}

app.post("/api/checkout", requireStaff, async (req, res) => {
  const user = req.user;
  try {
    const { checks, subtotal } = await validateItems(req.body?.items);

    const externalId = `POS-${Date.now()}-${crypto
      .randomBytes(3)
      .toString("hex")
      .toUpperCase()}`;
    const invoice = await createMiomiPayInvoice({
      externalId,
      amount: subtotal,
      user,
    });

    // Nomor transaksi konsisten dengan format app (tunai).
    const now = new Date();
    const two = (n) => String(n).padStart(2, "0");
    const transactionNumber =
      `POS-${now.getFullYear()}${two(now.getMonth() + 1)}${two(now.getDate())}-` +
      `${two(now.getHours())}${two(now.getMinutes())}${two(now.getSeconds())}`;

    const transactionRef = db.collection("transactions").doc();
    await transactionRef.set({
      transactionNumber,
      cashierId: user.uid,
      cashierName: user.name,
      items: checks.map((c) => ({
        productId: c.product.id,
        productName: c.product.name,
        unitPrice: c.product.price,
        quantity: c.quantity,
        lineTotal: c.lineTotal,
      })),
      subtotal,
      discount: 0,
      total: subtotal,
      currency: "IDR",
      paymentMethod: "qris",
      paymentStatus: "pending",
      transactionStatus: "pending",
      providerReference: invoice.reference,
      paymentUrl: invoice.checkout_url,
      externalId,
      qrImageUrl: invoice.qr_image_url ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      paidAt: null,
    });

    // Jejak upaya pembayaran untuk audit.
    await db.collection("payment_attempts").add({
      transactionId: transactionRef.id,
      reference: invoice.reference,
      invoiceNumber: invoice.invoice_number ?? null,
      externalId,
      amount: subtotal,
      status: "PENDING",
      createdAt: FieldValue.serverTimestamp(),
    });

    res.status(201).json({
      transactionId: transactionRef.id,
      paymentUrl: invoice.checkout_url,
      qrImageUrl: invoice.qr_image_url,
      reference: invoice.reference,
      total: subtotal,
      expiresAt: invoice.expires_at ?? null,
    });
  } catch (err) {
    console.error("Checkout gagal:", err);
    res.status(err.status || 500).json({ error: err.message });
  }
});

/**
 * Status pembayaran untuk polling dari app (webhook tidak bisa
 * menembus localhost — polling ini jaring pengaman sesuai PRD).
 */
/**
 * Tanya langsung ke MiomiPay: tagihan sudah dibayar atau belum.
 * Dipakai polling sebagai fallback karena webhook tidak bisa
 * menembus localhost saat pengujian.
 */
async function fetchMiomiPayStatus(reference) {
  try {
    const response = await fetch(
      `${MIOMIPAY_BASE_URL}/payment/${encodeURIComponent(reference)}/status`,
      {
        headers: {
          Authorization: `Bearer ${MIOMIPAY_API_KEY}`,
          Accept: "application/json",
        },
      },
    );
    const payload = await response.json().catch(() => null);
    if (!response.ok) return null;
    return String(payload?.data?.status || "").toUpperCase();
  } catch (err) {
    console.error("fetchMiomiPayStatus network error:", err.message);
    return null;
  }
}

app.get("/api/transactions/:id/status", requireStaff, async (req, res) => {
  const snap = await db.collection("transactions").doc(req.params.id).get();
  if (!snap.exists) {
    res.status(404).json({ error: "Transaksi tidak ditemukan" });
    return;
  }
  const data = snap.data();
  const maySee = req.user.role === "admin" || data.cashierId === req.user.uid;
  if (!maySee) {
    res.status(403).json({ error: "Bukan transaksi Anda" });
    return;
  }

  // Masih pending? Verifikasi langsung ke MiomiPay. Bila ternyata
  // PAID/EXPIRED/FAILED, selesaikan di sini (setara webhook).
  let status = data.paymentStatus;
  if (status === "pending" && data.providerReference) {
    try {
      const remote = await fetchMiomiPayStatus(data.providerReference);
      if (remote === "PAID") {
        const result = await settlePaid(snap.id, { reference: data.providerReference });
        status = result.status || 'paid';
      } else if (remote === "EXPIRED" || remote === "FAILED") {
        const mapped = remote === "EXPIRED" ? "expired" : "failed";
        await markNotPaid(snap.id, mapped);
        status = mapped;
      }
    } catch (err) {
      console.error("Gagal verifikasi status ke MiomiPay:", err.message);
    }
  }

  res.json({
    transactionId: snap.id,
    paymentStatus: status,
    transactionStatus: status,
    paymentUrl: data.paymentUrl,
    qrImageUrl: data.qrImageUrl,
    total: data.total,
  });
});

// ---------------------------------------------------------------------------
// Webhook MiomiPay
// ---------------------------------------------------------------------------

function verifySignature(req) {
  const incoming = req.get("X-MiomiPay-Signature") || "";
  const expected = crypto
    .createHmac("sha256", MIOMIPAY_WEBHOOK_SECRET)
    .update(req.rawBody)
    .digest("hex");
  const a = Buffer.from(incoming);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/**
 * Setelah PAID: kurangi stok atomik + tandai lunas + kirim notifikasi.
 * Satu Firestore transaction memastikan stok konsisten (PRD §10).
 * Idempotent: transaksi yang sudah paid diabaikan.
 */
async function settlePaid(transactionId, event) {
  let failedStock = false;
  const result = await db.runTransaction(async (t) => {
    const ref = db.collection("transactions").doc(transactionId);
    const snap = await t.get(ref);
    if (!snap.exists) return { ok: false, reason: "not-found" };
    const data = snap.data();
    if (data.paymentStatus === "paid") return { ok: true, idempotent: true };

    // Kurangi stok sekarang (tagihan sudah lunas).
    for (const item of data.items || []) {
      const productRef = db.collection("products").doc(item.productId);
      const productSnap = await t.get(productRef);
      if (!productSnap.exists) {
        failedStock = true;
        break;
      }
      const stock = productSnap.data().stock ?? 0;
      if (stock < item.quantity) {
        failedStock = true;
        break;
      }
      t.update(productRef, {
        stock: stock - item.quantity,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const status = failedStock ? "failed" : "paid";
    t.update(ref, {
      paymentStatus: status,
      transactionStatus: status,
      paidAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      providerEvent: event?.type ?? null,
    });
    return { ok: true, status, cashierName: data.cashierName, total: data.total, transactionNumber: data.transactionNumber };
  });
  return result;
}

/**
 * Tandai gagal/kedaluwarsa hanya bila masih pending (idempotent).
 */
async function markNotPaid(transactionId, status) {
  const ref = db.collection("transactions").doc(transactionId);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) return;
    if (snap.data().paymentStatus !== "pending") return;
    t.update(ref, {
      paymentStatus: status,
      transactionStatus: status,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

app.post("/api/webhook/miomipay", async (req, res) => {
  if (!verifySignature(req)) {
    res.status(401).json({ error: "Signature tidak valid" });
    return;
  }

  const event = req.body;
  const data = event?.data;
  if (!data?.reference) {
    res.status(400).json({ error: "Payload tidak dikenal" });
    return;
  }

  // Idempotent: catat event, lewati bila sudah pernah diproses.
  const eventRef = db.collection("webhook_events").doc(data.reference);
  const seen = await eventRef.get();
  if (seen.exists) {
    res.json({ received: true, idempotent: true });
    return;
  }

  // Cari transaksi dari reference provider.
  const snap = await db
    .collection("transactions")
    .where("providerReference", "==", data.reference)
    .limit(1)
    .get();

  if (snap.empty) {
    res.status(404).json({ error: "Transaksi tidak ditemukan" });
    return;
  }

  const transactionDoc = snap.docs[0];
  const status = String(data.status || "").toUpperCase();

  if (status === "PAID") {
    const result = await settlePaid(transactionDoc.id, event);
    if (result.ok && result.status === "paid") {
      await sendSaleNotification(
        transactionDoc.id,
        `Pembayaran lunas ${result.transactionNumber}`,
        `${result.cashierName} QRIS Rp${Number(result.total).toLocaleString("id-ID")}`,
      );
    } else if (!result.ok && result.reason === "not-found") {
      res.status(404).json({ error: "Transaksi tidak ditemukan" });
      return;
    }
  } else if (status === "EXPIRED" || status === "FAILED") {
    const mapped = status === "EXPIRED" ? "expired" : "failed";
    const current = transactionDoc.data();
    if (current.paymentStatus === "pending") {
      await transactionDoc.ref.update({
        paymentStatus: mapped,
        transactionStatus: mapped,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  await eventRef.set({
    reference: data.reference,
    event: event.type ?? null,
    status,
    processedAt: FieldValue.serverTimestamp(),
  });

  // Update jejak payment_attempts.
  await db
    .collection("payment_attempts")
    .where("reference", "==", data.reference)
    .limit(1)
    .get()
    .then((attempts) => {
      if (!attempts.empty) {
        attempts.docs[0].ref.update({
          status,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });

  res.json({ received: true });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server notifikasi berjalan pada port ${PORT}`);
  console.log(`MiomiPay: ${MIOMIPAY_BASE_URL} (${MIOMIPAY_API_KEY.slice(0, 10)}…)`);
});
