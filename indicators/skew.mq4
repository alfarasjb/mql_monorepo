

#include <MovingAverages.mqh>
#include <MAIN/math.mqh>

#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property version   "1.00"
#property strict
#property indicator_separate_window

#property indicator_buffers   1
#property indicator_plots     1 
#property indicator_label1    "Skew"
#property indicator_type1     DRAW_LINE 
#property indicator_color1    clrYellow
#property indicator_style1    STYLE_SOLID
#property indicator_width1    1 

#property indicator_label2    "Rolling SDEV"
#property indicator_type2     DRAW_LINE 
#property indicator_color2    clrYellow
#property indicator_style2    STYLE_SOLID
#property indicator_width2    1 
#property indicator_level1     2
#property indicator_level2     -2
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
input    int      InpWindow   = 3;
input    int      InpShift    = 0; 

double      SkewBuffer[], SDevBuffer[], MeanBuffer[], DiffBuffer[], CloseBuffer[], AbsoluteSkew[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   IndicatorBuffers(indicator_buffers);
   IndicatorDigits(Digits + 2);
   //SetIndexBuffer(0, SkewBuffer, INDICATOR_DATA);
   SetIndexBuffer(0, AbsoluteSkew, INDICATOR_DATA);
   
   SetIndexStyle(0, indicator_type1, indicator_style1, indicator_width1, indicator_color1);
   SetIndexLabel(0, indicator_label1);
   
   
   
   SetIndexDrawBegin(0, 0);
   IndicatorShortName("Skew");
   
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
   //ArraySetAsSeries(SDevBuffer, false);
   //ArraySetAsSeries(SkewBuffer, false);
   ArraySetAsSeries(AbsoluteSkew, false);
   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;
   for(int i=limit; i<rates_total; i++){
      AbsoluteSkew[i] = CalculateSkew(i, InpWindow, close);
      //SkewBuffer[i] = CalculateStandardScore(i, InpWindow, AbsoluteSkew);
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

