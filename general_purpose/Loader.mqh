

struct SLoader{
   datetime date;
   string   country, impact, title;
   double   actual, forecast, previous;
};

enum ENUM_IMPACT{
   HIGH, LOW, MEDIUM, NONE, NEUTRAL
};

// USE FOR BACKTESTING ONLY
// PATH CALENDAR_DB\\events\\symbol\\symbol_year
class CCalendarHistoryLoader {
   
   protected:
      
      string      PATH() { return "CALENDAR_DB\\events\\"; }
      datetime    CURRENT_DATE;
      int         SCANNED; 
      int         CURRENT_YEAR;
      int         COUNT(int c) { return SCANNED+=c; }
   
   private:
   public:
      SLoader     HISTORY_DATA[], BACKTEST_HISTORY[], TODAY[];
      datetime    NEWS_TODAY[];
   
      CCalendarHistoryLoader();
      ~CCalendarHistoryLoader () {};
   
      int         LoadCSV(ENUM_IMPACT impact_filter = NONE);
      int         NumHistory();
      int         UpdateHistory();
      int         DeQueue(SLoader &hist[]);
      int         Insert(SLoader &hist[]);
      int         PrintNextNewsEvent();
      bool        SymbolMatch(string country);
      bool        DateMatch(datetime target, datetime reference);
      int         UpdateData();
      bool        ImpactValid(ENUM_IMPACT filter, string impact);
      
      
      int         LoadDatesToday(ENUM_IMPACT impact = NONE);
      datetime    DateToday();
      int         UpdateToday();
      int         PopDates(datetime &NEWS[]);
      int         NumNewsToday();
      datetime    NextEvent();
      bool        EventInWindow(datetime window_open, datetime window_close);
      bool        IsNewYear();
      
      
      template <typename T> int Clear(T &data[]); 
      template <typename T> bool ArrayIsEmpty(T &data[]); 
      template <typename T> int  Append(T &element, T &dst[]); 
};

CCalendarHistoryLoader::CCalendarHistoryLoader() {
   CURRENT_DATE = TimeCurrent();
   SCANNED = 0;
   CURRENT_YEAR = TimeYear(TimeCurrent());
}

int      CCalendarHistoryLoader::LoadCSV(ENUM_IMPACT impact_filter = NONE) { 
   PrintFormat("%s LOAD", __FUNCTION__);
   
   string file_name = StringFormat("%s%s\\%s_%i.csv", PATH(), Symbol(), Symbol(), TimeYear(TimeCurrent()));
   Print("FILENAME: ", file_name);
   int handle = FileOpen(file_name, FILE_READ | FILE_CSV | FILE_COMMON | FILE_ANSI, '\n');
   if (handle == -1) {
      PrintFormat("Error Loading File %s", file_name);
      return -1;
   }
   
   string result[];
   int line = 0;
   while(!FileIsLineEnding(handle)) {
      line ++;
      string file_string = FileReadString(handle);
      int split = (int)StringSplit(file_string, ',', result);
      //if (split == 0) break; 
      
      //if (line == 1) continue; 
      
      // parse date
      if (StringFind(result[0], "-", 0) < 0) continue; 
      StringReplace(result[0], "-", ".");
      
      datetime r4fdatetime = StringToTime(result[0]);
      
      SLoader hist; 
      hist.date = r4fdatetime;
      hist.country = result[1];
      hist.impact = result[2];
      hist.title = result[3];
      hist.actual = result[4];
      hist.forecast = result[5];
      hist.previous = result[6];
      
      if (!ImpactValid(impact_filter, hist.impact)) continue;
      
      //PrintFormat("Date: %s, Country: %s, Impact: %s, Title: %s", TimeToString(hist.date), hist.country, hist.impact, hist.title);
         
      Append(hist, HISTORY_DATA);
   }
   
   FileClose(handle);
   FileFlush(handle);
   
   //UpdateHistory();
   Clear(TODAY);
   Clear(NEWS_TODAY);
   
   return NumHistory();  
}

bool     CCalendarHistoryLoader::ImpactValid(ENUM_IMPACT filter,string impact) { 
   switch(filter) { 
      case HIGH:
         if (impact == "H") return true;  
         break;    
      case MEDIUM: 
         if (impact == "M") return true;
         break;
      case LOW:
         if (impact == "L") return true;
         break;
      case NEUTRAL:
         if (impact == "N") return true; 
         break;
      default:
         return true;
   }
   return false;
}

template <typename T> 
int      CCalendarHistoryLoader::Append(T &element,T &dst[]) {
   int size = ArraySize(dst);
   ArrayResize(dst, size + 1); 
   dst[size] = element; 
   return ArraySize(dst); 
}

int      CCalendarHistoryLoader::PrintNextNewsEvent(void) {
   
   int size = ArraySize(TODAY);
   
   for (int i = 0; i < size; i++ ) {
      SLoader item = TODAY[i]; 
      PrintFormat("Date: %s, Title: %s, Country: %s, Impact: %s", 
         TimeToString(item.date), 
         item.title, 
         item.country, 
         item.impact);
   }
   return 1;
}

bool        CCalendarHistoryLoader::DateMatch(datetime target,datetime reference){
   
   int match = StringFind(TimeToString(target), TimeToString(reference, TIME_DATE));
   if (match == -1) return false;
   return true;
}

bool        CCalendarHistoryLoader::SymbolMatch(string country){
   int match = StringFind(Symbol(), country);
   if (StringFind(Symbol(), country) == -1) return false;
   return true;
}

int      CCalendarHistoryLoader::UpdateData() { 
   /*
   LOADS NEWS EVENTS TODAY
   */
   int start_index = COUNT(ArraySize(TODAY));
   Clear(TODAY); 
   int num_backtest = ArraySize(HISTORY_DATA);
   
   
   datetime date_today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   for (int i = start_index; i < num_backtest; i++) {
      SLoader hist = HISTORY_DATA[i];
      bool match = DateMatch(date_today, hist.date);
      
      if (!match) continue; 
      Append(hist, TODAY); 
      
   }
   int added = ArraySize(TODAY);
   return added; 
}

int      CCalendarHistoryLoader::LoadDatesToday(ENUM_IMPACT impact=3) {

   /*
   LOADS NEWS DATES TODAY
   */

   int start_index = COUNT(ArraySize(TODAY));
   
   Clear(NEWS_TODAY);
  
   int num_backtest = NumHistory(); 
   datetime date_today = DateToday(); 
   
   for (int i = start_index; i < num_backtest; i++) { 
      SLoader hist = HISTORY_DATA[i];
      bool match = DateMatch(date_today, hist.date);
      if (!match) continue; 
      Append(hist.date, NEWS_TODAY);
   }
   return ArraySize(NEWS_TODAY);
   
}

int      CCalendarHistoryLoader::UpdateToday(void) {

   /*
   UPDATES DATE QUEUE
   */
   
   if (ArrayIsEmpty(NEWS_TODAY)) return 0;

   while (TimeCurrent() > NEWS_TODAY[0]) { 
      
      if (PopDates(NEWS_TODAY) == 0) return 0;
      
   }
   return NumNewsToday();   
}

int      CCalendarHistoryLoader::PopDates(datetime &NEWS[]) {
   if (ArrayIsEmpty(NEWS)) return 0; 
   
   datetime dummy[];
   ArrayCopy(dummy, NEWS, 0, 1);
   ArrayFree(NEWS);
   ArrayCopy(NEWS, dummy);
   
   return ArraySize(NEWS);
}

template <typename T> 
int      CCalendarHistoryLoader::Clear(T &data[]) {
   ArrayFree(data);
   ArrayResize(data, 0);
   return ArraySize(data); 
}

bool     CCalendarHistoryLoader::EventInWindow(datetime window_open,datetime window_close) { 
   if (!IsTesting()) return false;
   int size = NumNewsToday(); 
   for (int i = 0; i < size; i++){
      datetime next_event = NEWS_TODAY[i];
      if (next_event > window_open && next_event < window_close) return true;
   }
     
   
   return false;
}


datetime CCalendarHistoryLoader::NextEvent(void) { 
   if (NumNewsToday() == 0) return 0; 
   
   return NEWS_TODAY[0];
}

bool CCalendarHistoryLoader::IsNewYear(void) {
   if (CURRENT_YEAR == TimeYear(TimeCurrent())) return false; 
   CURRENT_YEAR = TimeYear(TimeCurrent());
   return true;
}

int      CCalendarHistoryLoader::NumHistory(void)        {   return ArraySize(HISTORY_DATA); }
int      CCalendarHistoryLoader::NumNewsToday(void)      { return ArraySize(NEWS_TODAY); }
datetime CCalendarHistoryLoader::DateToday(void)         { return StringToTime(TimeToString(TimeCurrent(), TIME_DATE)); }

template <typename T>
bool     CCalendarHistoryLoader::ArrayIsEmpty(T &data[]) { return ArraySize(data) == 0; }

