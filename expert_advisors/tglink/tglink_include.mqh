
#define app_copyright "Copyright 2023, Jay Benedict Alfaras"
#define app_version   "1.00"
#property strict

#ifdef __MQL5__
#include<Trade/Trade.mqh>
CTrade Trade;
#endif

#include <B63/telegram_revised.mqh>
#include <B63/Generic.mqh>
#include <B63/newscheck.mqh>
#include <B63/CObjects.mqh>
#include <B63/TradeOperations.mqh>


int defX = 5;
int defY = 150;
CObjects obj(defX, defY, 10, 1);


enum EType{
   Primary = 1, 
   Secondary = 2,
};

enum ESource{
   Local = 1, 
   Network = 2,
};

enum EStrat{
   CopyOnly = 1,
   CopyAndManage = 2,
};

enum Status{
   Active = 1,
   Pending = 2,
   None = 3,
};
input string      copyParams       = " -- MAIN SETTINGS -- "; // MAIN SETTINGS


input EType       inpAccount       = 1; // Account Type (Primary / Secondary)
input bool        inpEnableCopy    = true; //Enable Copy Trading
input EStrat      inpCopyStrat     = 2; // Copy Trading Strategy: 1. Only Copy Entries 2. Copy and Manage based on Primary
input string      inpChatId        = "-1001832584646"; // Telegram Chat ID

input string      tradeParams      = "-- TRADE PARAMETERS --"; // TRADE PARAMETERS //

input ERisk       inpRiskType      = 1; // Risk Type  
input double      inpRiskLot       = 0.01; //Lot Size Based Exposure (Fixed Lot)
input double      inpRiskPct       = 1; //Balance Based Exposure - % (Percent Balance)
input double      inpRiskAmt       = 10; //Amount Based Exposure - USD (Fixed Amount)
input int         inpMagic         = 232323;// Magic Number

input int         inpDefPOExpiryHr = 18; // Default Pending Order Expiry 


STGMessage storedMsg;
const string      BotToken  =  "6406773615:AAES_F0EzZ7fYzhTAXmNddYJKHjYEv9Qwm0";
const string      ChatId    =  "-1001832584646";
CTelegram tg(inpChatId, BotToken);
CTradeOperations tradeOp(inpRiskType, inpRiskAmt, inpRiskPct, inpRiskLot);

struct STrade{
   string orderSymbol;
   ENUM_ORDER_TYPE orderType;
   double entry;
   double stop;
   double target;
   double volume;
   double pl;
   int ticket;
   int magic;
   datetime opening;
   datetime expiry;
   
   STrade(){
      orderSymbol = "";
      orderType = -1;
      entry = 0;
      stop = 0;
      target = 0;
      volume = 0;
      pl = 0;
      ticket = 0;
      magic = 0;
      opening = 0;
      expiry = 0;
   }
   
   void reInit(){
      orderSymbol = "";
      orderType = -1;
      entry = 0;
      stop = 0;
      target = 0;
      volume = 0;
      
     
   }
};


string dataToWrite = "";
STrade trade; // Placeholder of trade on current device
STrade Rtrade; // Placeholder of Received Trade (Secondary device)
STrade WTrade; // Placeholder of Written Trade (Primary device)
//string nl = "%250A";

STrade tradeArray [];
const string      GacctNum       = (string)AccountInfoInteger(ACCOUNT_LOGIN);
const string      GacctName      = AccountInfoString(ACCOUNT_NAME);
const string      GacctCompany   = AccountInfoString(ACCOUNT_COMPANY);
const string      Ginfo          = EnumToString(inpAccount) + nl + GacctNum + nl + GacctName + nl + GacctCompany + nl + EnumToString(inpCopyStrat);
const int         Gdigits        = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

int OnInit()
  {
      drawUI();
      string retVal = "Connected" + nl + Ginfo;
      ackMessage(retVal, false);
      
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
//---
      ObjectsDeleteAll(0, 0, -1);
      string retVal = "Disconnected" + nl + Ginfo;
      ackMessage(retVal,false);
      
      //ADD UNPIN MESSAGE ON Primary DE INIT
   
  }

void OnTick()
  {
//---
   //on trade open, trigger write, on Primary acct (put this on order send)
   //on tick read  if handle is < 1 on  account 
   //when file is available, read file, parse data, execute trade
   //check for open orders, if symbol matches, copy the trade details, and send
   //if (orderListChange()) checkByIndex(trade);
   checkByIndex(trade);
   readFromNetwork();
  }
  
// -- MAIN FUNCTIONS -- //
  
bool orderListChange(){
   if (PositionsTotal() != ArraySize(tradeArray)) return true;
   return false;
}
  
// -- MAIN FUNCTIONS -- //

// -- GENERIC OPERATIONS -- //

string norm(double price){
   return norm(price, Gdigits);
}

string norm(double price, int digits){
   return DoubleToString(price, digits);
}

bool ackMessage(string message){
   return ackMessage(message, false);
}

bool ackMessage(string message, bool pin){
   return tg.sendMsg(message, pin);
}


string tgOrderMessage(){
   // template for tg order commands
   string message = nl + WTrade.orderSymbol + nl + parseOrder(WTrade.orderType) + nl +"Entry: " + norm(WTrade.entry) + nl + "Stop: " + 
   norm(WTrade.stop) + nl + "Target: " + norm(WTrade.target) + nl + "Open Time: "  + WTrade.opening + nl + "Expiry: " + WTrade.expiry;
  // if (WTrade.entry == 0) return "%250ADELETE";
  // else return message;
  return message;
}

string parseOrder(ENUM_ORDER_TYPE ord){
   // formatting of enum_order_type into a more presentable string, solely for presentation purposes
   string retVal = "";
   if (WTrade.entry == 0) return "";
   switch (ord){
      case 0: 
         retVal = "Market Buy";
         break;
      case 1: 
         retVal = "Market Sell";
         break;
      case 2: 
         retVal = "Buy Limit";
         break;
      case 3:
         retVal = "Sell Limit";
         break;
      default:
         retVal = "";
         break;
   }
   return retVal;
}


string error(int i){
   string retVal = "";
   switch (i){
      case 1:
         retVal = "Order Delete Error. ";
         break;
      case 2: 
         retVal = "Order Modify Error. ";
         break;
      case 3:
         retVal = "Order Send Error. ";
         break;
      case 4:
         retVal = "Order Close Error. ";
         break;
      case 5:
         retVal = "Error Sending Message. Account Type must be Primary.";
         break;
      case 6:
         retVal = "Error Sending Message. Code: " + GetLastError();
      default:
         break;
   }
   Print(retVal, GetLastError());
   return retVal;
}

string validateSymbol(string rcvSymbol){
   string retVal = "";
   retVal = rcvSymbol;
   if (StringFind(AccountCompany(), "EightCap", 0) > -1){
      if (rcvSymbol != "XAUUSD") retVal = rcvSymbol + ".i";
   }
   return retVal;
}

Status ordStatus(int ord){
/*
   if (ord == 0 || ord == 1) return Active;
   if (ord == 2 || ord == 3) return Pending;
   if (ord == -1) return None;
   return None;*/
   switch(ord){
      case -1: 
         return None;
      case 0: 
         return Active;
      case 1:
         return Active;
      case 2: 
         return Pending;
      case 3: 
         return Pending;
      default:
         return None;
   }
}


bool positionsLimit(){
   bool retVal;
   switch(inpCopyStrat){
      case 1:
         retVal = false;
         break;
      case 2:
         if (PositionsTotal() == 1) retVal = true;
         break;
      default:
         break;
   }
   return false;
}

bool entryWindow(datetime tradeOpen, datetime tradeExpiry){
   MqlDateTime expiry;
   TimeToStruct(tradeOpen, expiry);
   expiry.hour = inpDefPOExpiryHr;
   expiry.min = 0;

   datetime expdatetime = tradeExpiry == 0 ? StructToTime(expiry) : tradeExpiry;
   if (TimeCurrent() >= tradeOpen && TimeCurrent() <= expdatetime) return true;
   return false;
}

// -- GENERIC OPERATIONS -- //

// -- NETWORK OPERATIONS -- //


bool writeToNetwork(string header){
   if (inpAccount == Secondary) return false;
   Status orderStatus = ordStatus(WTrade.orderType);
   string toWrite = header + tgOrderMessage();
   
   return ackMessage(toWrite, true);
   if (ordStatus(WTrade.orderType) == Active && WTrade.entry > 0) ackMessage("Order Filled" + nl + tgOrderMessage());
}

void readFromNetwork(){
   
   
   // reads last tg message, and decides trade
   tg.getLastMsg();
   if (tg.lastMessage.messageId != storedMsg.messageId){
      storedMsg = tg.lastMessage;
      string result[];
      string sep = "|";
      int replace = StringReplace(storedMsg.message, "\\n", "|");
      string sepChar = StringGetCharacter(sep, 0);
      int split = StringSplit(storedMsg.message, sepChar, result);
      if (split > 0){
         string command = result[0];
         StringToUpper(command);
         readCommand(command, result);
      }
  }
}

double validatePrice(string priceString){
   string sep = " ";
   string priceArr [];
   ushort sepChar = StringGetCharacter(sep, 0);
   int split = StringSplit(priceString, sepChar, priceArr);
   return priceArr[1];
}

ENUM_ORDER_TYPE validateOrder(string orderString){
   if(orderString == "Market Buy") return 0;
   if(orderString == "Market Sell") return 1;
   if(orderString == "Buy Limit") return 2;
   if(orderString == "Sell Limit") return 3;
   return -1;
}

datetime validateDatetime(string datetimestring){
   MqlDateTime expiry;
   string sep = " ";
   string dateArr[];
   
   ushort sepChar = StringGetCharacter(sep, 0);
   int split = StringSplit(datetimestring, sepChar, dateArr);
   expiry.hour = (int)StringSubstr(dateArr[2], 0, 2);
   expiry.min = (int)StringSubstr(dateArr[2], 2, 2);
   string expirystring = dateArr[1] + " " + (string)expiry.hour + ":" + (string)expiry.min;
   
   return StringToTime(expirystring);
   
}

void tgOrderOperations(string &result[]){
   // parses received message from tg, and decides what to do (open trade, modify, delete)
      Rtrade.orderSymbol = validateSymbol(result[1]);
      Rtrade.orderType = validateOrder(result[2]);
      Rtrade.entry = validatePrice(result [3]);
      Rtrade.stop = validatePrice(result[4]);
      Rtrade.target = validatePrice(result[5]);
      Rtrade.opening = validateDatetime(result[6]);
      Rtrade.expiry = validateDatetime(result[7]);
      Rtrade.volume = volume();
      
      
  // Print(orderFormat);
      if (result[0] == "DELETE" && inpCopyStrat == CopyAndManage) {
         if (!deleteOrder(Rtrade)) ackMessage(error(1));
      };
      if (Rtrade.entry > 0 && inpEnableCopy && result [0] == "ORDER" && entryWindow(Rtrade.opening, Rtrade.expiry)) {
         if (!sendOrder(Rtrade)) ackMessage(error(3));
      };
      if (openPositions() && Rtrade.entry == 0 && result[0] == "CLOSE" && inpCopyStrat == CopyAndManage){
         if (!closeOrder(Rtrade)) ackMessage(error(4));
      }
}

   
// -- NETWORK OPERATIONS -- //  

// -- COMMANDS --//

void readCommand(string command, string &result[]){
   
   string commands [] = {"ORDER", "POSITIONS", "INFOALL", "STATUSALL", "CLOSEALL", "DELETEALL", "NEWS", "NEWSHIGH", "NEWSTODAY"};
   if((command == "ORDER" || command == "DELETE" || command == "CLOSE") && (inpAccount == Secondary) && (ArraySize(result) > 1)) tgOrderOperations(result);
   if(command == commands[1]) sendCommand(1); // Positions
   if(command == commands[2]) sendCommand(2); // Info
   if(command == commands[3]) sendCommand(3); // Order Status
   if(command == commands[4]) sendCommand(4); // Close All
   if(command == commands[5]) sendCommand(5); // Delete All
   if(command == commands[6]) sendCommand(6); // News All
   if(command == commands[7]) sendCommand(7); //News High Impact Only
   
}


void sendCommand(int command){
   switch (command){
      case 1: 
          ackMessage("Total Positions: " + (string)PositionsTotal() + nl +  "Pending Orders: " + (string)status(Pending) + nl + "Active Orders: " + (string)status(Active), false);
         break;
      case 2:;
         ackMessage(tgInfo());
         break;
      case 3:
         ackMessage(orderStatus());
         break;
      case 4:
         if(!closeOrder(trade) && openPositions()) ackMessage(error(4));
         if (!openPositions()) ackMessage("No Open Positions");
         break;
      case 5:
         if(!deleteOrder(trade) && openPositions()) ackMessage(error(1));
         if (!openPositions()) ackMessage("No Open Positions");
         break;
      case 6: 
         checkNewsCustom(true, false, false);
         if (inpAccount == Primary) ackMessage(news());
         break;
      case 7: 
         checkNewsCustom(true, false, true);
         if (inpAccount == Primary) ackMessage(news());
      default:
         //ackMessage("Invalid Command", false);
         break; 
   }
}

string news(){
   string newsString = "";
   if (ArraySize(newsCustom) == 0) return "None";
   for (int i = 0; i < ArraySize(newsCustom); i++){
      newsString += newsCustom[i].title + nl + (string)newsCustom[i].time + nl + newsCustom[i].country + nl + nl;
   }  
   return newsString;
}
 

string tgInfo(){
   string retVal = GacctNum + nl + GacctName + nl + GacctCompany + nl + EnumToString(inpAccount) + nl + EnumToString(inpCopyStrat);
   return retVal;
}

int status(Status ref){
   int count = 0;
   if (!openPositions()) return 0;

   for (int i = 0; i < PositionsTotal(); i++){
      bool select = PositionSelectByIndex(i);
      if (ordStatus(PositionOrderType()) == ref) count++;
   }
   return count;

}

string orderStatus(){
   // PUT ORDERS IN POOL INTO ARRAY TO GET STATUS
   string orderString = EnumToString(inpAccount) + nl + trade.orderSymbol + nl + EnumToString(trade.orderType) + nl + 
   "Entry: " + norm(trade.entry) + nl + "Stop: " + norm(trade.stop) + nl + "Target: " + norm(trade.target) + nl + "Volume: " + norm(PositionVolume(), 2) + nl +
   "Open P/L: " + norm(PositionProfit(), 2) + " USD" + nl + "Ticket: " + (string)trade.ticket + nl + "Magic: " + (string)PositionMagicNumber();
   string retVal = "";
   if (checkByIndex(trade) && openPositions()) retVal = orderString;
   if (!openPositions()) retVal = "No Open Positions";
   return retVal;
}


// -- COMMANDS --//
// -- TRADE OPERATIONS -- //
bool sendOrder(STrade &tradeOpen){
Print(tradeOpen.volume);
string orderString = "Entry: "+ norm(tradeOpen.entry)+ nl + "Stop: " + norm(tradeOpen.stop) + nl + "Target: " + norm(tradeOpen.target) + nl + "Volume: " + norm(tradeOpen.volume, 2);
#ifdef __MQL4__
   if (PositionOrderSend(tradeOpen) < 0) return false;
   
#endif
#ifdef __MQL5__
   MqlTradeRequest tradeRequest;
   tradeRequest.magic = inpMagic;
   tradeRequest.action = TRADE_ACTION_PENDING;
   tradeRequest.symbol = Rtrade.orderSymbol;
   tradeRequest.volume = volume();
   tradeRequest.price = Rtrade.entry;
   tradeRequest.sl = Rtrade.stop;
   tradeRequest.tp = Rtrade.target;
   
   MqlTradeResult tradeResult;
   Trade.SetExpertMagicNumber(inpMagic);
   if(!Trade.PositionOpen(Rtrade.orderSymbol, Rtrade.orderType, volume(), Rtrade.entry, Rtrade.stop, Rtrade.target, NULL)) {
    //bool result = OrderSend(tradeRequest,tradeResult);
      return false;
   };
#endif 
ackMessage("TRADE CONFIRMED" + nl + orderString);
tradeOpen.reInit();

return true;
}

bool modifyOrder(STrade &compare){

#ifdef __MQL4__
   bool ticket = OrderModify(PositionTicket(), compare.entry, compare.stop, compare.target, 0, clrNONE);
   if (!ticket) return false;
#endif 

#ifdef __MQL5__
   Trade.OrderModify(PositionTicket(), compare.entry, compare.stop, compare.target, 0, 0, 0);
#endif
ackMessage("TRADE MODIFIED", false);
return true;
}

bool orderInPool(double price){
   for (int i = 0; i < PositionsTotal(); i++){
      bool select = PositionSelectByIndex(i);
      if (PositionPriceOpen() == price) return true;
   }
   return false;
}

bool deleteOrder(STrade &compare){
   bool retVal = false;
   if (!openPositions()) {
      Print("Nothing to delete. No Open Positions.");
      return false;
   }
   if (!orderInPool(compare.entry)) {
      Print("Order not in pool.");
      return false;
   }
  // compare.reInit();
  // trade.reInit();
   if (!PositionDelete()) return false;
   ackMessage("TRADE DELETED", false);
   return true;
}

bool closeOrder(STrade &compare){
   if (!orderInPool(compare.entry)) return false;
   if(!PositionClose()) return false;
   ackMessage("TRADE CLOSED" + nl +"P/L: " + DoubleToString(PositionProfit(), 2), false);
   return true;
}


//WRAPPER 

#ifdef __MQL4__
// NEW 
double volume(){ return tradeOp.volume(Rtrade.entry, Rtrade.stop); }



int PositionOrderSend(STrade &tradeSend) { return OrderSend(tradeSend.orderSymbol, tradeSend.orderType, tradeSend.volume, tradeSend.entry, 3, tradeSend.stop, tradeSend.target, NULL, inpMagic, tradeSend.expiry, clrNONE);}

STrade selectByIndex(STrade &compare, int index){
   //last order in order pool, is set to the trade struct
   PositionSelectByIndex(index);
   //bool select = OrderSelect(index, SELECT_BY_POS, MODE_TRADES); // OLD 
   compare.orderSymbol = PositionSymbol();
   compare.entry = PositionPriceOpen();
   compare.stop = PositionStopLoss();
   compare.target = PositionTakeProfit();
   compare.orderType = (ENUM_ORDER_TYPE)PositionOrderType();
   compare.opening = PositionOpenTime();
   compare.expiry = PositionExpiration();
   compare.pl = PositionProfit();
   compare.ticket = PositionTicket();
   compare.magic = PositionMagicNumber();

   return compare;
}

bool checkByIndex(STrade &compare){
   int Size = ArraySize(tradeArray);
   STrade updatedArr[];
   if(PositionsTotal() > Size){
      // trade was added
      Size = ArrayResize(tradeArray, PositionsTotal()); // resize trade array
      for (int i = 0; i < Size; i++){
         tradeArray[i] = selectByIndex(compare, i); // add to last position in array
      }
      WTrade = tradeArray[ArraySize(tradeArray) - 1]; // set last entry in trade array as wtrade for sending tg message
      // send tg message (new trade opened)
      if(!writeToNetwork("ORDER") && inpAccount == Primary) error(6);
         
   }
   if (PositionsTotal() < Size){
      //trade was deleted
      Size = ArraySize(tradeArray);
      for (int i = 0; i < Size ; i++){       
         for (int j = 0; j <= PositionsTotal(); j++){ 
            //compare selected trade in trade array with open positions in trade pool 
            //bool select = OrderSelect(j, SELECT_BY_POS, MODE_TRADES); // OLD
            PositionSelectByIndex(j);
            //NEW
            //if (!checkInPool(i, j)) continue; // 
            //if (checkInPool(i, j)) break;
            //NEW
            
           
            if(tradeArray[i].orderSymbol == OrderSymbol() && tradeArray[i].entry == OrderOpenPrice()) break;
            if (j < PositionsTotal()) continue;
            WTrade = tradeArray[i];
            if (ordStatus(tradeArray[i].orderType) == Pending && !writeToNetwork("DELETE") && inpAccount == Primary) error(6);
            if (ordStatus(tradeArray[i].orderType) == Active && !writeToNetwork("CLOSE") && inpAccount == Primary) error(6);
           
            //Clear and repopulate trade array
            ArrayFree(tradeArray);
            Size = ArrayResize(tradeArray, PositionsTotal());
            for (int z = 0; z < PositionsTotal(); z++){
               tradeArray[z] = selectByIndex(compare, z);
            }
       
         }
         Size = ArrayResize(tradeArray, PositionsTotal());
      }
   }
   return false;
}

bool checkInPool(int idx, int j){
   //idx = selected trade in array 
   // comparing with open positions in trade pool 
   if(tradeArray[idx].orderSymbol == PositionSymbol() && tradeArray[idx].entry == PositionPriceOpen()) return true;
   if (j < PositionsTotal()) return false;
   WTrade = tradeArray[idx];
   if (ordStatus(tradeArray[idx].orderType) == Pending && !writeToNetwork("DELETE")) error(6);
   if (ordStatus(tradeArray[idx].orderType) == Active && !writeToNetwork("CLOSE")) error(6);
   //Clear and repopulate trade array
   return true;
}



#endif


#ifdef __MQL5__



bool checkByIndex(STrade &compare){
   for (int i = 0 ; i < OrdersTotal(); i++){
      ulong ticket = PositionGetTicket(i);
      if (PositionSymbol() == Symbol()){
         compare.orderSymbol = PositionSymbol();
         compare.entry = PositionPriceOpen();
         compare.stop = PositionStopLoss();
         compare.target = PositionTakeProfit();
         compare.orderType = PositionGetInteger(POSITION_TYPE);
         
         return true;
      }
   }
   compare.reInit();
   return false;
}


#endif


// UI // 

int yOff(int y){
   int ret = defY - y;
   return ret;
}

string valueString(){
   string retVal = "";
   switch (inpRiskType){
      case 1:
         retVal = (string)inpRiskLot;
         break;
      case 2: 
         retVal = (string)inpRiskPct;
         break;
      case 3: 
         retVal = (string)inpRiskAmt;
         break;
      default:
         retVal = "";
         break;
   }
   return retVal;
}

datetime expirytime(){
   MqlDateTime expiry;
   TimeToStruct(TimeCurrent(), expiry);
   expiry.hour = inpDefPOExpiryHr;
   expiry.min = 0;
   expiry.sec = 0;
   return StructToTime(expiry);
}

void drawUI(){

  obj.CRectLabel("UI", defX, defY, 200, defY - 5); 
  obj.CTextLabel("InpAccount", 15, yOff(25), "Account Type: " + EnumToString(inpAccount));
  obj.CTextLabel("InpCopyEnabled", 15, yOff(45), "Copy Enabled: " + inpEnableCopy);
  obj.CTextLabel("InpCopyStrat", 15, yOff(65), "Copy Strategy: " + EnumToString(inpCopyStrat));
  obj.CTextLabel("InpRiskType", 15, yOff(85), "Risk Type: " + EnumToString(inpRiskType));
  obj.CTextLabel("InpRiskValue", 15, yOff(105), "Value: " + valueString());
  obj.CTextLabel("InpExpiry", 15, yOff(125), "Expiry: " + expirytime());
}




// UI //
