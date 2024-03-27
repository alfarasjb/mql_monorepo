//+------------------------------------------------------------------+
//|                                                      z_score.mq4 |
//|                             Copyright 2023, Jay Benedict Alfaras |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#include <MovingAverages.mqh>
#include <MAIN/math.mqh>

#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "Z-Score"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_color2  clrNONE
#property indicator_color3  clrNONE

//--- indicator buffers



enum ENUM_SPREAD_MODE {
   MODE_SINGLE
};

enum ENUM_SPREAD_CALC_MODE {
   MODE_PRICE, MODE_DIFF
};

enum ENUM_PAIR_CALC_MODE {
   MODE_DIFFERENCE, MODE_RATIO
};


input int               InpWindow                  = 10;
input int               InpMAWindow                = 50;
input int               InpShift                   = 0;

//input string                  InpSep_2             = " ========== PAIR ==========";
//input string                  InpSecondarySymbol   = "EURUSD";
//input ENUM_PAIR_CALC_MODE     InpPairCalcMode      = MODE_DIFFERENCE;

#property indicator_level1     2
#property indicator_level2     -2
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT


double      ZScoreBuffer[], SpreadBuffer[], CandleBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorDigits(Digits + 1);
//--- indicator buffers mapping
   SetIndexBuffer(0,ZScoreBuffer);
   SetIndexLabel(0, "Z-Score");
   SetIndexStyle(0, indicator_type1);
   
   
   SetIndexBuffer(1, SpreadBuffer);
   SetIndexLabel(1, "Spread");
   SetIndexStyle(1, DRAW_NONE, EMPTY, EMPTY, clrNONE);
   
   SetIndexBuffer(2, CandleBuffer);
   SetIndexLabel(2, "Candle");
   SetIndexStyle(2, DRAW_NONE, EMPTY, EMPTY, clrNONE);
   
   
   
   SetIndexDrawBegin(0, 0);
   IndicatorShortName("Z-Score");
   
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
   ArraySetAsSeries(ZScoreBuffer, false);
   ArraySetAsSeries(SpreadBuffer, false);
   ArraySetAsSeries(CandleBuffer, false);
   
   ArraySetAsSeries(close, false);
   ArraySetAsSeries(open, false);
   
   int limit = prev_calculated == 0 ? 0 : prev_calculated - 1;
   
   for (int i = limit; i < rates_total; i++){
      CandleBuffer[i] = close[i] - open[i];
      
      SpreadBuffer[i] = CalculateSpread(i, InpMAWindow, close);
      ZScoreBuffer[i] = CalculateStandardScore(i, InpWindow, SpreadBuffer);
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
