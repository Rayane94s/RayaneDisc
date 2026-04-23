const axios = require("axios");

const apiBase = `${process.env.FLINKS_API_URL}/v3/${process.env.FLINKS_CUSTOMER_ID}/BankingServices`;

// x-api-key is required on all data endpoints (GetAccountsSummary, GetAccountsDetail, etc.)
const dataHeaders = {
  "x-api-key": process.env.FLINKS_API_KEY,
  "Content-Type": "application/json",
};

/**
 * Generate a one-time authorize token using the secret key.
 * Single-use, valid 30 minutes.
 */
async function generateAuthorizeToken() {
  const res = await axios.post(
    `${apiBase}/GenerateAuthorizeToken`,
    {},
    { headers: { "flinks-auth-key": process.env.FLINKS_SECRET_KEY, "Content-Type": "application/json" } }
  );
  return res.data.Token;
}

/**
 * Open a session for a stored loginId → returns requestId for data calls.
 */
async function authorize(loginId) {
  const token = await generateAuthorizeToken();
  const res = await axios.post(
    `${apiBase}/Authorize`,
    { LoginId: loginId, MostRecentCached: true },
    { headers: { "flinks-auth-key": token, "Content-Type": "application/json" } }
  );
  return { requestId: res.data.RequestId };
}

module.exports = { apiBase, dataHeaders, generateAuthorizeToken, authorize };

