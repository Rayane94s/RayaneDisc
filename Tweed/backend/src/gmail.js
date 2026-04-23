const { google } = require("googleapis");
const fs = require("fs");
const path = require("path");
const { categorize } = require("./categorize");

const OVERRIDES_FILE = path.join(__dirname, "..", "merchant-categories.json");
const TOKENS_FILE = path.join(__dirname, "..", "gmail-tokens.json");

// ─── OAuth2 client ─────────────────────────────────────────────────────────────
function getOAuthClient() {
  return new google.auth.OAuth2(
    process.env.GMAIL_CLIENT_ID,
    process.env.GMAIL_CLIENT_SECRET,
    process.env.GMAIL_REDIRECT_URI || "http://localhost:3000/api/gmail/callback"
  );
}

function loadTokens() {
  try { return JSON.parse(fs.readFileSync(TOKENS_FILE, "utf8")); } catch { return null; }
}

function saveTokens(tokens) {
  fs.writeFileSync(TOKENS_FILE, JSON.stringify(tokens, null, 2));
}

function loadOverrides() {
  try { return JSON.parse(fs.readFileSync(OVERRIDES_FILE, "utf8")); } catch { return {}; }
}

function applyCategory(merchant) {
  const overrides = loadOverrides();
  if (merchant && overrides[merchant.toLowerCase()]) {
    return overrides[merchant.toLowerCase()];
  }
  return categorize(merchant);
}


function getAuthUrl() {
  const client = getOAuthClient();
  return client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: ["https://www.googleapis.com/auth/gmail.readonly"],
  });
}

async function exchangeCode(code) {
  const client = getOAuthClient();
  const { tokens } = await client.getToken(code);
  saveTokens(tokens);
  return tokens;
}

function isConnected() {
  return loadTokens() !== null;
}

async function getGmailClient() {
  const tokens = loadTokens();
  if (!tokens) throw new Error("Gmail not connected");
  const client = getOAuthClient();
  client.setCredentials(tokens);
  // Auto-refresh if expired
  client.on("tokens", (newTokens) => {
    const updated = { ...loadTokens(), ...newTokens };
    saveTokens(updated);
  });
  return google.gmail({ version: "v1", auth: client });
}

// ─── Parse a single Scotia email body ─────────────────────────────────────────
function parseScotiaEmail(body, emailDate) {
  // French: "Une autorisation de 50,97 $ auprès de IGA #7925 a été effectuée sur le compte 4537*****096**** à 16 h 54 HE"
  const frenchMatch = body.match(
    /Une autorisation de\s+([\d\s,\.]+)\s*\$\s+auprès de\s+(.+?)\s+a été effectuée sur le compte\s+([\w*]+)\s+à\s+(\d+)\s*h\s*(\d*)/i
  );
  if (frenchMatch) {
    const rawAmount = frenchMatch[1].replace(/\s/g, "").replace(",", ".");
    return {
      amount: parseFloat(rawAmount),
      merchant: frenchMatch[2].trim(),
      account: frenchMatch[3].trim(),
      date: emailDate,
      currency: "CAD",
      source: "gmail",
    };
  }

  // English: "A $50.97 purchase was made at IGA #7925"
  const englishMatch = body.match(
    /A\s+\$([\d,.]+)\s+(?:purchase|transaction|payment)\s+was\s+made\s+at\s+(.+?)(?:\s+on\s+account|\s+at\s+\d|\.|$)/i
  );
  if (englishMatch) {
    const rawAmount = englishMatch[1].replace(",", "");
    return {
      amount: parseFloat(rawAmount),
      merchant: englishMatch[2].trim(),
      account: null,
      date: emailDate,
      currency: "CAD",
      source: "gmail",
    };
  }

  return null;
}

// ─── Decode base64url Gmail message body ──────────────────────────────────────
function decodeBody(payload) {
  // Walk the MIME tree to find text/plain
  if (payload.body?.data) {
    return Buffer.from(payload.body.data, "base64url").toString("utf8");
  }
  if (payload.parts) {
    for (const part of payload.parts) {
      const text = decodeBody(part);
      if (text) return text;
    }
  }
  return null;
}

// Format a Date as "YYYY-MM-DD" in the server's local timezone
function toLocalDateString(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

// ─── Fetch and parse Scotia alerts from Gmail ──────────────────────────────────
async function fetchScotiaTransactions(maxResults = 100, afterDate = "2026/04/01") {
  const gmail = await getGmailClient();

  // Search for Scotia alert emails starting from afterDate
  const query = `from:alertas@scotiabank.com ("autorisation de" OR "purchase was made at" OR "InfoAlertes" OR "InfoAlerts") after:${afterDate}`;

  const listRes = await gmail.users.messages.list({
    userId: "me",
    q: query,
    maxResults,
  });

  const messages = listRes.data.messages || [];
  if (!messages.length) return [];


  async function fetchOne(msg) {
    try {
      const msgRes = await gmail.users.messages.get({ userId: "me", id: msg.id, format: "full" });
      const headers = msgRes.data.payload.headers;
      const dateHeader = headers.find((h) => h.name === "Date")?.value;
      const emailDate = dateHeader ? toLocalDateString(new Date(dateHeader)) : toLocalDateString(new Date());
      const body = decodeBody(msgRes.data.payload);
      if (!body) return null;
      const parsed = parseScotiaEmail(body, emailDate);
      if (parsed) { const cat = applyCategory(parsed.merchant); return { id: msg.id, ...parsed, ...cat }; }
      return null;
    } catch { return null; }
  }

  const transactions = (await Promise.all(messages.map(fetchOne))).filter(Boolean);

  // Sort newest first
  return transactions.sort((a, b) => new Date(b.date) - new Date(a.date));
}

// ─── Disk-persisted cache ─────────────────────────────────────────────────────
const CACHE_FILE = path.join(__dirname, "..", "txn-cache.json");
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

function readDiskCache() {
  try {
    const { data, time } = JSON.parse(fs.readFileSync(CACHE_FILE, "utf8"));
    if (Date.now() - time < CACHE_TTL_MS) return { data, time };
  } catch {}
  return null;
}

function writeDiskCache(data) {
  const time = Date.now();
  fs.writeFileSync(CACHE_FILE, JSON.stringify({ data, time }));
  return time;
}

async function fetchScotiaTransactionsCached(maxResults = 200, afterDate = "2026/04/01") {
  const cached = readDiskCache();
  if (cached) return cached.data;
  const data = await fetchScotiaTransactions(maxResults, afterDate);
  writeDiskCache(data);
  return data;
}

function invalidateCache() {
  try { fs.unlinkSync(CACHE_FILE); } catch {}
}

module.exports = { getAuthUrl, exchangeCode, isConnected, fetchScotiaTransactions, fetchScotiaTransactionsCached, invalidateCache, loadOverrides, OVERRIDES_FILE };
