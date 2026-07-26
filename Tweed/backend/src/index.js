require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");
const {
  getAuthUrl,
  exchangeCode,
  isConnected,
  fetchScotiaTransactionsCached,
  invalidateCache,
  loadOverrides,
  OVERRIDES_FILE,
} = require("./gmail");
const { RULES, DEFAULT } = require("./categorize");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "..", "public")));

// Anything interpolated into an HTML response has to be escaped — the OAuth
// callback echoes back values that arrive straight off the query string.
const escapeHtml = (value) =>
  String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[c]);

// ─── Categories ────────────────────────────────────────────────────────────────
app.get("/api/categories", (req, res) => {
  const list = [...RULES.map(r => ({ category: r.category, emoji: r.emoji, color: r.color, bg: r.bg })), DEFAULT];
  res.json({ categories: list });
});

app.post("/api/categories/override", (req, res) => {
  const { merchant, category, emoji, color, bg } = req.body;
  if (!merchant || !category) return res.status(400).json({ error: "merchant and category required" });
  const overrides = loadOverrides();
  overrides[merchant.toLowerCase()] = { category, emoji, color, bg };
  fs.writeFileSync(OVERRIDES_FILE, JSON.stringify(overrides, null, 2));
  invalidateCache();
  res.json({ success: true });
});


app.get("/api/gmail/status", (req, res) => {
  res.json({ connected: isConnected() });
});

app.get("/api/gmail/auth", (req, res) => {
  res.redirect(getAuthUrl());
});

app.get("/api/gmail/callback", async (req, res) => {
  const { code, error } = req.query;
  if (error) return res.status(400).send(`<h2>❌ Auth failed: ${escapeHtml(error)}</h2>`);
  try {
    await exchangeCode(code);
    res.send(`<!DOCTYPE html><html><head><meta charset="UTF-8">
      <script>setTimeout(() => window.location.href = '/', 1500);</script>
      <style>body{font-family:system-ui;display:flex;align-items:center;justify-content:center;height:100vh;background:#f0fdf4;}</style>
      </head><body><div style="text-align:center"><div style="font-size:48px">✅</div>
      <h2 style="color:#166534">Gmail Connected!</h2><p style="color:#6b7280">Fetching your Scotia transactions…</p>
      </div></body></html>`);
  } catch (err) {
    res.status(500).send(`<h2>Error: ${escapeHtml(err.message)}</h2>`);
  }
});

app.get("/api/gmail/transactions", async (req, res) => {
  try {
    const transactions = await fetchScotiaTransactionsCached(200);
    res.json({ transactions, total: transactions.length, source: "gmail" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Disconnect Gmail ──────────────────────────────────────────────────────────
app.post("/api/gmail/disconnect", (req, res) => {
  const tokensFile = path.join(__dirname, "..", "gmail-tokens.json");
  try { fs.unlinkSync(tokensFile); } catch {}
  res.json({ success: true });
});

// ─── Start ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Tweed backend running on http://localhost:${PORT}`));

