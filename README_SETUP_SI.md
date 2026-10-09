# Lumora Market Signal — MT5 → Vercel connection

This package contains a simple website, Vercel API, and MT5 sender EA.

## Important
- `Lumora_Market_Signal.mq5` is an approximate ATR trend indicator, not the original proprietary indicator from the screenshots.
- The sender EA only uploads the JSON status. It does not place trades.
- The current indicator writes a JSON file into MT5's **Common Files** folder. The sender EA reads that file and uploads it to the Vercel API.
- Vercel needs persistent storage; this package uses Upstash Redis. The signal will remain WAIT until the setup below is completed.

## 1. Configure Upstash Redis
1. Create a Redis database at https://upstash.com/ (free tier may be available depending on current limits).
2. Copy its **REST URL** and **REST Token**.
3. In Vercel → your project → Settings → Environment Variables, add:
   - `UPSTASH_REDIS_REST_URL` = your Upstash REST URL
   - `UPSTASH_REDIS_REST_TOKEN` = your Upstash REST Token
   - `MT5_BRIDGE_TOKEN` = a long random secret, for example 32+ random characters
4. Redeploy the Vercel project after adding environment variables.

## 2. Update Vercel files
Upload/replace `index.html`, `style.css`, `app.js`, and `api/market.js` in the GitHub repository connected to Vercel. Keep the `api` directory at the project root. Push to GitHub and wait for Vercel to redeploy.

The frontend URL shown in the earlier screenshot was `https://lumoramok.vercel.app`. If your actual domain differs, update `InpEndpoint` in the EA.

## 3. Install the indicator and sender EA on the MT5 computer
1. Copy `mt5/Lumora_Market_Signal.mq5` to `MQL5/Indicators/`.
2. Copy `mt5/Lumora_Vercel_Signal_Sender.mq5` to `MQL5/Experts/`.
3. Open each file in MetaEditor and Compile.
4. Attach `Lumora_Market_Signal` to the XAUUSD M1 chart. Keep `InpExportSignal=true`.
5. Attach `Lumora_Vercel_Signal_Sender` to any chart. In Inputs, set `InpBridgeToken` to the exact same value as Vercel's `MT5_BRIDGE_TOKEN`.
6. In MT5, go to Tools → Options → Expert Advisors and enable **Allow WebRequest for listed URL**. Add:
   `https://lumoramok.vercel.app`
7. Keep MT5 running and connected to the broker.

## 4. Test
- Open `https://lumoramok.vercel.app/api/market`. Initially it should say WAIT.
- In MT5 → Toolbox → Experts, look for `Lumora signal uploaded. HTTP=200`.
- Refresh the site. It should show the latest signal and a fresh update time.
- If you get HTTP 401, the token doesn't match. If WebRequest error -1, whitelist the URL. If HTTP 503, the Upstash environment variables are missing or incorrect.

## Signal meaning and limitations
The provided indicator is a fresh approximation using ATR trend bands and 3 same-direction closed candles. `GOOD_TO_ON` means the approximation's trend rule was met, not that a profitable trade is guaranteed and not necessarily identical to the user's original screenshots. Tune/test on demo first. Do not use it to auto-trade without independent validation.
