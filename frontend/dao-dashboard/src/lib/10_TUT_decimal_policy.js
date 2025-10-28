import { utils } from "ethers";

// Number of decimals used on chain. This should never change for TUT.
export const TUT_DECIMALS = 18;

// Define how many decimal places to show for different UI contexts.
// Governance and rewards can use fine grained precision while payments and
// payroll should use two decimal places to mirror fiat style accounting.
export const TUT_PRECISION = {
  governance: 4,
  access: 0,
  payments: 2,
  payroll: 2,
  escrow: 2,
  esg: 4,
  training: 4,
  tiers: 0,
};

// Internal helper to truncate a string representation of a number to the
// desired number of decimal places without rounding up. The returned
// string will contain at most `p` decimals after the period.
function clampToPrecision(str, p) {
  if (!str.includes(".")) return str;
  if (p <= 0) return str.split(".")[0];
  const [i, d = ""] = str.split(".");
  return `${i}.${d.slice(0, p)}`;
}

/**
 * Format a BigNumber into a human readable string using the appropriate
 * precision for the given context. Decimals are read from the contract
 * but default to 18.
 *
 * @param {ethers.BigNumber} bn The BigNumber value to format
 * @param {string} context One of the keys of TUT_PRECISION
 * @param {number} decimals Number of decimals on chain
 */
export function tutFormat(bn, context = "payments", decimals = TUT_DECIMALS) {
  const p = TUT_PRECISION[context] ?? 2;
  const raw = utils.formatUnits(bn, decimals);
  const clamped = clampToPrecision(raw, p);
  return Number(clamped).toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: p,
  });
}

/**
 * Parse a user-provided value into a BigNumber using the correct precision
 * for the given context. Input strings are sanitized, normalized and then
 * rounded half up to the context precision before conversion.
 *
 * @param {string|number} input The user provided value
 * @param {string} context One of the keys of TUT_PRECISION
 * @param {number} decimals Number of decimals on chain
 */
export function tutParse(input, context = "payments", decimals = TUT_DECIMALS) {
  const p = TUT_PRECISION[context] ?? 2;
  const normalized = String(input).replace(/,/g, "").trim();
  if (!/^\d*(\.\d*)?$/.test(normalized)) throw new Error("Invalid amount");
  const [i = "0", d = ""] = normalized.split(".");
  const need = Math.max(0, p - d.length);
  const over = Math.max(0, d.length - p);
  let frac = d;
  if (need > 0) frac = d + "0".repeat(need);
  if (over > 0) {
    const cut = d.slice(0, p);
    const next = d[p] ?? "0";
    const bumped = next >= "5" ? (BigInt(cut || "0") + 1n).toString() : cut;
    frac = bumped.padStart(p, "0");
  }
  const quantized = p > 0 ? `${i}.${frac}` : i;
  return utils.parseUnits(quantized, decimals);
}