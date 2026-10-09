// Vercel serverless endpoint.
// Configure MT5_BRIDGE_URL in Vercel Project Settings > Environment Variables.
// It must point to a secure bridge endpoint that returns JSON like:
// { "connected": true, "symbol": "XAUUSD", "status": "GOOD_TO_ON",
//   "message": "Trend pattern detected", "updatedAt": "2026-10-09T12:00:00Z" }
//
// Without a configured bridge this safely returns WAIT; it never fabricates a live signal.
export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store, max-age=0");
  const bridgeUrl = process.env.MT5_BRIDGE_URL;

  if (!bridgeUrl) {
    return res.status(200).json({
      connected: false,
      symbol: "XAUUSD",
      status: "WAIT",
      message: "MT5 data bridge is not configured. Waiting for live data.",
      updatedAt: null
    });
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    const response = await fetch(bridgeUrl, {
      method: "GET",
      headers: process.env.MT5_BRIDGE_TOKEN
        ? { Authorization: `Bearer ${process.env.MT5_BRIDGE_TOKEN}` }
        : {},
      signal: controller.signal,
      cache: "no-store"
    });
    clearTimeout(timeout);

    if (!response.ok) throw new Error("Bridge returned non-200 status");
    const data = await response.json();
    const allowed = ["GOOD_TO_ON", "WAIT", "AVOID"];
    if (!allowed.includes(data.status)) throw new Error("Invalid signal status");

    return res.status(200).json({
      connected: data.connected === true,
      symbol: data.symbol || "XAUUSD",
      status: data.status,
      message: data.message || "",
      updatedAt: data.updatedAt || new Date().toISOString()
    });
  } catch (error) {
    return res.status(200).json({
      connected: false,
      symbol: "XAUUSD",
      status: "WAIT",
      message: "Cannot reach MT5 bridge. Waiting for connection.",
      updatedAt: null
    });
  }
}
