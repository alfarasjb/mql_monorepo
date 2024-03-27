#include "utilities.mqh"

class CTradeOps{

   protected:
   private:
      string            TRADE_SYMBOL;
      int               TRADE_MAGIC;
      
      
   public: 
      
      CTradeOps() {};
      ~CTradeOps() {}
      
      void              SYMBOL(string symbol) { TRADE_SYMBOL = symbol; }
      void              MAGIC(int magic)      { TRADE_MAGIC = magic; }
      
      string            SYMBOL()             { return TRADE_SYMBOL; }
      int               MAGIC()              { return TRADE_MAGIC; }
      
      
      
      int               OP_OrdersCloseAll();
      int               OP_CloseTrade(int ticket);
      int               OP_OrderOpen(string symbol, ENUM_ORDER_TYPE order_type, double volume, double price, double sl, double tp, string comment, datetime expiration = 0);
      bool              OP_TradeMatch(int index);
      int               OP_OrderSelectByTicket(int ticket);
      int               OP_OrderSelectByIndex(int index);
      int               OP_HistorySelectByIndex(int index);
      int               OP_ModifySL(double sl);
      int               OP_ModifyTP(double tp);
      int               OP_OrdersCloseBatch(int &orders[]);
      
      double            util_market_spread();
      double            util_tick_val();
      double            util_trade_pts();
      double            util_last_candle_open();
      double            util_last_candle_close();    
      double            util_entry_candle_open();
      
      double            price_ask();
      double            price_bid();
      
      bool              OrderIsPending(int ticket);    
      
      
      int               PopOrderArray(int &tickets[]);  
};

double            CTradeOps::price_ask(void)             { return SymbolInfoDouble(Symbol(), SYMBOL_ASK); }
double            CTradeOps::price_bid(void)             { return SymbolInfoDouble(Symbol(), SYMBOL_BID); }


double            CTradeOps::util_market_spread(void)    { return MarketInfo(Symbol(), MODE_SPREAD); }
double            CTradeOps::util_tick_val(void)         { return MarketInfo(Symbol(), MODE_TICKVALUE); }
double            CTradeOps::util_trade_pts(void)        { return MarketInfo(Symbol(), MODE_POINT); }

int               PosTotal()                  { return OrdersTotal(); }
int               PosTicket()                 { return OrderTicket(); }
double            PosLots()                   { return OrderLots(); }
string            PosSymbol()                 { return OrderSymbol(); }
int               PosMagic()                  { return OrderMagicNumber(); }
datetime          PosOpenTime()               { return OrderOpenTime(); }
datetime          PosCloseTime()              { return OrderCloseTime(); }
double            PosOpenPrice()              { return OrderOpenPrice(); }
double            PosClosePrice()             { return OrderClosePrice(); }
double            PosProfit()                 { return (OrderProfit() + OrderCommission() + OrderSwap()); }
ENUM_ORDER_TYPE   PosOrderType()              { return (ENUM_ORDER_TYPE)OrderType(); }
double            PosSL()                     { return OrderStopLoss(); }
double            PosTP()                     { return OrderTakeProfit(); }
double            PosCommission()             { return MathAbs(OrderCommission()); }
double            PosSwap()                   { return MathAbs(OrderSwap()); }
int               PosHistTotal()              { return OrdersHistoryTotal(); }
string            PosComment()                { return OrderComment(); }


int CTradeOps::OP_CloseTrade(int ticket) {
   int t = OP_OrderSelectByTicket(ticket);
   
   double close_price=0;
   
   switch(PosOrderType()){
      case ORDER_TYPE_BUY: close_price = price_bid(); break;
      case ORDER_TYPE_SELL: close_price = price_ask(); break;
   }
   
   int c;
   switch(PosOrderType()) {
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         c = OrderClose(PosTicket(), PosLots(), close_price, 3);
         if (!c) PrintFormat("%s: ORDER CLOSE FAILED. TICKET: %i, ERROR: %i", __FUNCTION__, PosTicket(), GetLastError());
         break;
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_LIMIT:
         
         c = OrderDelete(PosTicket());
         if (!c) PrintFormat("%s: ORDER DELETE FAILED. TICKET: %i, ERROR: %i", __FUNCTION__, PosTicket(), GetLastError());
         break;
      default:
         c = -1;
         break;
   }
   
   
   return c;  
}

int CTradeOps::OP_OrderOpen(
   string symbol,
   ENUM_ORDER_TYPE order_type,
   double volume,
   double price,
   double sl,
   double tp, 
   string comment,
   datetime expiration = 0){
   
   int ticket = OrderSend(Symbol(), order_type, NormalizeDouble(volume, 2), price, 3, sl, tp, comment, MAGIC(), expiration, clrNONE);
   return ticket;
   return 1;
}


int      CTradeOps::OP_OrdersCloseAll(void) {
   int open_positions = PosTotal();
   int tickets_to_close[];
   for (int i = 0; i < open_positions; i++) {
      int s = OP_OrderSelectByIndex(i);
      if (!OP_TradeMatch(i)) continue; 
      //if (OrderIsPending(PosTicket())) continue;
      int size = ArraySize(tickets_to_close);
      ArrayResize(tickets_to_close, size + 1);
      tickets_to_close[size] = PosTicket();
   }
   
   int num_tickets = ArraySize(tickets_to_close);
   int closed     = 0;
   for (int j = 0; j < num_tickets; j ++){
      int c = OP_CloseTrade(tickets_to_close[j]);
      if (c > 0) closed++;
   }
   return closed;
}

int      CTradeOps::OP_OrdersCloseBatch(int &orders[]) {

   int num_orders    = ArraySize(orders);
   if (num_orders <= 0) return 0; 
   
   int ticket = orders[0]; // first in queue
   
   int c       = OP_CloseTrade(orders[0]);
   if (c)      PrintFormat("%s: Trade Closed. Ticket: %i", __FUNCTION__, ticket);
   int a       = PopOrderArray(orders);
   if (a > num_orders) return -1;
   //OP_OrdersCloseBatch(orders);
   
   return OP_OrdersCloseBatch(orders);
}

int      CTradeOps::PopOrderArray(int &tickets[]) {
   int   temp[];
   int   size = ArraySize(tickets) - 1;
   ArrayResize(temp, size);
   ArrayCopy(temp, tickets, 0, 1);
   ArrayFree(tickets);
   ArrayCopy(tickets, temp);
   return ArraySize(tickets);
}



bool     CTradeOps::OP_TradeMatch(int index) {
   
   int t = OP_OrderSelectByIndex(index);
   if (PosMagic() != MAGIC()) return false;
   if (PosSymbol() != SYMBOL()) return false;
   return true;

}

bool     CTradeOps::OrderIsPending(int ticket) {
   int s = OP_OrderSelectByTicket(ticket);
   
   if (PosOrderType() > 1) return true; 
   return false;
}

int      CTradeOps::OP_ModifySL(double sl) {
   
   if (sl == PosSL()) return 0; 
   
   int m = OrderModify(PosTicket(), PosOpenPrice(), sl, PosTP(), 0);
   return m;

}

int CTradeOps::OP_OrderSelectByTicket(int ticket)        { return OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); }
int CTradeOps::OP_OrderSelectByIndex(int index)          { return OrderSelect(index, SELECT_BY_POS, MODE_TRADES); }
int CTradeOps::OP_HistorySelectByIndex(int index)        { return OrderSelect(index, SELECT_BY_POS, MODE_HISTORY); }