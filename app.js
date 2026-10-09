const $ = (id) => document.getElementById(id);

async function refreshSignal() {
  try {
    const response = await fetch("/api/market", { cache: "no-store" });
    if (!response.ok) throw new Error("Market API unavailable");
    const data = await response.json();

    $("marketName").textContent = data.symbol || "XAUUSD";
    $("lastUpdate").textContent = data.updatedAt
      ? new Date(data.updatedAt).toLocaleTimeString()
      : "—";

    const card = $("statusCard");
    card.className = "status";
    $("statusIcon").textContent = "…";

    if (data.status === "GOOD_TO_ON") {
      card.classList.add("good");
      $("statusIcon").textContent = "✓";
      $("statusTitle").textContent = "GOOD TO ON";
      $("statusText").textContent = data.message || "Market condition matches your selected setup.";
    } else if (data.status === "AVOID") {
      card.classList.add("bad");
      $("statusIcon").textContent = "×";
      $("statusTitle").textContent = "AVOID";
      $("statusText").textContent = data.message || "Market condition is not suitable.";
    } else {
      $("statusTitle").textContent = "WAIT";
      $("statusText").textContent = data.message || "Waiting for a suitable market condition.";
    }

    $("connection").textContent = data.connected
      ? "● MT5 market data connected"
      : "● MT5 data not connected yet";
    $("connection").className = data.connected ? "connection online" : "connection";
  } catch (err) {
    $("statusCard").className = "status waiting";
    $("statusIcon").textContent = "…";
    $("statusTitle").textContent = "WAIT";
    $("statusText").textContent = "Market data is unavailable. No ON signal will be shown.";
    $("connection").textContent = "● Cannot connect to market data";
    $("connection").className = "connection";
  }
}
refreshSignal();
setInterval(refreshSignal, 5000);
