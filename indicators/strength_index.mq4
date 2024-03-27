
#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_label1  "Normalized Strength Index"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrGray 
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_level1     5
#property indicator_level2     -5
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
#property indicator_label2 "Absolute Strength Index"
#property indicator_color2 clrNONE

#include <MAIN/math.mqh>
input    int      InpWindow   = 50;
double      StrengthIndexBuffer[], AbsoluteStrengthIndexBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   IndicatorDigits(Digits + 1);
   SetIndexBuffer(0, StrengthIndexBuffer);
   SetIndexLabel(0, indicator_label1);
   SetIndexStyle(0, indicator_style1);
   
   SetIndexBuffer(1, AbsoluteStrengthIndexBuffer);
   SetIndexLabel(1, indicator_label2);
   SetIndexDrawBegin(0, 0);
   IndicatorShortName("Strength Index");
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   
   ArraySetAsSeries(StrengthIndexBuffer, false);
   ArraySetAsSeries(AbsoluteStrengthIndexBuffer, false);
   
   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1; 
   
   for (int i = limit; i < rates_total; i++) {
      AbsoluteStrengthIndexBuffer[i]     = CalculateRatio(i, open, high, low, close);
      StrengthIndexBuffer[i]  = CalculateStandardScore(i, InpWindow, AbsoluteStrengthIndexBuffer);
   }
  
  
   return(rates_total);
  }
//+------------------------------------------------------------------+

double   CalculateRatio(
   int position, 
   const double &open[], 
   const double &high[], 
   const double &low[], 
   const double &close[]) {
   
   // calculate directional ratio
   
   // long vs short 
   
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);
   
   double open_price    = open[position];
   double close_price   = close[position];
   double body          = MathAbs(close_price - open_price);
   double diff          = close_price > open_price ? high[position] - close_price : low[position] - close_price;
   if (diff == 0) return 0;
   double ratio = MathPow(body, 2) / diff; 
   return ratio;
}