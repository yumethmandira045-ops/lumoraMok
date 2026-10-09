const $ = id => document.getElementById(id);
let installPrompt = null;
window.addEventListener('beforeinstallprompt', event => {
  event.preventDefault(); installPrompt = event; $('installButton').hidden = false;
});
$('installButton').addEventListener('click', async () => {
  if (!installPrompt) return;
  installPrompt.prompt(); await installPrompt.userChoice; installPrompt = null; $('installButton').hidden = true;
});
window.addEventListener('appinstalled', () => { $('installButton').hidden = true; });
if ('serviceWorker' in navigator) window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
async function refreshSignal() {
  try {
    const r = await fetch('/api/market', { cache: 'no-store' });
    if (!r.ok) throw new Error('Signal API unavailable');
    const d = await r.json();
    $('marketName').textContent = d.symbol || 'XAUUSD';
    $('lastUpdate').textContent = d.updatedAt ? new Date(d.updatedAt).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit',second:'2-digit'}) : '—';
    const card = $('statusCard'); card.className = 'status';
    if (d.status === 'GOOD_TO_ON') {
      card.classList.add('good'); $('statusIcon').textContent = '✓'; $('statusTitle').textContent = 'GOOD TO ON';
      $('statusText').textContent = d.message || 'All configured trend checks passed on closed candles.';
    } else if (d.status === 'AVOID') {
      card.classList.add('bad'); $('statusIcon').textContent = '×'; $('statusTitle').textContent = 'AVOID';
      $('statusText').textContent = d.message || 'Market condition is not suitable.';
    } else {
      $('statusIcon').textContent = '…'; $('statusTitle').textContent = 'WAIT';
      $('statusText').textContent = d.message || 'Waiting for suitable market conditions.';
    }
    const age = d.updatedAt ? Date.now() - new Date(d.updatedAt).getTime() : Infinity;
    const connected = d.connected === true && age >= -5000 && age < 30000;
    $('connection').textContent = connected ? '● MT5 connected · live update' : '● MT5 not connected / signal is stale';
    $('connection').className = connected ? 'connection online' : 'connection';
    if (!connected) { card.className = 'status waiting'; $('statusIcon').textContent = '…'; $('statusTitle').textContent = 'WAIT'; $('statusText').textContent = 'MT5 data is stale. Waiting for a fresh signal.'; }
  } catch {
    $('statusCard').className = 'status waiting'; $('statusIcon').textContent = '…'; $('statusTitle').textContent = 'WAIT';
    $('statusText').textContent = 'Cannot read latest market signal.'; $('connection').textContent = '● Connection unavailable'; $('connection').className = 'connection';
  }
}
refreshSignal(); setInterval(refreshSignal, 5000);
