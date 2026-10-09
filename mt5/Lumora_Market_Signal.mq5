//+------------------------------------------------------------------+
//| Lumora Market Signal - M1 Trend Detector                         |
//| Educational approximation based on ATR trailing trend bands.     |
//| This is NOT the original indicator from the supplied screenshots.|
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_label1  "Bull Trend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

#property indicator_label2  "Bear Trend"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

#property indicator_label3  "BUY"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrBlue
#property indicator_width3  2

#property indicator_label4  "SELL"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  2

input int      InpATRPeriod       = 10;    // ATR calculation period
input double   InpATRMultiplier   = 2.0;   // Trend band multiplier
input int      InpConfirmBars     = 3;     // Same-direction closed candles for GOOD TO ON
input bool     InpExportSignal    = true;  // Write status JSON to MT5 Common Files
input string   InpExportFile      = "LumoraMarketSignal.json";

double BullBuffer[];
double BearBuffer[];
double BuyBuffer[];
double SellBuffer[];

double TrueRange[];
double ATRValues[];
double BasicUpper[];
double BasicLower[];
double FinalUpper[];
double FinalLower[];
int    Trend[];

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpATRPeriod < 1 || InpATRMultiplier <= 0.0 || InpConfirmBars < 1)
      return(INIT_PARAMETERS_INCORRECT);

   SetIndexBuffer(0, BullBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BearBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, BuyBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, SellBuffer, INDICATOR_DATA);

   ArraySetAsSeries(BullBuffer, false);
   ArraySetAsSeries(BearBuffer, false);
   ArraySetAsSeries(BuyBuffer, false);
   ArraySetAsSeries(SellBuffer, false);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(2, PLOT_ARROW, 233); // Up arrow
   PlotIndexSetInteger(3, PLOT_ARROW, 234); // Down arrow

   IndicatorSetString(INDICATOR_SHORTNAME, "Lumora Market Signal (ATR Trend)");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < InpATRPeriod + 3)
      return(0);

   // Use oldest-to-newest indexing for deterministic calculations.
   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);

   ArrayResize(TrueRange, rates_total);
   ArrayResize(ATRValues, rates_total);
   ArrayResize(BasicUpper, rates_total);
   ArrayResize(BasicLower, rates_total);
   ArrayResize(FinalUpper, rates_total);
   ArrayResize(FinalLower, rates_total);
   ArrayResize(Trend, rates_total);

   for(int i = 0; i < rates_total; i++)
   {
      BullBuffer[i] = EMPTY_VALUE;
      BearBuffer[i] = EMPTY_VALUE;
      BuyBuffer[i]  = EMPTY_VALUE;
      SellBuffer[i] = EMPTY_VALUE;

      if(i == 0)
         TrueRange[i] = high[i] - low[i];
      else
      {
         double range1 = high[i] - low[i];
         double range2 = MathAbs(high[i] - close[i-1]);
         double range3 = MathAbs(low[i] - close[i-1]);
         TrueRange[i] = MathMax(range1, MathMax(range2, range3));
      }

      if(i == 0)
         ATRValues[i] = TrueRange[i];
      else if(i < InpATRPeriod)
         ATRValues[i] = (ATRValues[i-1] * i + TrueRange[i]) / (i + 1.0);
      else
         ATRValues[i] = (ATRValues[i-1] * (InpATRPeriod - 1.0) + TrueRange[i]) / InpATRPeriod;

      double midpoint = (high[i] + low[i]) / 2.0;
      BasicUpper[i] = midpoint + InpATRMultiplier * ATRValues[i];
      BasicLower[i] = midpoint - InpATRMultiplier * ATRValues[i];

      if(i == 0)
      {
         FinalUpper[i] = BasicUpper[i];
         FinalLower[i] = BasicLower[i];
         Trend[i] = (close[i] >= midpoint ? 1 : -1);
      }
      else
      {
         FinalUpper[i] = (BasicUpper[i] < FinalUpper[i-1] || close[i-1] > FinalUpper[i-1])
                         ? BasicUpper[i] : FinalUpper[i-1];
         FinalLower[i] = (BasicLower[i] > FinalLower[i-1] || close[i-1] < FinalLower[i-1])
                         ? BasicLower[i] : FinalLower[i-1];

         Trend[i] = Trend[i-1];
         if(Trend[i-1] < 0 && close[i] > FinalUpper[i-1])
            Trend[i] = 1;
         else if(Trend[i-1] > 0 && close[i] < FinalLower[i-1])
            Trend[i] = -1;
      }

      if(Trend[i] > 0)
      {
         BullBuffer[i] = FinalLower[i];
         if(i > 0 && Trend[i-1] < 0)
            BuyBuffer[i] = low[i] - ATRValues[i] * 0.25;
      }
      else
      {
         BearBuffer[i] = FinalUpper[i];
         if(i > 0 && Trend[i-1] > 0)
            SellBuffer[i] = high[i] + ATRValues[i] * 0.25;
      }
   }

   // Export only the last CLOSED candle; do not use the still-forming candle.
   if(InpExportSignal)
   {
      int closedBar = rates_total - 2;
      int sameDirectionBars = 0;
      int direction = Trend[closedBar];

      for(int j = closedBar; j >= 0 && Trend[j] == direction; j--)
         sameDirectionBars++;

      string signalStatus = (sameDirectionBars >= InpConfirmBars) ? "GOOD_TO_ON" : "WAIT";
      string directionText = (direction > 0) ? "UPTREND" : "DOWNTREND";
      string messageText = (signalStatus == "GOOD_TO_ON")
                           ? directionText + " detected on closed candles"
                           : "Waiting for " + IntegerToString(InpConfirmBars) + " closed candles in one direction";

      int fileHandle = FileOpen(InpExportFile,
                                FILE_WRITE | FILE_TXT | FILE_COMMON | FILE_ANSI);
      if(fileHandle != INVALID_HANDLE)
      {
         string json = "{\"connected\":true,"
                       "\"symbol\":\"" + _Symbol + "\","
                       "\"timeframe\":\"" + EnumToString((ENUM_TIMEFRAMES)_Period) + "\","
                       "\"status\":\"" + signalStatus + "\","
                       "\"direction\":\"" + directionText + "\","
                       "\"message\":\"" + messageText + "\","
                       "\"updatedAt\":\"" + TimeToString(time[closedBar], TIME_DATE|TIME_MINUTES) + "\"}";
         FileWriteString(fileHandle, json);
         FileClose(fileHandle);
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
