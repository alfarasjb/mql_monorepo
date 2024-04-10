
/*
   This file contains a script for a generic RSI trading algorithm.
   
   Returns a BUY signal when the RSI is oversold, and a SELL signal 
   when the RSI is overbought.
   
   DISCLAIMER: This script does not guarantee future profits. Do not 
   use this script with live funds. 
*/

#include <B63/Generic.mqh> 
#include "trade_ops.mqh"

enum ENUM_RSI_REGION {
   RSI_OVERBOUGHT,
   RSI_OVERSOLD,
   RSI_NEUTRAL
};

enum ENUM_SIGNAL {
   SIGNAL_LONG,
   SIGNAL_SHORT,
   SIGNAL_NONE
}; 


input int      InpMagic                   =  111111;
input int      InpRsiPeriod               = 10;
input int      InpRsiShift                = 1; 
input double   InpRsiOverboughtThreshold  = 70.0;
input double   InpRsiOversoldThreshold    = 30.0;

class CRSITrade : public CTradeOps {
private:
   int      rsi_period_, rsi_shift_; 
   double   rsi_overbought_threshold_, rsi_oversold_threshold_; 
public:

   CRSITrade();
   ~CRSITrade(); 
            
            int               RsiPeriod()                const { return rsi_period_; }
            int               RsiShift()                 const { return rsi_shift_; }
            double            RsiOverboughtThreshold()   const { return rsi_overbought_threshold_; }
            double            RsiOversoldThreshold()     const { return rsi_oversold_threshold_; }
   
            void              Stage();
            ENUM_SIGNAL       Signal(); 
            double            RsiValue(); 
            ENUM_RSI_REGION   RsiRegion(); 
            int               SendOrder(ENUM_SIGNAL signal);
            int               ClosePositions(ENUM_ORDER_TYPE order_type); 
            bool              DeadlineReached(); 
}; 


 
CRSITrade::CRSITrade() 
   : CTradeOps(Symbol(), InpMagic)
   , rsi_period_ (InpRsiPeriod)
   , rsi_shift_ (InpRsiShift)
   , rsi_overbought_threshold_ (InpRsiOverboughtThreshold)
   , rsi_oversold_threshold_ (InpRsiOversoldThreshold)  {}

CRSITrade::~CRSITrade() {}

ENUM_SIGNAL CRSITrade::Signal() {
   ENUM_RSI_REGION region  = RsiRegion(); 
   switch(region) {
      case RSI_OVERBOUGHT: return SIGNAL_SHORT; 
      case RSI_OVERSOLD:   return SIGNAL_LONG;
   }
   return SIGNAL_NONE; 
}

bool        CRSITrade::DeadlineReached() {
   return TimeHour(TimeCurrent()) >= 20; 
}

void        CRSITrade::Stage() {
   if (DeadlineReached()) {
      ClosePositions(ORDER_TYPE_BUY);
      ClosePositions(ORDER_TYPE_SELL); 
   }
   

   ENUM_SIGNAL signal = Signal();
   if (signal == SIGNAL_NONE) return; 
   SendOrder(signal); 
   
   
}

int         CRSITrade::SendOrder(ENUM_SIGNAL signal) {
   ENUM_ORDER_TYPE order_type;
   double entry_price; 
   switch(signal) {
      case SIGNAL_LONG:
         order_type  = ORDER_TYPE_BUY;
         entry_price = UTIL_PRICE_ASK();
         ClosePositions(ORDER_TYPE_SELL); 
         break;
      case SIGNAL_SHORT:
         order_type  = ORDER_TYPE_SELL;
         entry_price = UTIL_PRICE_BID(); 
         ClosePositions(ORDER_TYPE_BUY);
         break;
      case SIGNAL_NONE:
         return -1; 
      default:
         return -1; 
   }
   return OP_OrderOpen(Symbol(), order_type, 0.01, entry_price, 0, 0, NULL);
   
}

int         CRSITrade::ClosePositions(ENUM_ORDER_TYPE order_type) {
   if (PosTotal() == 0) return 0; 
   
   CPoolGeneric<int> *tickets = new CPoolGeneric<int>(); 
   for (int i = 0; i < PosTotal(); i++) {
      int s = OP_OrderSelectByIndex(i); 
      int ticket = PosTicket(); 
      if (!OP_TradeMatchTicket(ticket)) continue; 
      if (PosOrderType() != order_type) continue; 
      tickets.Append(ticket); 
   }
   int extracted[];
   int num_extracted = tickets.Extract(extracted); 
   OP_OrdersCloseBatch(extracted); 
   delete tickets;
   return num_extracted; 
}

double      CRSITrade::RsiValue() {
   return iRSI(Symbol(), PERIOD_CURRENT, 10, PRICE_CLOSE, 1); 
}

ENUM_RSI_REGION   CRSITrade::RsiRegion() {
   if (RsiValue() > RsiOverboughtThreshold())   return RSI_OVERBOUGHT; 
   if (RsiValue() < RsiOversoldThreshold())     return RSI_OVERSOLD; 
   return RSI_NEUTRAL;  
}

CRSITrade      rsi_trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (IsNewCandle()) {
      rsi_trade.Stage();
      
   }
   
  }
//+------------------------------------------------------------------+
