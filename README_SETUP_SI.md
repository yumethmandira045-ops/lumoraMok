# Lumora Market Signal — PWA + MT5 + Vercel

## What's updated
- Installable Android PWA manifest, icons, service worker, install button, safe-area/mobile layout.
- Stricter signal filters: closed-candle confirmation, ADX trend strength, fast/slow EMA alignment and slope, minimum candle body, and late-entry/extension filter.
- Existing Vercel `/api/market` + Upstash Redis + MT5 sender payload contract is preserved.

## Deploy
1. Extract this ZIP and upload/replace all files in the GitHub repository connected to Vercel (include `manifest.webmanifest`, `sw.js`, `icons/`, `api/`, and `mt5/`).
2. Commit changes and wait for Vercel deployment to finish.
3. Keep existing Vercel env vars: `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, `MT5_BRIDGE_TOKEN`.
4. In MT5 MetaEditor, replace `MQL5/Indicators/Lumora_Market_Signal.mq5` with this version and compile. Reattach/reload the indicator and ensure `InpExportSignal=true`.
5. Keep `Lumora_Vercel_Signal_Sender` EA running with the same `InpBridgeToken`; no change to its endpoint is required.

## Install on Android
Open `https://lumoramok.vercel.app` in Chrome. Use the on-page Install App button if shown, or Chrome menu (⋮) → Install app / Add to Home screen. On iPhone, open in Safari → Share → Add to Home Screen.

## Filters (starting values)
- ADX >= 18; fast EMA 9 vs slow EMA 21 alignment and fast EMA slope.
- 3 closed candles in the same ATR-trend direction.
- Candle body >= 0.10 ATR.
- Close no more than 1.8 ATR away from fast EMA to avoid late entries.

These are stricter starting filters, not proven profitability. They may reduce signals and can also miss trades. Backtest/walk-forward test on historical data and demo-test before relying on them. The included trend line remains an approximation; it is not the user's original proprietary indicator. The sender EA only uploads signals and never opens/closes trades.
