const $ = id => document.getElementById(id);
async function refreshSignal() {
  try {
    const r = await fetch("/api/market", { cache: "no-store" });
    const d = await r.json();
    $("marketName").textContent = d.symbol || "XAUUSD";
    $("lastUpdate").textContent = d.updatedAt ? new Date(d.updatedAt).toLocaleTimeString() : "—";
    const card = $("statusCard"); card.className = "status";
    if (d.status === "GOOD_TO_ON") {
      card.classList.add("good"); $("statusIcon").textContent = "✓";
      $("statusTitle").textContent = "GOOD TO ON";
      $("statusText").textContent = d.message || "Configured trend condition detected.";
    } else if (d.status === "AVOID") {
      card.classList.add("bad"); $("statusIcon").textContent = "×";
      $("statusTitle").textContent = "AVOID";
      $("statusText").textContent = d.message || "Market condition is not suitable.";
    } else {
      $("statusIcon").textContent = "…"; $("statusTitle").textContent = "WAIT";
      $("statusText").textContent = d.message || "Waiting for suitable market condition.";
    }
    const fresh = d.updatedAt && (Date.now() - new Date(d.updatedAt).getTime() < 30000);
    const connected = d.connected === true && fresh;
    $("connection").textContent = connected ? "● MT5 connected · live update" : "● MT5 not connected / signal is stale";
    $("connection").className = connected ? "connection online" : "connection";
    if (!connected && d.status === "GOOD_TO_ON") {
      card.className = "status waiting"; $("statusIcon").textContent = "…";
      $("statusTitle").textContent = "WAIT"; $("statusText").textContent = "MT5 data is stale. Waiting for a fresh signal.";
    }
  } catch {
    $("statusCard").className = "status waiting"; $("statusIcon").textContent = "…";
    $("statusTitle").textContent = "WAIT"; $("statusText").textContent = "Cannot read latest market signal.";
    $("connection").textContent = "● Connection unavailable"; $("connection").className = "connection";
  }
}
refreshSignal(); setInterval(refreshSignal, 5000);
