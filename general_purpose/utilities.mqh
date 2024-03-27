

double            UTIL_PREVIOUS_DAY_OPEN(void)     { 
   
   double open    = iOpen(Symbol(), PERIOD_D1, 1);
   if (open == 0) return iOpen(NULL, PERIOD_CURRENT, UTIL_SHIFT_YESTERDAY());
   return open;
}

double            UTIL_PREVIOUS_DAY_CLOSE(void)    { 
   
   double close   = iClose(NULL, PERIOD_D1, 1);
   if (close == 0) return iClose(NULL, PERIOD_CURRENT, UTIL_SHIFT_TODAY() + 1);
   return close;

}

double            UTIL_PREVIOUS_DAY_HIGH(void)     {
   
   double high    = iHigh(NULL, PERIOD_D1, 1);
   return high; 
}

double            UTIL_PREVIOUS_DAY_LOW(void)      {

   double low     = iLow(NULL, PERIOD_D1, 1);
   return low;

}


int               UTIL_SHIFT_TODAY(void)           { return iBarShift(NULL, PERIOD_CURRENT, UTIL_DATE_TODAY()); }
int               UTIL_SHIFT_YESTERDAY(void)       { return iBarShift(NULL, PERIOD_CURRENT, UTIL_DATE_YESTERDAY()); }


double            UTIL_MARKET_SPREAD(void)         { return MarketInfo(Symbol(), MODE_SPREAD); }
double            UTIL_TICK_VAL(void)              { return MarketInfo(Symbol(), MODE_TICKVALUE); }
double            UTIL_TRADE_PTS(void)             { return MarketInfo(Symbol(), MODE_POINT); }
double            UTIL_PRICE_ASK(void)             { return SymbolInfoDouble(Symbol(), SYMBOL_ASK); }
double            UTIL_PRICE_BID(void)             { return SymbolInfoDouble(Symbol(), SYMBOL_BID); }
double            UTIL_LAST_CANDLE_OPEN(void)      { return iOpen(Symbol(), PERIOD_CURRENT, 0); }
double            UTIL_LAST_CANDLE_CLOSE(void)     { return iClose(Symbol(), PERIOD_CURRENT, 0); }
double            UTIL_DAY_OPEN(void)              { return iOpen(Symbol(), PERIOD_D1, 0); }
double            UTIL_CANDLE_OPEN(int shift)      { return iOpen(Symbol(), PERIOD_CURRENT, shift); }
double            UTIL_CANDLE_CLOSE(int shift)     { return iClose(Symbol(), PERIOD_CURRENT, shift); }

double            UTIL_CANDLE_HIGH(int shift = 1)  { return iHigh(Symbol(), PERIOD_CURRENT, shift); }
double            UTIL_CANDLE_LOW(int shift = 1)   { return iLow(Symbol(), PERIOD_CURRENT, shift); }
 


int               UTIL_INTERVAL_DAY(void)          { return PeriodSeconds(PERIOD_D1); }
int               UTIL_INTERVAL_CURRENT(void)      { return PeriodSeconds(PERIOD_CURRENT); }

double            UTIL_ACCOUNT_BALANCE(void)       { return AccountInfoDouble(ACCOUNT_BALANCE); }
double            UTIL_ACCOUNT_EQUITY(void)        { return AccountInfoDouble(ACCOUNT_EQUITY); }
string            UTIL_ACCOUNT_SERVER(void)        { return AccountInfoString(ACCOUNT_SERVER); }

double            UTIL_SYMBOL_MINLOT(void)         { return MarketInfo(Symbol(), MODE_MINLOT); }
double            UTIL_SYMBOL_MAXLOT(void)         { return MarketInfo(Symbol(), MODE_MAXLOT); }
int               UTIL_SYMBOL_DIGITS(void)         { return (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS); }

double            UTIL_SYMBOL_CONTRACT_SIZE(void)  { return SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE); }
double            UTIL_SYMBOL_LOTSTEP(void)        { return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP); }

string            UTIL_NORM_PRICE(double value) {
   
   string format_string    = StringFormat("%%.df", UTIL_SYMBOL_DIGITS());
   return StringFormat(format_string, value);
   
}

double            UTIL_NORM_VALUE(double value) {
   return NormalizeDouble(value, 2);
}


bool              UTIL_DATE_MATCH(datetime target, datetime reference) {

   if (StringFind(TimeToString(target), TimeToString(reference, TIME_DATE)) == -1) return false;
   return true;

}


datetime          UTIL_GET_DATE(datetime parse_datetime) {
   MqlDateTime dt_struct;
   TimeToStruct(parse_datetime, dt_struct);
   
   dt_struct.hour = 0;
   dt_struct.min = 0;
   dt_struct.sec = 0; 
   
   return StructToTime(dt_struct);
}

datetime          UTIL_DATE_TODAY(void)            { return (UTIL_GET_DATE(TimeCurrent())); }
datetime          UTIL_DATE_YESTERDAY(void)        { return UTIL_DATE_TODAY() - UTIL_INTERVAL_DAY(); }