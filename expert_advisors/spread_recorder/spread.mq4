//+------------------------------------------------------------------+
//|                                                         main.mq4 |
//|                             Copyright 2023, Jay Benedict Alfaras |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Jay Benedict Alfaras"
#property version   "1.00"
#property strict
#property description "A Script for recording live market spreads, and stores data in a csv file."


#include <B63/Generic.mqh>

enum Category{
   All = 0,
   MarketWatch = 1,
};

input Category       InpCategory    = All; // Category of Symbols to Monitor: Market Watch or All 
input bool           InpLogging     = true; // Enables/Disables Logging
input string         InpFolderName  = "spreads"; // Folder Name
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
   if (IsNewCandle()){ update_spreads(); }

  }
//+------------------------------------------------------------------+

int update_spreads(){
   /*
   */
   logger("Updating Spreads");
   int symbols_total = SymbolsTotal(InpCategory);
   
   for (int i = 0; i < symbols_total ; i++){
      string symbol_name = SymbolName(i, InpCategory);
      string message = TimeCurrent()+","+symbol_name+","+MarketInfo(symbol_name, MODE_SPREAD);
      write_to_csv(symbol_name, message);
   }
   logger("Spreads Updated");
   return 1;
}

int write_to_csv(string symbol_name, string message){
   string file = InpFolderName + "\\"+AccountServer()+"\\"+symbol_name+"\\"+symbol_name+"_spread.csv";
   int handle = FileOpen(file, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
   FileSeek(handle, 0, SEEK_END);
   FileWrite(handle, message);
   FileClose(handle);
   FileFlush(handle);
   return handle;
}

int logger(string message){
   if (!InpLogging) return -1;
   Print(message);
   return 1;
}
