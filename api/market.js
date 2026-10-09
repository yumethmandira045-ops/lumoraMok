// Vercel serverless API for the latest MT5 signal.
// Configure UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN and MT5_BRIDGE_TOKEN.
// MT5 sender EA POSTs JSON with Authorization: Bearer <MT5_BRIDGE_TOKEN>.
const KEY = "lumora:latest-market-signal";

async function redisCommand(command) {
  const base = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!base || !token) throw new Error("Redis is not configured");
  const response = await fetch(base.replace(/\/$/, "") + "/" + command.map(encodeURIComponent).join("/"), {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store"
  });
  if (!response.ok) throw new Error("Redis request failed");
  return response.json();
}

export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store, max-age=0");
  if (req.method === "POST") {
    const expected = process.env.MT5_BRIDGE_TOKEN;
    const auth = req.headers.authorization || "";
    if (!expected || auth !== `Bearer ${expected}`) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    const body = req.body || {};
    const allowed = ["GOOD_TO_ON", "WAIT", "AVOID"];
    if (!allowed.includes(body.status) || typeof body.connected !== "boolean") {
      return res.status(400).json({ error: "Invalid signal payload" });
    }
    const payload = {
      connected: body.connected,
      symbol: String(body.symbol || "XAUUSD").slice(0, 24),
      timeframe: String(body.timeframe || "M1").slice(0, 12),
      status: body.status,
      direction: String(body.direction || "").slice(0, 24),
      message: String(body.message || "").slice(0, 160),
      updatedAt: new Date().toISOString()
    };
    try {
      await redisCommand(["set", KEY, JSON.stringify(payload)]);
      return res.status(200).json({ ok: true, updatedAt: payload.updatedAt });
    } catch {
      return res.status(503).json({ error: "Signal storage unavailable; configure Upstash Redis." });
    }
  }
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET, POST");
    return res.status(405).json({ error: "Method not allowed" });
  }
  try {
    const result = await redisCommand(["get", KEY]);
    if (!result.result) {
      return res.status(200).json({ connected: false, symbol: "XAUUSD", status: "WAIT",
        message: "Waiting for first MT5 signal.", updatedAt: null });
    }
    const data = JSON.parse(result.result);
    if (!data.updatedAt || Date.now() - new Date(data.updatedAt).getTime() > 30000) {
      return res.status(200).json({ ...data, connected: false, status: "WAIT",
        message: "MT5 signal is stale. Waiting for a fresh update." });
    }
    return res.status(200).json(data);
  } catch {
    return res.status(200).json({ connected: false, symbol: "XAUUSD", status: "WAIT",
      message: "Signal storage is not configured. Waiting for live data.", updatedAt: null });
  }
}
