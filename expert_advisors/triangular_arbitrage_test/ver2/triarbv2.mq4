//+------------------------------------------------------------------+
//|                                                     triarbv2.mq4 |
//|                             Copyright 2023, Jay Benedict Alfaras |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <B63/Generic.mqh>


/*
1. identify mispriced cross -> implied vs market
2. identify values in number of contracts

cross: AUDNZD
top: AUDUSD
bottom: NZDUSD 

implied = AUDUSD / NZDUSD
market = AUDNZD 

process: 

I. LONG AUDNZD: 
Buy AUD 100000 Contracts at market price (1.06 hypothetically)
1 AUD = 1.06 NZD 

100000 AUD * (1.06 NZD / 1AUD) = 106000
Sell NZD 106000 Contracts 

AUDNZD POSITION: Long: 100000 Contracts

0.61 NZDUSD 
II. Cancel the NZD (buyback)
Buy NZD 106000 @ 0.61NZDUSD 
1 NZD = 0.61 USD
106000 NZD * ( 0.61 USD / 1 NZD) = 64600  
Sell USD 64600 Contracts

NZDUSD POSITION: Long: 106000 Contracts

III. Cancel the USD (buyback)
0.65 AUDUSD 

Sell AUD 100000
1 AUD = 0.65 USD  

100000 AUD * (0.65 USD / 1 AUD ) = 65000 

BUY USD 65000 Contracts

Profit: 400 USD

AUDUSD POSITION: Sell: 100000 Contracts

---- ALL POSITIONS ----- 
AUDNZD Long 100000 Contracts -> 1 Lot 
NZDUSD Long 106000 Contracts -> 1.06 Lot 
AUDUSD Short 100000 Contracts -> 1 Lot 

1. Get transaction by number of contracts purchased
2. Scale via contract size

*/

string cross = "AUDNZD";
string upper = "AUDUSD";
string lower = "NZDUSD";
double default_contracts = 100000;

struct OrderProfile{
   string symbol;
   double base_contracts;
   double quote_contracts;
   ENUM_ORDER_TYPE order;
   double volume;
   
   void create_profile(string sym, double base, double quote, ENUM_ORDER_TYPE ord){
      symbol = sym;
      base_contracts = base;
      quote_contracts = quote;
      order = ord;
      volume = base / 100000;
   }
};

struct Triangle{
   OrderProfile cross_currency;
   OrderProfile base_currency;
   OrderProfile quote_currency;
   
   OrderProfile order_queue[];
   
   void create_triangle(OrderProfile &cross, OrderProfile &base, OrderProfile &quote){
      cross_currency = cross;
      base_currency = base;
      quote_currency = quote;
      
      ArrayResize(order_queue, 3);
      order_queue[0] = cross_currency;
      order_queue[1] = base_currency;
      order_queue[2] = quote_currency;
   }
};


Triangle tri_arb;

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
   if(IsNewCandle()){
      if (OrdersTotal() == 0){
         check_gap();
      }
      else{
         close_orders();
      }
   }
   
  }
//+------------------------------------------------------------------+

void check_gap(){
   double upper_price = iClose(upper, PERIOD_CURRENT, 0);
   double lower_price = iClose(lower, PERIOD_CURRENT, 0);
   double cross_price = iClose(cross, PERIOD_CURRENT, 0);
   double implied_cross = upper_price / lower_price;
   
   if (implied_cross > cross_price){
      Print("GAP: SELL");
      // sell the cross
      
      // get base contracts 
       double base_contracts = default_contracts;
      double quote_contracts = base_contracts * cross_price;
      
      OrderProfile ord_profile;
      ord_profile.create_profile(cross, base_contracts, quote_contracts, ORDER_TYPE_BUY);
      
      
      
      double base_profile_base = ord_profile.quote_contracts;
      double base_profile_quote = base_profile_base * lower_price;
      OrderProfile base_profile;
      base_profile.create_profile(lower, base_profile_base, base_profile_quote, ORDER_TYPE_BUY);
      
      double quote_profile_base = ord_profile.base_contracts;
      double quote_profile_quote = quote_profile_base * upper_price; 
      OrderProfile quote_profile;
      quote_profile.create_profile(upper, quote_profile_base, quote_profile_quote, ORDER_TYPE_SELL);
      
      tri_arb.create_triangle(ord_profile, base_profile, quote_profile);
      execute_trades(tri_arb);
   }
   
   if (cross_price > implied_cross){
      Print("GAP: BUY");
      // buy the cross
       double base_contracts = default_contracts;
      double quote_contracts = base_contracts * cross_price;
      
      OrderProfile ord_profile;
      ord_profile.create_profile(cross, base_contracts, quote_contracts, ORDER_TYPE_SELL);
      
      
      
      double base_profile_base = ord_profile.quote_contracts;
      double base_profile_quote = base_profile_base * lower_price;
      OrderProfile base_profile;
      base_profile.create_profile(lower, base_profile_base, base_profile_quote, ORDER_TYPE_SELL);
      
      double quote_profile_base = ord_profile.base_contracts;
      double quote_profile_quote = quote_profile_base * upper_price; 
      OrderProfile quote_profile;
      quote_profile.create_profile(upper, quote_profile_base, quote_profile_quote, ORDER_TYPE_BUY);
      
      tri_arb.create_triangle(ord_profile, base_profile, quote_profile);
      execute_trades(tri_arb);
   }
}

void execute_trades(Triangle &tri){
   int trades = ArraySize(tri.order_queue);
   
   for (int i = 0; i < trades; i ++){
      OrderProfile profile = tri.order_queue[i];
      send_order(profile);
   }
}

int send_order(OrderProfile &profile){
   ENUM_ORDER_TYPE ord = profile.order == ORDER_TYPE_BUY ? Ask : Bid;
   int t = OrderSend(profile.symbol, profile.order, profile.volume, ord, 3, 0, 0, NULL, 0, 0, clrNONE);
   return t;
}

int close_orders(){
   int orders = OrdersTotal();
  
   for (int i = 0; i < orders; i++){
      int t = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      double close_price = OrderType() == ORDER_TYPE_BUY ? Bid : Ask;
      int c = OrderClose(OrderTicket(), OrderLots(), close_price, 3, clrNONE);
   }
   return 1;
}