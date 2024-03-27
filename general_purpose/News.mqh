
#include <B63/FFCalendarDownload.mqh> 


class CNews{
   
   
   protected:
   private:
      string   PATH;
   public:
      SFFEvent NEWS_CURRENT[], NEWS_TODAY[], NEWS_SYMBOL_TODAY[];
      int      FILE_HANDLE;
      
      CNews(string path);
      ~CNews() {}
      void        FILE_PATH(string path);
      
      int         FetchData();
      int         AppendToNews(SFFEvent &event, SFFEvent &data[]);
      int         DownloadFromForexFactory(string file_name);
      int         NewsSymbolToday();      
      int         ClearArray(SFFEvent &data[]);
      int         ClearHandle();
      int         NumNews();
      int         NumNewsToday();
      int         ResetHandle();
      
      bool        FileExists(string file_path);
      bool        DateMatch(datetime target, datetime reference);
      bool        SymbolMatch(string country);
      
      datetime    ParseDates(string date, string time);
      datetime    DateToday();
      
      datetime    LatestWeeklyCandle();
      int         WeeklyDelta();
      string      FileName(datetime file_date);
      string      FilePath(string file_name);
      
      int         GMTOffset();
      int         ServerOffset();
      int         Hours();
};


CNews::CNews(string path) {
   FILE_PATH(path);
}

void CNews::FILE_PATH(string path) { PATH = path; }


int CNews::ClearHandle(void){
   FileClose(FILE_HANDLE);
   FileFlush(FILE_HANDLE);
   return ResetHandle();
}

int CNews::ResetHandle(void){
   FILE_HANDLE = 0; 
   return FILE_HANDLE;
}

int CNews::ClearArray(SFFEvent &data[]){
   ArrayFree(data);
   ArrayResize(data, 0);
   return ArraySize(data);
}

int CNews::FetchData(void){
   ResetLastError();
   ClearArray(NEWS_CURRENT);
   ClearHandle();
   
   datetime latest = LatestWeeklyCandle();
   int delta = (int)(TimeCurrent() - latest);
   int weekly_delta = WeeklyDelta();
   
   datetime file_date = delta > weekly_delta ? latest + weekly_delta : latest;
   string file_path = FilePath(FileName(file_date));
   
   if (!FileExists(file_path)) {
      PrintFormat("%s: File %s not found. Downloading from forex factory.", __FUNCTION__, file_path);
      if (DownloadFromForexFactory(FileName(file_date)) == -1) PrintFormat("%s: Download Failed. Error: %i", __FUNCTION__, GetLastError());   
   }
   else PrintFormat("%s: File %s found", __FUNCTION__, file_path);
   
   string result[];
   ushort sep_char = StringGetCharacter(",", 0);
   
   int line = 0; 
   
   FILE_HANDLE = FileOpen(file_path, FILE_CSV | FILE_READ | FILE_ANSI, "\n");
   if (FILE_HANDLE < 0) return -1; 
   
   while (!FileIsLineEnding(FILE_HANDLE)) {
      
      string file_string = FileReadString(FILE_HANDLE);
      
      int split = (int)StringSplit(file_string, sep_char, result);
      line ++; 
      
      if (line == 1) continue;
      
      SFFEvent event; 
      event.title = result[0];
      event.country = result[1];
      event.time = ParseDates(result[2], result[3]);
      event.impact = result[4];
      event.forecast = result[5];
      event.previous = result[6];
      AppendToNews(event, NEWS_CURRENT);
   }
   
   
   return NumNews();
}

bool CNews::FileExists(string file_path) {
   int handle = FileOpen(file_path, FILE_CSV | FILE_READ | FILE_ANSI, "\n");
   if (handle < 0) return false;
   FileClose(handle);
   FileFlush(handle);
   return true;
}

datetime CNews::ParseDates(string date,string time) {
   
   string result[];
   
   ushort u_sep = StringGetCharacter("-", 0); 
   int split = StringSplit(date, u_sep, result);
   
   int gmt_offset_hours = GMTOffset() / Hours();
   int server_offset_hours = ServerOffset() / Hours(); 
   int gmt_server_offset_hours = gmt_offset_hours - server_offset_hours - 1;
   
   int gmt_server_offset_seconds = gmt_server_offset_hours * Hours();
   
   datetime time_string = StringToTime(time);
   MqlDateTime event_date, event_time; 
   TimeToStruct(time_string, event_time);
   
   bool IsPM = StringFind(time, "pm") > -1 ? true : false;
   
   event_time.mon = (int)result[0];
   event_time.day = (int)result[1];
   event_time.year = (int)result[2];
   
   event_time.hour = !IsPM ? event_time.hour == 12 ? 0 : event_time.hour : event_time.hour != 12 ? event_time.hour + 12 : event_time.hour;
   
   datetime event = StructToTime(event_time);
   
   datetime final_dt = event + gmt_server_offset_seconds;
   
   return final_dt;
}

int CNews::AppendToNews(SFFEvent &event,SFFEvent &data[]) {

   int size = ArraySize(data);
   ArrayResize(data, size + 1);
   data[size] = event;
   
   return ArraySize(data);
}

int CNews::DownloadFromForexFactory(string file_name) { 
   CFFCalendarDownload *downloader = new CFFCalendarDownload(PATH, 50000);
   bool success = downloader.Download(file_name);
   
   delete downloader; 
   if (!success) return -1;
   return NumNews();
}

int CNews::NewsSymbolToday(void) { 
   ClearArray(NEWS_SYMBOL_TODAY);
   int size = NumNews();
   
   for (int i = 0; i < size; i ++) {
      SFFEvent event = NEWS_CURRENT[i];
      if (!SymbolMatch(event.country)) continue;
      if (!DateMatch(DateToday(), event.time)) continue; 
      AppendToNews(event, NEWS_SYMBOL_TODAY);
   }
   
   return ArraySize(NEWS_SYMBOL_TODAY);
}

bool CNews::DateMatch(datetime target,datetime reference) { 
   if (StringFind(TimeToString(target), TimeToString(reference, TIME_DATE)) == -1) return false; 
   return true;
}

bool CNews::SymbolMatch(string country) {
   if (StringFind(Symbol(), country) == -1) return false;
   return true;
}

datetime CNews::DateToday(void)                 { return StringToTime(TimeToString(TimeCurrent(), TIME_DATE)); }
datetime CNews::LatestWeeklyCandle(void)        { return iTime(Symbol(), PERIOD_W1, 0); }
int      CNews::WeeklyDelta(void)               { return PeriodSeconds(PERIOD_W1); }             
string   CNews::FileName(datetime file_date)    { return StringFormat("%s.csv", TimeToString(file_date, TIME_DATE)); }
string   CNews::FilePath(string file_name)      { return StringFormat("%s\\%s", PATH, file_name); }
int      CNews::NumNews(void)                   { return ArraySize(NEWS_CURRENT); }
int      CNews::GMTOffset(void)                 { return (int)MathAbs(TimeGMTOffset()); }
int      CNews::ServerOffset(void)              { return (int)(TimeLocal() - TimeCurrent()); }
int      CNews::Hours(void)                     { return PeriodSeconds(PERIOD_H1); }