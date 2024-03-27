//###<Experts/B63/b63-mt4-experts/Prod/oct/TradeTool.mq4>


#property strict

#include "tests/tests.mqh"
#include "definition.mqh"
#include "tradetool_app.mqh"
// SCREEN ADJUSTMENTS // 



CTradeToolApp tradetool_app(UI_X, UI_Y, UI_WIDTH, UI_HEIGHT);

int OnInit() {
   
   tradetool_main.SetMarketLimits();
   tradetool_main.SetInputs(InpDefLots, InpDefStop, InpDefTP, InpMagic, InpPointsStep);
   
   tradetool_app.InitializeUIElements();
   tradetool_app.UpdatePrice(tradetool_app.Norm(tradetool_main.util_ask()), tradetool_app.Norm(tradetool_main.util_bid()));
   
   Print(tradetool_main.SYMBOL);
   if (InpRunTests) tradetool_tests.run_main_test();
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)  { ObjectsDeleteAll(0, 0, -1); }

void OnTick()                    { tradetool_app.UpdatePrice(tradetool_app.Norm(tradetool_main.util_ask()), tradetool_app.Norm(tradetool_main.util_bid())); }


void OnChartEvent(const int id, const long &lparam, const double &daram, const string &sparam){
   
   if (CHARTEVENT_OBJECT_CLICK){  
      
      if (tradetool_app.ObjectIsButton(sparam, tradetool_app.order_buttons)) {
         tradetool_app.EVENT_TRADE(sparam, tradetool_main);
      }
      if (tradetool_app.ObjectIsToggle(sparam, tradetool_app.switches)) {
         tradetool_app.EVENT_TOGGLE(sparam);
      }
      if (tradetool_app.ObjectIsRow(sparam, tradetool_app.adjust_row)){
         AdjustButton adjust_button = tradetool_app.GetAdjustFunction(sparam);
         tradetool_app.EVENT_ADJUST(adjust_button);
      }
    
   }
   if (CHARTEVENT_OBJECT_ENDEDIT){
      if (tradetool_app.ObjectIsRow(sparam, tradetool_app.adjust_row)){
         tradetool_app.EVENT_EDIT(sparam);
      }
   }
   ChartRedraw();
}




