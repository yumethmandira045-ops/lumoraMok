# Lumora Market Signal — GitHub + Vercel package

This folder is the full website project. The supplied Lumora logo is integrated into the page and favicon.

## Upload to GitHub
1. Extract this ZIP.
2. Create/open the GitHub repository connected to your Vercel project.
3. Upload every item in this folder, including the `api` and `mt5` folders, `lumora-logo.png`, and hidden files such as `.gitignore`.
4. Commit the changes. Vercel will redeploy from the connected repository.

## Required live data setup
The website does not read MT5 directly. To store the latest status, create an Upstash Redis database and add these Vercel Project Settings → Environment Variables: `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, and `MT5_BRIDGE_TOKEN`. Use a long random secret for `MT5_BRIDGE_TOKEN`, then redeploy.

## MT5 setup
1. Copy `mt5/Lumora_Market_Signal.mq5` to `MQL5/Indicators/` and compile in MetaEditor.
2. Copy `mt5/Lumora_Vercel_Signal_Sender.mq5` to `MQL5/Experts/` and compile.
3. Attach the indicator to XAUUSD M1 and keep `InpExportSignal=true`.
4. Attach the sender EA to a chart and set `InpBridgeToken` to the exact same secret as `MT5_BRIDGE_TOKEN` in Vercel. The endpoint is set to `https://lumoramok.vercel.app/api/market`; change it if your domain is different.
5. MT5 → Tools → Options → Expert Advisors → enable “Allow WebRequest for listed URL” and add `https://lumoramok.vercel.app` (or your domain). Keep MT5 running and connected.
6. Check the MT5 Experts tab for `Lumora signal uploaded. HTTP=200`. Then open `/api/market` on your website to inspect the data.

## Status logic and limitations
The included indicator is an approximate ATR-trend indicator, not a copy of the original indicator shown in screenshots. `GOOD TO ON` means its trend direction persisted for the configured number of closed M1 candles; it does not guarantee a profitable market or switch a separate trading bot on. Validate on a demo account before relying on it. The MT5 computer must stay on with MT5 running.
