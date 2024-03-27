
#include <B63/TradeOperations.mqh>
CTradeOperations op();

class CTradeToolMain{
   protected:
   private:
      string         FIELD_SL, FIELD_TP, FIELD_VOL, FIELD_PENDING;
   public:
      string         SYMBOL;
      
      
      // INPUTS
      int            SL_INPUT, TP_INPUT;
      int            MAGIC_INPUT;
      int            POINTS_STEP_INPUT;
      
      // MARKET
      double         MAX_LOT, MIN_LOT, LOT_STEP, CONTRACT;
      int            DIGITS;
      
      // TRADE
      double         TRADE_ENTRY, TRADE_STOP, TRADE_TARGET;
      float          TRADE_VOLUME;
      bool           TRADE_SL_ON, TRADE_TP_ON, TRADE_VOL_ON;
      int            TRADE_STOP_POINTS, TRADE_TP_POINTS, TRADE_MAGIC_NUMBER;
      
      // ERRONEOUS
      double         ERR_TRADE_STOP, ERR_TRADE_TARGET, ERR_TRADE_VOLUME, ERR_TRADE_ENTRY;
      
      
      CTradeToolMain(double vol_input, int sl_input, int tp_input, int magic_input, int points_step_input);
      
      void           SetInputs(double vol_input, int sl_input, int tp_input, int magic_input, int points_step_input);
      void           SetMarketLimits();
      void           Update(double Entry, double Stop, double Target, double Vol, bool SLOn, bool TPOn, bool VolOn, int SLPoints, int TPPoints);
      void           TradeParams(ENUM_ORDER_TYPE ord);
      int            SendOrder(ENUM_ORDER_TYPE ord);
      int            Error(int e);
      
      
      // UTILITIES
      double         util_ask()                       { return SymbolInfoDouble(SYMBOL, SYMBOL_ASK); }
      double         util_bid()                       { return SymbolInfoDouble(SYMBOL, SYMBOL_BID); }
      double         util_get_values(string sparam)   { return StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT)); }
      double         util_point()                     { return SymbolInfoDouble(SYMBOL, SYMBOL_POINT); }
      
      string         util_invalid_order()             { return "Invalid Order Parameters for: "; }
      void           util_logger(string message)      { PrintFormat("LOGGER: %s", message); }
};

CTradeToolMain::CTradeToolMain(double vol_input, int sl_input, int tp_input, int magic_input, int points_step_input){

   SetInputs(vol_input, sl_input, tp_input, magic_input, points_step_input);
   
   FIELD_SL = "EDITSL";
   FIELD_TP = "EDITTP";
   FIELD_VOL = "EDITVOL";
   FIELD_PENDING = "EDITPENDING";
   
   SetMarketLimits();
}

void CTradeToolMain::SetInputs(double vol_input, int sl_input, int tp_input, int magic_input, int points_step_input){
   
   TRADE_VOLUME = vol_input;
   TRADE_ENTRY = 0;
   
   SL_INPUT  = sl_input; 
   TP_INPUT = tp_input; 
   
   MAGIC_INPUT = magic_input;
   POINTS_STEP_INPUT = points_step_input;

}


void CTradeToolMain::SetMarketLimits(void){
   SYMBOL = Symbol();
   MAX_LOT = SymbolInfoDouble(SYMBOL, SYMBOL_VOLUME_MAX);
   MIN_LOT = SymbolInfoDouble(SYMBOL, SYMBOL_VOLUME_MIN);
   LOT_STEP = SymbolInfoDouble(SYMBOL, SYMBOL_VOLUME_STEP);
   DIGITS = (int)SymbolInfoInteger(SYMBOL, SYMBOL_DIGITS);
   CONTRACT = SymbolInfoDouble(SYMBOL, SYMBOL_TRADE_CONTRACT_SIZE);  
   
}

void CTradeToolMain::Update(double Entry,double Stop,double Target,double Vol,bool SLOn,bool TPOn,bool VolOn,int SLPoints,int TPPoints){
   TRADE_ENTRY       = Entry;
   TRADE_STOP        = Stop;
   TRADE_TARGET      = Target;
   TRADE_VOLUME      = Vol;
   TRADE_SL_ON       = SLOn;
   TRADE_TP_ON       = TPOn;
   TRADE_VOL_ON      = VolOn;
   TRADE_STOP_POINTS = SLPoints;
   TRADE_TP_POINTS   = TPPoints;
   TRADE_MAGIC_NUMBER = MAGIC_INPUT;
}

void CTradeToolMain::TradeParams(ENUM_ORDER_TYPE ord){
   double sl = util_get_values(FIELD_SL);
   double tp = util_get_values(FIELD_TP);
   double vol = util_get_values(FIELD_VOL);
   double pending_price = util_get_values(FIELD_PENDING);
   
   double stop = 0;
   double target = 0;
   
   switch(ord){
      
         case 0: 
            stop = TRADE_SL_ON ? sl != 0 ? util_ask() - sl * util_point() : 0 : 0;
            target = TRADE_TP_ON ? tp != 0 ? util_ask() + tp * util_point() : 0 : 0;
            Update(util_ask(), stop, target, (float)vol, TRADE_SL_ON, TRADE_TP_ON, true,(int)sl, (int)tp);
            break; 
            
         case 1:
            stop = TRADE_SL_ON ? sl!= 0 ? util_bid() + sl * util_point() : 0 : 0;
            target = TRADE_TP_ON ? tp!= 0 ? util_bid() - tp * util_point() : 0 : 0;
            Update(util_bid(), stop, target, (float)vol, TRADE_SL_ON, TRADE_TP_ON, true, (int)sl, (int)tp);
            break;
            
         case 2: 
         case 4:
            stop = TRADE_SL_ON ? sl != 0 ? pending_price - sl * util_point() : 0 : 0;
            target = TRADE_TP_ON ? tp != 0 ? pending_price + tp * util_point() : 0 : 0;
            Update(pending_price, stop, target, (float)vol, TRADE_SL_ON, TRADE_TP_ON, true, (int)sl, (int)tp);
            break;
            
         case 3: 
         case 5:
            stop = TRADE_SL_ON ? sl != 0 ? pending_price + sl * util_point() : 0 : 0;
            target = TRADE_TP_ON ? tp != 0 ? pending_price - tp * util_point() : 0 : 0;
            Update(pending_price, stop, target, (float)vol, TRADE_SL_ON, TRADE_TP_ON, true, (int)sl, (int)tp);
            break;
            
       
         default:
            break;
      }
}

int CTradeToolMain::SendOrder(ENUM_ORDER_TYPE ord){
   double volume = util_get_values(FIELD_VOL);
   TradeParams(ord);
   
   int ticket = op.SendOrder(ord, volume, TRADE_ENTRY, TRADE_STOP, TRADE_TARGET, TRADE_MAGIC_NUMBER);
   
   if (ticket < 0){
      // update erroneous parameters 
      ERR_TRADE_STOP = TRADE_STOP;
      ERR_TRADE_TARGET = TRADE_TARGET;
      ERR_TRADE_ENTRY  = TRADE_ENTRY;
      ERR_TRADE_VOLUME = TRADE_VOLUME;
      
      switch(ord){
      
         case 0: 
            // market buy
            if ((TRADE_STOP > 0 && TRADE_TARGET > 0)  && (TRADE_STOP > TRADE_TARGET || TRADE_STOP > util_ask() || util_ask() > TRADE_TARGET)) return Error(-10);
            break; 
         case 1: 
            // market sell
            if ((TRADE_STOP > 0 && TRADE_TARGET > 0) && (TRADE_TARGET > TRADE_STOP || TRADE_TARGET > util_bid() || util_bid() > TRADE_STOP)) return Error(-20);
            break; 
         case 2:
            // buy limit
            if ((TRADE_ENTRY > util_ask() || TRADE_STOP > util_ask() || TRADE_ENTRY < TRADE_TARGET)) return Error(-30);
            break;
         case 3:
            // sell limit
            if ((util_bid() > TRADE_ENTRY || util_bid() > TRADE_STOP || TRADE_TARGET > TRADE_ENTRY)) return Error(-40); 
            break;
         case 4: 
            // buy stop
            if (TRADE_ENTRY < util_ask()) return Error(-50); 
            break;
         case 5: 
            // sell stop 
            if (TRADE_ENTRY > util_bid()) return Error(-60);
            break;
         default: 
            break; 
      }
      Error(0);
   }
   
   return ticket;
}

int CTradeToolMain::Error(int e){
   
#ifdef __MQL4__
const int ErrTradeDisabled    = 133;
const int ErrMarketClosed     = 132;
const int ErrBadVol           = 131;
const int ErrBadStops         = 130;
const int ErrAutoTrading      = 4109;
#endif


#ifdef __MQL5__
const int ErrTradeDisabled    = 10017;
const int ErrMarketClosed     = 10018;
const int ErrBadVol           = 10014;
const int ErrBadStops         = 10016;
#endif

const int errorCode = GetLastError();

   switch(e){
   
      case 0:
         if (errorCode == ErrTradeDisabled) util_logger("Order Send Failed. Trading is disabled for current symbol");
         if (errorCode == ErrMarketClosed) util_logger("Order Send Failed. Market is closed.");
         if (errorCode == ErrBadVol) util_logger(StringFormat("Order Send Error: Invalid Volume. Vol: %f", ERR_TRADE_VOLUME));
         if (errorCode == ErrBadStops) util_logger(StringFormat("Order Send Error: Invalid Stops. SL: %f, TP: %f", ERR_TRADE_STOP, ERR_TRADE_TARGET));
         if (errorCode == ErrAutoTrading) util_logger("Order Send Failed. Auto Trading is Disabled.");
         break;
      case -10:
         util_logger(StringFormat("%s Market Buy. Price: %f, SL: %f, TP: %f", util_ask(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break;
      case -20:
         util_logger(StringFormat("%s Market Sell. Price: %f, SL: %f, TP: %f", util_bid(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break;
      case -30: 
         util_logger(StringFormat("%s Buy Limit. Price: %f, SL: %f, TP: %f", util_invalid_order(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break; 
      case -40: 
         util_logger(StringFormat("%s Sell Limit. Price: %f, SL: %f, TP: %f", util_invalid_order(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break; 
      case -50: 
         util_logger(StringFormat("%s Buy Stop. Price: %f, SL: %f, TP: %f", util_invalid_order(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break;
      case -60: 
         util_logger(StringFormat("%s Sell Stop. Price: %f, SL: %f, TP: %f", util_invalid_order(), ERR_TRADE_ENTRY, ERR_TRADE_STOP, ERR_TRADE_TARGET)); 
         break;
      default:
         util_logger(StringFormat("Order Send Failed. Code: %i", e));
         break;
   }
   return e;
}
