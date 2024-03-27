
#include <MovingAverages.mqh> 
#include <MAIN/math.mqh> 



#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_buffers 3 
#property indicator_plots 1 
#property indicator_separate_window
//#property indicator_chart_window
#property indicator_label1 "Day Open"
#property indicator_type1 DRAW_LINE 
#property indicator_color1 clrYellow 
#property indicator_style1 STYLE_SOLID 

#property indicator_color2 clrNONE
#property indicator_color3 clrNONE
input int InpWindow     = 20;


double   DayOpenBuffer[], DaySpreadBuffer[], NormalizedDaySpreadBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   //SetIndexBuffer(1, DayOpenBuffer);
   //SetIndexLabel(0, "Dates"); 
   //SetIndexStyle(0, indicator_type1);
   
   SetIndexBuffer(1, DaySpreadBuffer);
   SetIndexLabel(1, "Spread");
   SetIndexStyle(1, indicator_type1);
   
   SetIndexBuffer(0, NormalizedDaySpreadBuffer);
   SetIndexLabel(0, "Normalized");
   SetIndexStyle(0, indicator_type1);
   SetIndexDrawBegin(0, 0);
//---
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
//---
   ArraySetAsSeries(DaySpreadBuffer, false);
   ArraySetAsSeries(DayOpenBuffer, false);
   ArraySetAsSeries(time, false);
   ArraySetAsSeries(close, false);
   ArraySetAsSeries(NormalizedDaySpreadBuffer, false);
   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1; 
   
   for (int i = limit; i < rates_total; i++) {
      //DatesBuffer[i] = (double)iTime(NULL, PERIOD_CURRENT, i+1);
      //DayOpenBuffer[i] = CalculateDayOpen(i, time);
      DaySpreadBuffer[i] = CalculateDaySpread(i, time, close);
      NormalizedDaySpreadBuffer[i] = CalculateStandardScore(i, InpWindow, DaySpreadBuffer);
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double CalculateDaySpread(int position, const datetime &date[], const double &close[]) {
   
   if (ArrayGetAsSeries(date)) ArraySetAsSeries(date, false);
   if (ArrayGetAsSeries(close)) ArraySetAsSeries(close, false);
   
   string timestring = TimeToString(date[position], TIME_DATE);
   datetime target = StringToTime(timestring); 
   
   int shift = iBarShift(Symbol(), PERIOD_CURRENT, target);
   double open = iOpen(Symbol(), PERIOD_CURRENT, shift);
   
   double spread = close[position] - open;
   return spread;
}
