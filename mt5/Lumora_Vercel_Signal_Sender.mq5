//+------------------------------------------------------------------+
//| Lumora Vercel Signal Sender                                      |
//| Reads LumoraMarketSignal.json from MT5 Common Files and POSTs it. |
//| This EA does NOT open or manage trades.                           |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"

input string InpEndpoint = "https://lumoramok.vercel.app/api/market";
input string InpBridgeToken = "CHANGE_THIS_TO_THE_SAME_SECRET_AS_VERCEL";
input string InpSignalFile = "LumoraMarketSignal.json";
input int    InpSendEverySeconds = 5;

int OnInit()
{
   if(InpSendEverySeconds < 2)
      return(INIT_PARAMETERS_INCORRECT);
   EventSetTimer(InpSendEverySeconds);
   Print("Lumora Vercel Signal Sender started. It only sends status; it does not trade.");
   SendLatestSignal();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { EventKillTimer(); }
void OnTick() { /* Timer is used so updates are not tied to tick frequency. */ }
void OnTimer() { SendLatestSignal(); }

void SendLatestSignal()
{
   int h = FileOpen(InpSignalFile, FILE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI);
   if(h == INVALID_HANDLE)
   {
      Print("Cannot open Common Files/", InpSignalFile,
            ". Attach Lumora_Market_Signal indicator and check its export setting.");
      return;
   }
   string payload = FileReadString(h, (int)FileSize(h));
   FileClose(h);
   if(StringLen(payload) < 10)
   {
      Print("Signal JSON file is empty.");
      return;
   }

   char data[];
   int count = StringToCharArray(payload, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(count > 0) ArrayResize(data, count - 1); // omit null terminator

   char result[];
   string result_headers;
   string headers = "Content-Type: application/json\r\nAuthorization: Bearer " + InpBridgeToken + "\r\n";
   ResetLastError();
   int status = WebRequest("POST", InpEndpoint, headers, 7000, data, result, result_headers);
   if(status == -1)
   {
      Print("WebRequest failed. Add https://lumoramok.vercel.app to MT5 Tools > Options > Expert Advisors > Allow WebRequest. Error=", GetLastError());
      return;
   }
   string response = CharArrayToString(result, 0, -1, CP_UTF8);
   if(status < 200 || status >= 300)
      Print("Signal upload failed. HTTP=", status, " response=", response);
   else
      Print("Lumora signal uploaded. HTTP=", status, " response=", response);
}
