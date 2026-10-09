# Lumora Market Signal (Vercel)

A simple mobile-friendly XAUUSD M1 status page. It displays only:
- GOOD TO ON
- WAIT
- AVOID

## Deploy the website
1. Extract this ZIP.
2. Upload the folder to a GitHub repository.
3. In Vercel, choose **Add New → Project** and import that repository.
4. Deploy. No build command is needed for the static frontend and API function.

## Important: live MT5 connection is a separate step
This website does not connect directly to the MT5 terminal on your computer. Vercel cannot read a local MT5 indicator automatically.

The `/api/market` endpoint safely displays WAIT until `MT5_BRIDGE_URL` is configured in Vercel:
Project → Settings → Environment Variables.

The bridge URL must return JSON in this format:
```json
{
  "connected": true,
  "symbol": "XAUUSD",
  "status": "GOOD_TO_ON",
  "message": "Trend pattern detected",
  "updatedAt": "2026-10-09T12:00:00Z"
}
```
`status` must be `GOOD_TO_ON`, `WAIT`, or `AVOID`.

Optionally set `MT5_BRIDGE_TOKEN` if your bridge supports Bearer-token authentication. Use HTTPS and protect the endpoint; do not expose MT5 passwords or trading API secrets in browser JavaScript.

## To finish the real signal integration
The MT5 indicator's source (`.mq5`) or documentation for its output buffers/signals is needed to identify the same blue/red trend pattern shown in your screenshots. An `.ex5` file alone may not expose the indicator's internal logic. Until that connection is built and tested, the site will not claim a live GOOD TO ON signal.


## MT5 indicator source
`Lumora_Market_Signal.mq5` is a new approximation, not the original indicator shown in the screenshots. It uses ATR trailing trend bands and BUY/SELL arrows, and writes a JSON status file named `LumoraMarketSignal.json` into the MT5 Common Files directory.

To install: copy the `.mq5` file to `MQL5/Indicators`, open it in MetaEditor, compile it, then attach it to an XAUUSD M1 chart. Enable Algo Trading is not required just to calculate the indicator, but MT5 must be running for updates.

The file is local to the computer. Vercel cannot read it directly. A separate secure bridge/uploader still needs to send the JSON status from the computer to the deployed site. This indicator is not an automatic trading EA and does not place trades.
