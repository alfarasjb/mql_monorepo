
#include <B63/CInetDownload.mqh>

struct SCalendarEvent {
   string   title;
   string   country;
   datetime date;
   datetime time;
   string   impact;  
   string   forecast;
   string   previous;
};

enum Source{
   FXFACTORY_WEEKLY,
   R4F_WEEKLY,
};


const string FXFACTORY_WEEKLY_URL       = "https://nfs.faireconomy.media/ff_calendar_thisweek.csv";
const string R4F_WEEKLY_URL             = "http://www.robots4forex.com/news/week.php";


class CCalendarDownload : public CINetDownload {
   protected:
      void        ParseFXFACTORYResponse();
      void        ParseR4FResponse();
      string      ParseImpact(string impact);
    
   public:
      CCalendarDownload():CINetDownload(){};
      CCalendarDownload(string path, int timeout):CINetDownload(path, timeout){};
      ~CCalendarDownload(){};
      
      SCalendarEvent     Events[];
      int         Count; 
      
      
      bool        Download(string file_name, Source src);
      string      URL(Source src);
      int         ResetEvents();
};



string   CCalendarDownload::URL(Source src) {
   
   switch(src) {
      case FXFACTORY_WEEKLY: return FXFACTORY_WEEKLY_URL;
      case R4F_WEEKLY: return R4F_WEEKLY_URL;
      default: return "";
   }
}


string   CCalendarDownload::ParseImpact(string impact) { 
   if (impact == "H") return "High";
   if (impact == "M") return "Medium";
   if (impact == "L") return "Low";
   return "";
}


bool     CCalendarDownload::Download(string file_name, Source src) { 

   ResetEvents();
   
   string   url      = URL(src);
   Print("URL: ", url);
   bool     result   = CINetDownload::Download(url, file_name);
   if (!result) return false; 
   
   switch (src) {
      case FXFACTORY_WEEKLY:  ParseFXFACTORYResponse(); break; 
      case R4F_WEEKLY:        ParseR4FResponse();  break;
   }
   
   return true;
   
}

int      CCalendarDownload::ResetEvents(void) { 
   ArrayFree(Events);
   ArrayResize(Events, 0);
   return ArraySize(Events);
}


void     CCalendarDownload::ParseR4FResponse(void){
   string lines[], columns[], date_parts[];
   int size = StringSplit(mResponse, '\n', lines);
   
   Count = size - 1; 
   ArrayResize(Events, Count);
   
   for (int i = 0; i < Count; i++) {
      StringSplit(StringTrimLeft(StringTrimRight(lines[i+1])), ',', columns);
      int num_columns = ArraySize(columns);
      
      if (num_columns == 0) continue;
      if (StringFind(columns[0], "/", 0) < 0) continue;
      
      // build date string YYYY.MM.DD HH:MM from M/D/YYYY
      StringSplit(columns[0], '/', date_parts);
      string datetime_string = StringFormat("%s.%s.%s %s", date_parts[0], date_parts[1], date_parts[2], columns[1]);
      MqlDateTime r4fdate; 
      TimeToStruct(StringToTime(datetime_string), r4fdate); 
      r4fdate.hour = r4fdate.hour + 2; 
      
      datetime r4fdatetime = StructToTime(r4fdate);
      
      Events[i].time = r4fdatetime;
      Events[i].country = columns[2];
      Events[i].impact = ParseImpact(columns[3]);
      Events[i].title = columns[4];
      
   }
}


void     CCalendarDownload::ParseFXFACTORYResponse(void){
   string   lines[];
   string   columns[];
   int      size  =  StringSplit(mResponse, '\n', lines);
   
   //Remember the size includes the heading line
   Count    =  size - 1;
   ArrayResize(Events, Count);
   string   dateParts[];
   string   timeParts[];
   for (int i = 0; i < Count; i++){
      #ifdef __MQL4__
         StringSplit(StringTrimLeft(StringTrimRight(lines[i + 1])), ',', columns);
      #endif
      #ifdef __MQL5__
         StringTrimRight(lines[i + 1]);
         StringTrimLeft(lines[i + 1]);
         StringSplit(lines[i + 1]), ',', columns);
      #endif
      // some items are simple strings
      Events[i].title   =  columns[0];
      Events[i].country =  columns[1];
      Events[i].impact  =  columns[4];
      
      //Date and time are stored separately and not in a format 
      //easy to convert
      //stored as MM-DD-YYYY HH:MM(am/pm)
      //break up the date and time into parts
      StringSplit(columns[2], '-', dateParts);
      StringSplit(columns[3], ':', timeParts);
      
      // converting am/pm to 24h 
      if (timeParts[0] == "12"){
         timeParts[0]   =  "00";
      }
      // if pm just add 12 hrs
      if (StringSubstr(timeParts[1], 2, 1) =="p"){
         timeParts[0]   =  IntegerToString(StringToInteger(timeParts[0] + (string)12));
      }
      // take only the first 2 characters from the minutes (remove am/pm)
      timeParts[1]   = StringSubstr(timeParts[1], 0, 2);
      
      //Join back to YYYY.MM.DD HH:MM
      string timeString = dateParts[2] + "." + dateParts[0] + "." + dateParts[1]
                           + " " + timeParts[0] + ":" + timeParts[1];
                  
      Events[i].time    =  StringToTime(timeString);
      MqlDateTime adjTime;
      TimeToStruct(Events[i].time, adjTime);
      adjTime.hour = adjTime.hour + 3;
      
      Events[i].time    = StructToTime(adjTime);
      
      
      
      //Values in forecast and previous may be in different formats
      // just store as string to make it simple
      Events[i].forecast   =  columns[5];
      Events[i].previous   =  columns[6];
   }
   
  
}