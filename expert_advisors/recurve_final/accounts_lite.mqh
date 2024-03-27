

#include "lib/dependencies/trade_ops.mqh"


class CAccountsLite : public CTradeOps {
protected:

private:


   CPoolGeneric<int>    tickets_active_; 
   CPoolGeneric<int>    tickets_closed_today_; 

   //--- Metrics
   double               deposit_, start_bal_today_, closed_pl_today_, pct_gain_today_;
   int                  symbol_trades_today_, total_trades_today_;
   
   //--- Daily Reset
   datetime             last_update_; 

public: 
   
      CAccountsLite();
      ~CAccountsLite(); 
   
      
            void        SetDeposit(double value)            { deposit_ = value; }
            void        SetStartBalToday(double value)      { start_bal_today_ = value; }
            void        SetClosedPLToday(double value)      { closed_pl_today_ = value; }
            void        SetPctGainToday(double value)       { pct_gain_today_ = value; }
            void        SetLastUpdate(datetime value)       { last_update_ = value; }
            
            void        AddClosedPLToday(double value)      { closed_pl_today_+=value; }
            
      const double      AccountDeposit()  const       { return deposit_; }
      const double      AccountStartBalToday()  const { return start_bal_today_; }
      const double      AccountClosedPLToday()  const { return closed_pl_today_; }
      const double      AccountPctGainToday()   const { return pct_gain_today_; }
      
      const datetime    LastUpdate() const            { return last_update_; }
      
            void        Track(); 
            double      Deposit(); 
            bool        IsNewDay(); 
            int         LastTicketInOrderPool();
            bool        PoolStateChanged(); 
            datetime    GetDate(datetime target); 
            int         InitializeActiveTickets(); 
            datetime    Register(); 
            void        AppendClosedTrade(int ticket); 

};

CAccountsLite::CAccountsLite() : CTradeOps(Symbol(), 0) {}

CAccountsLite::~CAccountsLite() {}


double         CAccountsLite::Deposit() {
   
   if (IsTesting())     return 100;
   
   int s;
   s = OP_HistorySelectByIndex(0); 
   if (PosOrderType() == 6)    return PosProfit(); 
   
   
   int hist_total  = PosHistTotal(); 
   s = OP_HistorySelectByIndex(hist_total - 1);
   if (PosOrderType() == 6)   return PosProfit(); 
   
   Log_.LogError("Deposit not found.", __FUNCTION__); 
   return 0; 
   
   
}

void           CAccountsLite::Track() {
   if (IsNewDay()) {
      // Init(); // Not implemented
      return; 
   }
   
   if (!PoolStateChanged()) return; 
   
   CPoolGeneric<int> *current = new CPoolGeneric<int>(); 
   
   int s, curr_ticket;
   for (int i = 0; i < PosTotal(); i++) {
      s = OP_OrderSelectByIndex(i);
      curr_ticket =  PosTicket(); 
      current.Append(curr_ticket); 
   }
   
   current.Sort();
   tickets_active_.Sort(); 
   
   int first_ticket;
   while(tickets_active_.Size() > 0) {
      first_ticket   = tickets_active_.First(); 
      if (!current.Search(first_ticket)) AppendClosedTrade(first_ticket); 
      tickets_active_.Remove(first_ticket); 
   }
   
   int current_extracted[]; 
}

void           CAccountsLite::AppendClosedTrade(int ticket) {
   tickets_closed_today_.Append(ticket);
   int s = OP_HistorySelectByTicket(ticket);
   
   AddClosedPLToday(PosProfit());
   double gain_today = AccountClosedPLToday() / AccountStartBalToday() * 100;
   SetPctGainToday(gain_today); 
      
   Log_.LogInformation(StringFormat("Updated Hist. Ticket: %i, Profit: %f, PL Today: %f, Gain Today: %f", 
      ticket,
      PosProfit(),
      AccountClosedPLToday(),
      AccountPctGainToday()), __FUNCTION__); 
   
}


int            CAccountsLite::InitializeActiveTickets() {
   int   t, active_ticket;
   
   for (int i = 0; i < PosTotal(); i++) {
      t  = OP_OrderSelectByIndex(i); 
      active_ticket  = PosTicket(); 
      if (!tickets_active_.Search(active_ticket))
         tickets_active_.Append(active_ticket); 
   }
   int active_size   = tickets_active_.Size(); 
   Log_.LogInformation(StringFormat("%i trades active.", active_size), __FUNCTION__); 
   datetime upd = Register();
   return active_size; 
}

bool           CAccountsLite::PoolStateChanged() {
   if (PosTotal() != tickets_active_.Size()) {
      Log_.LogInformation(StringFormat("Order Pool Changed: %i", PosTotal()), __FUNCTION__); 
      Log_.LogInformation(StringFormat("Order Pool Changed. Reason: Size. Pool: %i, Stored: %i", 
         PosTotal(), 
         tickets_active_.Size()), __FUNCTION__); 
      return true; 
   }
   
   bool b = tickets_active_.Sort(); 
   
   if (tickets_active_.Last() != LastTicketInOrderPool()) {
      Log_.LogInformation(StringFormat("Order Pool Changed. Reason: Last. Pool: %i, Stored: %i", 
         LastTicketInOrderPool(), 
         tickets_active_.Last()), __FUNCTION__); 
         return true; 
   }
   
   int t;
   for (int i = 0; i < PosTotal(); i++) {
      t = OP_OrderSelectByIndex(i);
      if (PosTicket() != tickets_active_.Item(i)) {
         Log_.LogInformation(StringFormat("Order Pool Changed. Reason: Replace. Pool: %i, Stored: %i", 
            PosTicket(), 
            tickets_active_.Item(i)), __FUNCTION__); 
         return true; 
      }
   }
   return false; 
}

datetime       CAccountsLite::Register() {
   SetLastUpdate(TimeCurrent());
   Log_.LogInformation(StringFormat("Last Update: %s", TimeToString(LastUpdate())), __FUNCTION__);
   return LastUpdate();
}

int            CAccountsLite::LastTicketInOrderPool() { 
   if (PosTotal() == 0) return 0; 
   int s = OP_OrderSelectByIndex(PosTotal() - 1); 
   return PosTicket(); 
}

datetime       CAccountsLite::GetDate(datetime target) {
   return StringToTime(TimeToString(target, TIME_DATE)); 
}

bool           CAccountsLite::IsNewDay() {
   return (GetDate(TimeCurrent() != GetDate(LastUpdate()))); 

}
