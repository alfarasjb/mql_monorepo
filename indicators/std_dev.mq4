
#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "Standard Deviation"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2 "Rolling Max Volatility"
#property indicator_type2 DRAW_LINE 
#property indicator_color2 clrDodgerBlue 
#property indicator_style2 STYLE_SOLID 
#property indicator_width2 1 

#include <MovingAverages.mqh>
#include <MAIN/math.mqh>
input    int      InpWindow      = 10; 
input    int      InpMaxWindow   = 50;
input    int      InpShift       = 0;
double      SDevBuffer[], MeanBuffer[], CloseBuffer[];
double      BarBuffer[];
double      RollingMaxSdevBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
   IndicatorBuffers(indicator_buffers);
   IndicatorDigits(Digits + 4);
   SetIndexBuffer(0, SDevBuffer, INDICATOR_DATA);
   SetIndexStyle(0, indicator_type1, indicator_style1, indicator_width1, indicator_color1);
   SetIndexLabel(0, indicator_label1);
   
   SetIndexBuffer(1, RollingMaxSdevBuffer, INDICATOR_DATA);
   SetIndexStyle(1, indicator_type2, indicator_style2, indicator_width2, indicator_color2);
   SetIndexLabel(1, indicator_label2);
   
   
   SetIndexDrawBegin(0, 0);
   IndicatorShortName("Standard Deviation");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, // size of input time series 
                const int prev_calculated, // number of handled bars at the previous call
                const datetime &time[], 
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
   ArraySetAsSeries(SDevBuffer, false);
   ArraySetAsSeries(RollingMaxSdevBuffer, false);
   ArraySetAsSeries(close, false);
   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;
   
   for(int i=limit; i<rates_total; i++){
      SDevBuffer[i] = CalculateStandardDeviation(i, InpWindow, close);
      RollingMaxSdevBuffer[i] = CalculateRollingMaxStdDev(i, InpMaxWindow, SDevBuffer);
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double      CalculateRollingMaxStdDev(int position, int periods, const double &price[]) {
   
   double max = 0; 
   
   if (ArrayGetAsSeries(price)) ArraySetAsSeries(price, false);
   
   if (position >= periods) {
      for (int i = 0; i < periods; i++) {
         double x    = price[position - i];
         max = max == 0 ? x : x > max ? x : max; 
      }
   }
   return max;

}

double      EXCalculateStandardDeviation(int position, int periods, const double &price[]) {

   double sum = 0;
   bool price_as_series = ArrayGetAsSeries(price);
   if (price_as_series) ArraySetAsSeries(price, false);
   double mean = SimpleMA(position, periods, price);
   
   if (position >= periods) {
      for (int i = 0; i < periods; i++) {
         double x_i = price[position-i];
         double diff = MathPow(x_i - mean, 2);
         sum += diff;
      }
   }
   
   double sdev = MathSqrt(sum / periods); 
   return sdev;   
}

