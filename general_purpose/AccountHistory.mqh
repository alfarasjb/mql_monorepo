
#include <MAIN/TradeOps.mqh>

struct TradesHistory{
   uint              trade_ticket, trade_magic; 
   datetime          trade_open_time, trade_close_time; 
   ENUM_ORDER_TYPE   trade_type; 
   string            trade_symbol; 
   double            trade_open_price, trade_lots, trade_sl, trade_tp, trade_close_price, trade_commission, trade_profit, trade_swap;
   
   double            rolling_balance, max_equity, percent_drawdown;

};

struct PortfolioSeries{
   // Portfolio Analytics
   bool        in_drawdown, is_losing_streak; 
   double      current_drawdown_percent, max_drawdown_percent, peak_equity; 
   int         max_consecutive_losses, last_consecutive_losses, data_points;

   TradesHistory trade_history[];
};

enum EnumLosingStreak{
   Max, 
   Last,
};

class CAccountHistory {

   protected:
   private:
      PortfolioSeries   PORTFOLIO; 
      double            AccountDeposit();
   public:
      
      CAccountHistory();
      ~CAccountHistory() {}
      
      double            ACCOUNT_DEPOSIT;
      
      // PORTFOLIO GETTER
      bool              PORTFOLIO_IN_DRAWDOWN ()               { return PORTFOLIO.in_drawdown;              }
      bool              PORTFOLIO_IS_LOSING_STREAK ()          { return PORTFOLIO.is_losing_streak;         }
      double            PORTFOLIO_CURRENT_DRAWDOWN_PERCENT ()  { return PORTFOLIO.current_drawdown_percent; }
      double            PORTFOLIO_MAX_DRAWDOWN_PERCENT ()      { return PORTFOLIO.max_drawdown_percent;     }
      double            PORTFOLIO_PEAK_EQUITY ()               { return PORTFOLIO.peak_equity;              }
      int               PORTFOLIO_MAX_CONSECUTIVE_LOSSES ()    { return PORTFOLIO.max_consecutive_losses;   }
      int               PORTFOLIO_LAST_CONSECUTIVE_LOSSES ()   { return PORTFOLIO.last_consecutive_losses;  }
      int               PORTFOLIO_DATA_POINTS ()               { return PORTFOLIO.data_points;              }
       
      
      void              InitHistory();
      void              ClearHistory();
      void              UpdatePortfolioValues(TradesHistory &history);
      void              UpdateHistoryWithLastValue();
      
      double            HighestEquity();
      double            LatestTradeIsLoss();
      
      int               AppendToHistory(TradesHistory &history);
      int               ConsecutiveLosses(EnumLosingStreak losing_streak = Max);
      
      bool              OnLosingStreak();
      bool              IsHistoryUpdated();
      
      TradesHistory     LastEntry(); // return the last entry as struct      
      
      ulong             PortfolioLatestTradeTicket();
      bool              TicketInPortfolioHistory(int ticket);

      int               ExportBacktestHistory();
      
      int               NumHistoryTotal();
      int               HistorySelectByIndex(int index);
      int               PortfolioHistorySize();
      bool              PortfolioHistoryIsEmpty();
      bool              AccountInDrawdown();
};

CAccountHistory::CAccountHistory(void) {
   ACCOUNT_DEPOSIT = AccountDeposit();
}

void CAccountHistory::ClearHistory(void) {

   ArrayFree(PORTFOLIO.trade_history);
   ArrayResize(PORTFOLIO.trade_history, 0);
   PORTFOLIO.peak_equity               = 0;
   PORTFOLIO.in_drawdown               = 0;
   PORTFOLIO.current_drawdown_percent  = 0;
   PORTFOLIO.is_losing_streak          = 0;
   PORTFOLIO.max_consecutive_losses    = 0;
   PORTFOLIO.last_consecutive_losses   = 0;
   PORTFOLIO.max_drawdown_percent      = 0; 
   
}

void CAccountHistory::InitHistory(void) {
   ClearHistory();
   
   int num_history = NumHistoryTotal(); 
   
   double peak = ACCOUNT_DEPOSIT, cumulative_profit = 0, max_drawdown_pct = 0;
   
   for (int i = 0; i < num_history; i ++) {
   
      int s = HistorySelectByIndex(i);
      double profit = PosProfit();
      if (profit == 0 || profit == ACCOUNT_DEPOSIT) continue;
      
      // Append P/L 
      cumulative_profit += profit; 
      
      double rolling_equity = ACCOUNT_DEPOSIT + cumulative_profit; 
      peak = rolling_equity > peak ? rolling_equity : peak; 
      
      double drawdown = rolling_equity < peak ? (1 - (rolling_equity / peak)) * 100 : 0;
      
      max_drawdown_pct = drawdown > max_drawdown_pct ? drawdown : max_drawdown_pct;
      
      //14
      TradesHistory TRADE;
      TRADE.trade_ticket         = PosTicket();
      TRADE.trade_close_price    = PosClosePrice();
      TRADE.trade_close_time     = PosCloseTime();
      TRADE.trade_commission     = PosCommission();
      TRADE.trade_lots           = PosLots();
      TRADE.trade_magic          = PosMagic();
      TRADE.trade_open_price     = PosOpenPrice();
      TRADE.trade_open_time      = PosOpenTime();
      TRADE.trade_profit         = PosProfit();
      TRADE.trade_sl             = PosSL();
      TRADE.trade_swap           = PosSwap();
      TRADE.trade_symbol         = PosSymbol();
      TRADE.trade_tp             = PosTP();
      TRADE.trade_type           = PosOrderType();
      TRADE.rolling_balance      = rolling_equity;
      TRADE.max_equity           = peak;
      TRADE.percent_drawdown     = drawdown;
      
      AppendToHistory(TRADE);
   }
   
   PORTFOLIO.peak_equity               = peak; 
   PORTFOLIO.in_drawdown               = AccountInDrawdown();
   PORTFOLIO.current_drawdown_percent  = PORTFOLIO.in_drawdown ? (1 - (AccountBalance() / PORTFOLIO.peak_equity)) * 100 : 0;
   PORTFOLIO.is_losing_streak          = OnLosingStreak();
   PORTFOLIO.max_consecutive_losses    = ConsecutiveLosses();
   PORTFOLIO.last_consecutive_losses   = ConsecutiveLosses(Last);
   PORTFOLIO.max_drawdown_percent      = max_drawdown_pct; 
   PORTFOLIO.data_points               = PortfolioHistorySize();
   
}

double CAccountHistory::AccountDeposit(void) {
   int num_history = NumHistoryTotal();
   
   for (int i = num_history; i >= 0; i--) {
      int s = HistorySelectByIndex(i);
      if (PosOrderType() == 6) return PosProfit();
   }
   return -1;
}


bool CAccountHistory::OnLosingStreak(void) {
   int size = PortfolioHistorySize();
   if (size <= 0) return false;
   TradesHistory history = PORTFOLIO.trade_history[size - 1];
   if (history.trade_profit < 0) return true;
   return false;
}

int CAccountHistory::ConsecutiveLosses(EnumLosingStreak losing_streak=Max) {
   
   int size = PortfolioHistorySize();
   int streak = 0, max_losses = 0;
   double consecutive_losses[], current_streak[];
   
   for (int i = size - 1; i >= 0; i--) {
      TradesHistory portfolio = PORTFOLIO.trade_history[i];
      
      if (portfolio.trade_profit >= 0 || i == 0) {
         if (streak > max_losses) {
            max_losses = streak;
            
            ArrayFree(consecutive_losses);
            ArrayResize(consecutive_losses, max_losses);
            ArrayCopy(consecutive_losses, current_streak);
            if (losing_streak == Last) return max_losses;
         }
         streak = 0;
         ArrayFree(current_streak);
         continue;
      }
      
      int current_streak_size = ArraySize(current_streak);
      ArrayResize(current_streak, current_streak_size + 1);
      current_streak[current_streak_size] = portfolio.trade_profit;
      
      streak++; 
   }
   return max_losses; 
}


int CAccountHistory::AppendToHistory(TradesHistory &history) {
   int size = PortfolioHistorySize();
   
   ArrayResize(PORTFOLIO.trade_history, size + 1);
   PORTFOLIO.trade_history[size] = history;
   
   return PortfolioHistorySize();
}

bool CAccountHistory::IsHistoryUpdated(void) {
   int size = PortfolioHistorySize();
   if (size <= 0) return false;
   
   TradesHistory history = PORTFOLIO.trade_history[size - 1];
   if (PortfolioHistorySize() < NumHistoryTotal()) return false;
   return true;
}

TradesHistory CAccountHistory::LastEntry(void) {
   int num_history = NumHistoryTotal(); 
   
   int s = HistorySelectByIndex(num_history - 1);
   int size = PortfolioHistorySize(); 
   
   double stored_max_equity = PORTFOLIO.peak_equity == 0 ? ACCOUNT_DEPOSIT : PORTFOLIO.peak_equity;
   
   TradesHistory TRADE;
   TRADE.trade_ticket         = PosTicket();
   TRADE.trade_close_price    = PosClosePrice();
   TRADE.trade_close_time     = PosCloseTime();
   TRADE.trade_commission     = PosCommission();
   TRADE.trade_lots           = PosLots();
   TRADE.trade_magic          = PosMagic();
   TRADE.trade_open_price     = PosOpenPrice();
   TRADE.trade_open_time      = PosOpenTime();
   TRADE.trade_profit         = PosProfit();
   TRADE.trade_sl             = PosSL();
   TRADE.trade_swap           = PosSwap();
   TRADE.trade_symbol         = PosSymbol();
   TRADE.trade_tp             = PosTP();
   TRADE.trade_type           = PosOrderType();
   TRADE.rolling_balance      = AccountBalance();
   TRADE.max_equity           = stored_max_equity;
   TRADE.percent_drawdown     = TRADE.rolling_balance < TRADE.max_equity ? (1 - (TRADE.rolling_balance / TRADE.max_equity)) * 100 : 0;

   return TRADE;
}

void CAccountHistory::UpdatePortfolioValues(TradesHistory &history) {

   PORTFOLIO.data_points               = PortfolioHistorySize();
   PORTFOLIO.peak_equity               = history.rolling_balance > PORTFOLIO.peak_equity ? history.rolling_balance : PORTFOLIO.peak_equity; 
   PORTFOLIO.in_drawdown               = AccountInDrawdown();
   PORTFOLIO.current_drawdown_percent  = PORTFOLIO.in_drawdown ? (1 - (AccountBalance() / PORTFOLIO.peak_equity)) * 100 : 0; 
   PORTFOLIO.is_losing_streak          = OnLosingStreak(); 
   PORTFOLIO.max_consecutive_losses    = ConsecutiveLosses();
   PORTFOLIO.last_consecutive_losses   = ConsecutiveLosses(Last);
   PORTFOLIO.max_drawdown_percent      = history.percent_drawdown > PORTFOLIO.max_drawdown_percent ? history.percent_drawdown : PORTFOLIO.max_drawdown_percent;

}

void CAccountHistory::UpdateHistoryWithLastValue(void) {

   TradesHistory history = LastEntry();
   AppendToHistory(history);
   UpdatePortfolioValues(history);
   
}

ulong CAccountHistory::PortfolioLatestTradeTicket(void) {

   int size = PortfolioHistorySize();
   
   if (PortfolioHistoryIsEmpty()) return 0;
   return PORTFOLIO.trade_history[size - 1].trade_ticket;
   
}

bool CAccountHistory::TicketInPortfolioHistory(int ticket) {

   int size = PortfolioHistorySize();
   
   if (PortfolioHistoryIsEmpty()) return false; 
   if (ticket == PortfolioLatestTradeTicket()) return true;
   return false;
   
}

bool CAccountHistory::PortfolioHistoryIsEmpty(void) {

   if (PortfolioHistorySize() > 0) return false;
   return true;
   
}

bool     CAccountHistory::AccountInDrawdown(void)           { return AccountBalance() < PORTFOLIO.peak_equity; }
int      CAccountHistory::PortfolioHistorySize(void)        { return ArraySize(PORTFOLIO.trade_history); }
int      CAccountHistory::HistorySelectByIndex(int index)   { return OrderSelect(index, SELECT_BY_POS, MODE_HISTORY); }
int      CAccountHistory::NumHistoryTotal(void)             { return OrdersHistoryTotal(); }

