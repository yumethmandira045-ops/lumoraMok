//+------------------------------------------------------------------+
//| Lumora Market Signal - filtered M1 trend approximation           |
//| Not the proprietary/original indicator from the user's chart.    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
#property indicator_label1  "Bull Trend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  3
#property indicator_label2  "Bear Trend"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  3
#property indicator_label3  "BUY"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrBlue
#property indicator_width3  2
#property indicator_label4  "SELL"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  2

input int      InpATRPeriod       = 10;    // ATR period
input double   InpATRMultiplier   = 2.0;   // Trend band multiplier
input int      InpConfirmBars     = 3;     // Same-direction CLOSED bars
input int      InpADXPeriod       = 14;    // Trend-strength period
input double   InpMinADX          = 18.0;  // Minimum ADX; higher = stricter
input int      InpFastEMA         = 9;     // Fast EMA
input int      InpSlowEMA         = 21;    // Slow EMA
input double   InpMaxExtensionATR = 1.8;   // Reject late entries beyond EMA by ATR multiple
input double   InpMinBodyATR      = 0.10;  // Reject tiny signal candle bodies
input bool     InpExportSignal    = true;  // Export JSON to Common Files
input string   InpExportFile      = "LumoraMarketSignal.json";

double BullBuffer[], BearBuffer[], BuyBuffer[], SellBuffer[];
double TrueRange[], ATRValues[], BasicUpper[], BasicLower[], FinalUpper[], FinalLower[];
double FastEMA[], SlowEMA[], ADXValues[];
int Trend[];
int adxHandle = INVALID_HANDLE;

int OnInit()
{
   if(InpATRPeriod<1 || InpATRMultiplier<=0 || InpConfirmBars<1 || InpADXPeriod<2 || InpMinADX<0 || InpFastEMA<1 || InpSlowEMA<=InpFastEMA || InpMaxExtensionATR<=0 || InpMinBodyATR<0)
      return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,BullBuffer,INDICATOR_DATA); SetIndexBuffer(1,BearBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BuyBuffer,INDICATOR_DATA); SetIndexBuffer(3,SellBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BullBuffer,false); ArraySetAsSeries(BearBuffer,false); ArraySetAsSeries(BuyBuffer,false); ArraySetAsSeries(SellBuffer,false);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE); PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE); PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(2,PLOT_ARROW,233); PlotIndexSetInteger(3,PLOT_ARROW,234);
   adxHandle=iADX(_Symbol,(ENUM_TIMEFRAMES)_Period,InpADXPeriod);
   if(adxHandle==INVALID_HANDLE) { Print("Lumora: could not create ADX handle. Error ",GetLastError()); return INIT_FAILED; }
   IndicatorSetString(INDICATOR_SHORTNAME,"Lumora Market Signal (Filtered ATR Trend)");
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) { if(adxHandle!=INVALID_HANDLE) IndicatorRelease(adxHandle); }

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   if(rates_total<MathMax(InpSlowEMA,InpATRPeriod)+InpADXPeriod+5) return 0;
   ArraySetAsSeries(time,false); ArraySetAsSeries(open,false); ArraySetAsSeries(high,false); ArraySetAsSeries(low,false); ArraySetAsSeries(close,false);
   ArrayResize(TrueRange,rates_total); ArrayResize(ATRValues,rates_total); ArrayResize(BasicUpper,rates_total); ArrayResize(BasicLower,rates_total); ArrayResize(FinalUpper,rates_total); ArrayResize(FinalLower,rates_total); ArrayResize(Trend,rates_total); ArrayResize(FastEMA,rates_total); ArrayResize(SlowEMA,rates_total); ArrayResize(ADXValues,rates_total);
   ArraySetAsSeries(ADXValues,false);
   int copied=CopyBuffer(adxHandle,0,0,rates_total,ADXValues);
   if(copied<rates_total) return prev_calculated;
   double af=2.0/(InpFastEMA+1.0), as=2.0/(InpSlowEMA+1.0);
   for(int i=0;i<rates_total;i++)
   {
      BullBuffer[i]=EMPTY_VALUE; BearBuffer[i]=EMPTY_VALUE; BuyBuffer[i]=EMPTY_VALUE; SellBuffer[i]=EMPTY_VALUE;
      if(i==0) { TrueRange[i]=high[i]-low[i]; FastEMA[i]=close[i]; SlowEMA[i]=close[i]; }
      else { TrueRange[i]=MathMax(high[i]-low[i],MathMax(MathAbs(high[i]-close[i-1]),MathAbs(low[i]-close[i-1]))); FastEMA[i]=af*close[i]+(1-af)*FastEMA[i-1]; SlowEMA[i]=as*close[i]+(1-as)*SlowEMA[i-1]; }
      if(i==0) ATRValues[i]=TrueRange[i]; else if(i<InpATRPeriod) ATRValues[i]=(ATRValues[i-1]*i+TrueRange[i])/(i+1.0); else ATRValues[i]=(ATRValues[i-1]*(InpATRPeriod-1.0)+TrueRange[i])/InpATRPeriod;
      double mid=(high[i]+low[i])/2.0; BasicUpper[i]=mid+InpATRMultiplier*ATRValues[i]; BasicLower[i]=mid-InpATRMultiplier*ATRValues[i];
      if(i==0) { FinalUpper[i]=BasicUpper[i]; FinalLower[i]=BasicLower[i]; Trend[i]=(close[i]>=mid?1:-1); }
      else { FinalUpper[i]=(BasicUpper[i]<FinalUpper[i-1]||close[i-1]>FinalUpper[i-1])?BasicUpper[i]:FinalUpper[i-1]; FinalLower[i]=(BasicLower[i]>FinalLower[i-1]||close[i-1]<FinalLower[i-1])?BasicLower[i]:FinalLower[i-1]; Trend[i]=Trend[i-1]; if(Trend[i-1]<0&&close[i]>FinalUpper[i-1]) Trend[i]=1; else if(Trend[i-1]>0&&close[i]<FinalLower[i-1]) Trend[i]=-1; }
      if(Trend[i]>0) { BullBuffer[i]=FinalLower[i]; if(i>0&&Trend[i-1]<0) BuyBuffer[i]=low[i]-ATRValues[i]*0.25; }
      else { BearBuffer[i]=FinalUpper[i]; if(i>0&&Trend[i-1]>0) SellBuffer[i]=high[i]+ATRValues[i]*0.25; }
   }
   if(InpExportSignal)
   {
      int b=rates_total-2, direction=Trend[b], same=0;
      for(int j=b;j>=0&&Trend[j]==direction;j--) same++;
      bool emaAligned=(direction>0)?(FastEMA[b]>SlowEMA[b]&&FastEMA[b]>FastEMA[MathMax(0,b-2)]):(FastEMA[b]<SlowEMA[b]&&FastEMA[b]<FastEMA[MathMax(0,b-2)]);
      bool adxOK=(ADXValues[b]>=InpMinADX);
      bool bodyOK=(MathAbs(close[b]-open[b])>=ATRValues[b]*InpMinBodyATR);
      bool extensionOK=(ATRValues[b]>0 && MathAbs(close[b]-FastEMA[b])<=ATRValues[b]*InpMaxExtensionATR);
      bool enoughBars=(same>=InpConfirmBars);
      bool good=(enoughBars&&emaAligned&&adxOK&&bodyOK&&extensionOK);
      string directionText=(direction>0)?"UPTREND":"DOWNTREND";
      string reason="WAIT: " ;
      if(!enoughBars) reason+="need more closed trend candles";
      else if(!adxOK) reason+="weak/choppy trend (ADX below threshold)";
      else if(!emaAligned) reason+="EMA trend not aligned";
      else if(!bodyOK) reason+="weak candle body";
      else if(!extensionOK) reason+="price overextended; avoid late entry";
      else reason=directionText+" confirmed: ADX, EMA, candle and extension checks passed";
      string status=(good?"GOOD_TO_ON":"WAIT");
      int fh=FileOpen(InpExportFile,FILE_WRITE|FILE_TXT|FILE_COMMON|FILE_ANSI);
      if(fh!=INVALID_HANDLE)
      {
         string msg=(good?reason:reason);
         StringReplace(msg,"\\","\\\\"); StringReplace(msg,"\"","\\\"");
         string json="{\"connected\":true,\"symbol\":\""+_Symbol+"\",\"timeframe\":\""+EnumToString((ENUM_TIMEFRAMES)_Period)+"\",\"status\":\""+status+"\",\"direction\":\""+directionText+"\",\"message\":\""+msg+"\",\"adx\":"+DoubleToString(ADXValues[b],1)+",\"emaAligned\":"+(emaAligned?"true":"false")+",\"updatedAt\":\""+TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+"\"}";
         FileWriteString(fh,json); FileClose(fh);
      }
   }
   return rates_total;
}
//+------------------------------------------------------------------+
