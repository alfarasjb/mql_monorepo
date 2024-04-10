
/*
   This file contains a script for a generic Moving Average
   Crossover trading algorithm.
   
   Sends a BUY signal when Fast MA is above Slow MA, and vice versa. 
   
   DISCLAIMER: This script does not guarantee future profits, and is 
   created for demonstration purposes only. Do not use this script 
   with live funds. 
*/

#include <B63/Generic.mqh> 
#include "trade_ops.mqh"



enum ENUM_SIGNAL {
   SIGNAL_LONG,
   SIGNAL_SHORT,
   SIGNAL_NONE
}; 


input int      InpMagic                   =  111111;
input int      InpMASlowPeriod            = 10;
input int      InpMAFastPeriod            = 50; 
input ENUM_MA_METHOD InpMAMethod          = MODE_SMA;

class CMACrossTrade : public CTradeOps {
private:
   int      ma_slow_period_, ma_fast_period_; 
   ENUM_MA_METHOD    ma_method_; 

public:
   
   CMACrossTrade();
   ~CMACrossTrade(); 
   
            int               MASlowPeriod()    const { return ma_slow_period_; }
            int               MAFastPeriod()    const { return ma_fast_period_; }
            ENUM_MA_METHOD    MAMethod()        const { return ma_method_; }
            
            
            void              Stage();
            ENUM_SIGNAL       Signal(); 
            double            MASlowValue();
            double            MAFastValue(); 
            int               SendOrder(ENUM_SIGNAL signal);
            int               ClosePositions(ENUM_ORDER_TYPE order_type); 
            bool              DeadlineReached();
}; 

CMACrossTrade::CMACrossTrade() 
   : CTradeOps(Symbol(), InpMagic)
   , ma_slow_period_(InpMASlowPeriod)
   , ma_fast_period_(InpMAFastPeriod)
   , ma_method_(InpMAMethod) {}
   
CMACrossTrade::~CMACrossTrade() {}




bool        CMACrossTrade::DeadlineReached() {
   return TimeHour(TimeCurrent()) >= 20; 
}

void        CMACrossTrade::Stage() {
   if (DeadlineReached()) {
      ClosePositions(ORDER_TYPE_BUY);
      ClosePositions(ORDER_TYPE_SELL); 
   }
   

   ENUM_SIGNAL signal = Signal();
   if (signal == SIGNAL_NONE) return; 
   SendOrder(signal); 
   
   
}

ENUM_SIGNAL CMACrossTrade::Signal() {
   double ma_slow = MASlowValue(); 
   double ma_fast = MAFastValue(); 
   
   if (ma_fast > ma_slow) return SIGNAL_LONG;
   if (ma_fast < ma_slow) return SIGNAL_SHORT;
   return SIGNAL_NONE; 
}

double      CMACrossTrade::MASlowValue() {
   return iMA(Symbol(), PERIOD_CURRENT, MASlowPeriod(), 0, MAMethod(), PRICE_CLOSE, 1); 
}

double      CMACrossTrade::MAFastValue() {
   return iMA(Symbol(), PERIOD_CURRENT, MAFastPeriod(), 0, MAMethod(), PRICE_CLOSE, 1); 
}

int         CMACrossTrade::SendOrder(ENUM_SIGNAL signal) {
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

int         CMACrossTrade::ClosePositions(ENUM_ORDER_TYPE order_type) {
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

CMACrossTrade     ma_cross_trade; 

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
      ma_cross_trade.Stage(); 
   }
   
  }
//+------------------------------------------------------------------+
