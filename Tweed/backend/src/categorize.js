// Keyword-based merchant categorization.
// Rules are checked in order; first match wins.
const RULES = [
  // ── Groceries ──────────────────────────────────────────────────────────────
  {
    category: "Groceries", emoji: "🛒", color: "#16a34a", bg: "#f0fdf4",
    patterns: [
      /\biga\b/i, /metro/i, /provigo/i, /maxi\b/i, /loblaws/i, /sobeys/i,
      /super\s*c\b/i, /walmart/i, /costco/i, /whole\s*foods/i, /marché/i,
      /epicerie/i, /épicerie/i, /grocery/i, /fruiterie/i,
    ],
  },
  // ── Restaurants & Cafés ────────────────────────────────────────────────────
  {
    category: "Food & Dining", emoji: "🍔", color: "#ea580c", bg: "#fff7ed",
    patterns: [
      /tim\s*hortons/i, /starbucks/i, /mcdonald/i, /subway/i, /burger\s*king/i,
      /wendy/i, /harvey/i, /pizza/i, /sushi/i, /resto/i, /restaurant/i,
      /café|cafe/i, /boulangerie/i, /patisserie/i, /pâtisserie/i, /diner/i,
      /grill/i, /bistro/i, /bar\s*&\s*grill/i, /five\s*guys/i, /chipotle/i,
      /noodle/i, /ramen/i, /pho\b/i, /thai/i, /indian\s*cuisine/i,
      /donut/i, /beignet/i, /chocolat/i,
    ],
  },
  // ── Gas & Transport ────────────────────────────────────────────────────────
  {
    category: "Transport", emoji: "🚗", color: "#2563eb", bg: "#eff6ff",
    patterns: [
      /uber/i, /lyft/i, /taxi/i, /esso/i, /petro[\s-]?canada/i, /shell/i,
      /ultra\s*mar/i, /ultramar/i, /couche[\s-]?tard/i, /circle\s*k/i,
      /stm\b/i, /rtm\b/i, /exo\b/i, /viarail/i, /via\s*rail/i,
      /parking/i, /stationnement/i, /autoroute/i, /péage/i, /peage/i,
      /bixi/i, /vélo\s*libre/i,
    ],
  },
  // ── Health & Pharmacy ──────────────────────────────────────────────────────
  {
    category: "Health", emoji: "💊", color: "#dc2626", bg: "#fef2f2",
    patterns: [
      /pharmaprix/i, /jean\s*coutu/i, /uniprix/i, /brunet/i, /shoppers/i,
      /rexall/i, /clinique/i, /clinic/i, /dentist/i, /dentaire/i,
      /médecin/i, /medecin/i, /hospital/i, /hôpital/i, /optique/i,
      /physio/i, /massage/i, /santé/i, /sante/i,
    ],
  },
  // ── Entertainment ──────────────────────────────────────────────────────────
  {
    category: "Entertainment", emoji: "🎬", color: "#7c3aed", bg: "#f5f3ff",
    patterns: [
      /netflix/i, /spotify/i, /apple/i, /google\s*play/i, /steam/i,
      /cinema/i, /cinéma/i, /cineplex/i, /landmark/i, /théâtre/i, /theatre/i,
      /disney/i, /amazon\s*prime/i, /crave/i, /youtube/i, /twitch/i,
      /playstation/i, /xbox/i, /nintendo/i,
    ],
  },
  // ── Shopping ───────────────────────────────────────────────────────────────
  {
    category: "Shopping", emoji: "🛍️", color: "#db2777", bg: "#fdf2f8",
    patterns: [
      /amazon/i, /ebay/i, /etsy/i, /zara/i, /h\s*&\s*m\b/i, /uniqlo/i,
      /simons/i, /reitmans/i, /winners/i, /dollarama/i, /ikea/i,
      /best\s*buy/i, /canadian\s*tire/i, /home\s*depot/i, /rona/i,
      /bureau\s*en\s*gros/i, /staples/i, /sport\s*chek/i, /atmosphere/i,
      /ardene/i, /garage\b/i, /aldo/i, /la\s*senza/i, /victoria/i,
    ],
  },
  // ── Utilities & Telecom ────────────────────────────────────────────────────
  {
    category: "Utilities", emoji: "💡", color: "#d97706", bg: "#fffbeb",
    patterns: [
      /hydro[\s-]?québec/i, /hydro/i, /hydroquebec/i, /videotron/i,
      /bell\b/i, /rogers/i, /telus/i, /fido/i, /virgin\s*mobile/i,
      /koodo/i, /chatr/i, /internet/i, /desjardins/i, /assurance/i,
      /insurance/i,
    ],
  },
  // ── Travel ─────────────────────────────────────────────────────────────────
  {
    category: "Travel", emoji: "✈️", color: "#0891b2", bg: "#ecfeff",
    patterns: [
      /air\s*canada/i, /air\s*transat/i, /porter/i, /westjet/i,
      /airbnb/i, /booking\.com/i, /expedia/i, /hotel/i, /hôtel/i,
      /marriott/i, /hilton/i, /holiday\s*inn/i, /best\s*western/i,
    ],
  },
  // ── Transfers & ATM ────────────────────────────────────────────────────────
  {
    category: "Transfer / ATM", emoji: "💸", color: "#64748b", bg: "#f8fafc",
    patterns: [
      /atm/i, /virement/i, /transfer/i, /interac/i, /paypal/i,
      /venmo/i, /e[\s-]?transfer/i,
    ],
  },
];

const DEFAULT = { category: "Other", emoji: "🏷️", color: "#6b7280", bg: "#f9fafb" };

/**
 * Returns { category, emoji, color, bg } for a given merchant name.
 */
function categorize(merchant) {
  if (!merchant) return DEFAULT;
  for (const rule of RULES) {
    if (rule.patterns.some(p => p.test(merchant))) {
      return { category: rule.category, emoji: rule.emoji, color: rule.color, bg: rule.bg };
    }
  }
  return DEFAULT;
}

module.exports = { categorize, RULES, DEFAULT };
