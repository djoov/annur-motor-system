// Shared readers for data written by the mobile app (the source of truth).

// Stock is a single number on mobile: `stock`, with `qty_display` as a mirror.
// Older items may only have `qty_display` or `qty_warehouse`.
export function itemStock(data: any): number {
  return Number(data?.stock ?? data?.qty_display ?? data?.qty_warehouse ?? 0) || 0;
}

// YYYY-MM-DD in the browser's local time (WIB), not UTC like toISOString().
export function localDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

// Start of a local day from a YYYY-MM-DD key (new Date("YYYY-MM-DD") is UTC).
export function startOfLocalDay(key: string): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d, 0, 0, 0, 0);
}

export function endOfLocalDay(key: string): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d, 23, 59, 59, 999);
}

export function toDate(value: any): Date | null {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  const d = new Date(value);
  return isNaN(d.getTime()) ? null : d;
}

// Mobile writes 'debt' for debt sales; the old web POS wrote 'tempo'.
export function isDebtSale(trx: any): boolean {
  return trx?.type !== "return" && (trx?.paymentMethod === "debt" || trx?.paymentMethod === "tempo");
}

export function paymentLabel(trx: any): string {
  if (trx?.type === "return") return "Retur";
  switch (trx?.paymentMethod) {
    case "debt":
    case "tempo":
      return "Hutang";
    case "transfer":
      return "Transfer";
    default:
      return "Tunai";
  }
}
