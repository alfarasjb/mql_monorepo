/*
STUFF TO TEST  

FUNCTIONALITY
Increment and Decrement (Expected Output) -> SL, TP, Volume, Pending
Edit String Expected Output
Switching 
Sending Orders by button press 
*/

#include "../oct_include.mqh"

enum TestResult{
   Passed = 0,
   Failed = 1
};

TestResult testresult;

struct TestFunction{
   string method;
   string expected_bool;
   string true_value_bool; 
   double lot_size;
   TestResult result;
   
   void stat(string mthd, string exp_val, string true_val){
      method = mthd;
      expected_bool = exp_val;
      true_value_bool = true_val;
      
      result = expected_bool == true_value_bool ? Passed : Failed;
   }
} testfunc;


class TradeTool_Tests{
   protected: 
   private:
      double         step;
      int            passed, failed, total;
      TestFunction   added[];
      void           success();
      void           fail();
      void           add_tests(TestFunction &test_function);
      void           reset_tests();   
   
   
      void           SetConstants();
      void           summarize();
      void           validate(string function, string expected, string true_value);
      void           delete_pending_tests();
      bool           is_pending();
      void           toggle_sl_tp();
   
      
      void           edit_entry(string object_name, string text){ ObjectSetString(0, object_name, OBJPROP_TEXT, (string)text); }
      void           trigger_button_press(string sparam);
      
      double         get_parent_value(string sparam);
      
      
      // BUTTONS
      string         SL_INC, SL_DEC, TP_INC, TP_DEC, VOL_INC, VOL_DEC, PENDING_INC, PENDING_DEC, SL_ON, SL_OFF, TP_ON, TP_OFF, MARKET_BUY, MARKET_SELL, BUY_LIMIT, SELL_LIMIT, BUY_STOP, SELL_STOP;
      // FIELDS
     
      string         SL_FIELD, TP_FIELD, VOL_FIELD, PENDING_FIELD;
      
   public:
   
      TradeTool_Tests(void);
      
      
      void        test_max_lot(bool expected, double lot);
      void        test_min_lot(bool expected, double lot);
      void        test_min_points_value(int expected);
      void        test_min_points_bool(bool expected, double points);
      
      void        test_buy_limit();
      void        test_buy_limit_error();
      void        test_sell_limit();
      void        test_sell_limit_error();
      void        test_buy_stop();
      void        test_buy_stop_error();
      void        test_sell_stop();
      void        test_sell_stop_error();
      
      
      void        run_main_test();
      void        run_test();
      void        run_interface_test();
      void        run_order_by_button_test();
   
      void        test_increment_sl();  
      void        test_decrement_sl();
      void        test_increment_tp();
      void        test_decrement_tp();
      void        test_increment_vol();
      void        test_decrement_vol();
      void        test_increment_pending();
      void        test_decrement_pending();
      void        test_toggle_sl_on();
      void        test_toggle_sl_off();
      void        test_toggle_tp_on();
      void        test_toggle_tp_off();
      void        test_buy_limit_button();
      void        test_sell_limit_button();
      void        test_buy_stop_button();
      void        test_sell_stop_button();
   
};

TradeTool_Tests::TradeTool_Tests(void){ 

   
}

void TradeTool_Tests::SetConstants(){
   SL_INC = tradetool_app.adjust_sl.increment.name;
   SL_DEC = tradetool_app.adjust_sl.decrement.name;
   TP_INC = tradetool_app.adjust_tp.increment.name;
   TP_DEC = tradetool_app.adjust_tp.decrement.name;
   VOL_INC = tradetool_app.adjust_volume.increment.name;
   VOL_DEC = tradetool_app.adjust_volume.decrement.name;
   PENDING_INC = tradetool_app.adjust_pending.increment.name;
   PENDING_DEC = tradetool_app.adjust_pending.decrement.name;
   
   SL_ON = tradetool_app.sl_toggle.on_name;
   SL_OFF = tradetool_app.sl_toggle.off_name;
   
   TP_ON = tradetool_app.tp_toggle.on_name;
   TP_OFF = tradetool_app.tp_toggle.off_name;
   
   MARKET_BUY = tradetool_app.market_buy.button_name;
   MARKET_SELL = tradetool_app.market_sell.button_name;
   BUY_LIMIT = tradetool_app.buy_limit.button_name;
   BUY_STOP = tradetool_app.buy_stop.button_name;
   SELL_LIMIT = tradetool_app.sell_limit.button_name;
   SELL_STOP = tradetool_app.sell_stop.button_name;
   
   SL_FIELD = tradetool_app.adjust_sl.field_name;
   TP_FIELD = tradetool_app.adjust_tp.field_name;
   VOL_FIELD = tradetool_app.adjust_volume.field_name;
   PENDING_FIELD = tradetool_app.adjust_pending.field_name; 
}

void TradeTool_Tests::run_main_test(){
   SetConstants();
   run_test();
   run_interface_test();
   run_order_by_button_test();
   summarize();
}

void TradeTool_Tests::run_test(){
      /*
      Test conditions
      */
      step = (tradetool_main.POINTS_STEP_INPUT) / tradetool_main.CONTRACT; 
      reset_tests();
      
      test_min_lot(true, 0.01);
      test_min_lot(false, 0.02);
      test_max_lot(true, 100000);
      test_max_lot(false, 0.01);
      test_min_points_value(0);
      test_min_points_bool(false, 10);
      test_min_points_bool(true, 0);
      
      test_buy_limit();
      test_buy_limit_error();
      test_sell_limit();
      test_sell_limit_error();
      
      test_buy_stop();
      test_buy_stop_error();
      test_sell_stop();
      test_sell_stop_error();
      
      //summarize();
}

void TradeTool_Tests::run_interface_test(void){
   /*
   Increment and Decrement (Expected Output) -> SL, TP, Volume, Pending
   Edit String Expected Output
   Switching 
   Sending Orders by button press 
   */
   //run_test();
   test_increment_sl();
   test_decrement_sl();
   test_increment_tp();
   test_decrement_tp();
   test_increment_vol();
   test_decrement_vol();
   test_increment_pending();
   test_decrement_pending();
   test_toggle_sl_on();
   test_toggle_sl_off();
   test_toggle_tp_on();
   test_toggle_tp_off();
   
   //test_sell_limit_button();
}

void TradeTool_Tests::run_order_by_button_test(){
   // ORDERS HERE
   // TURN ON SL AND TP 
   
   toggle_sl_tp();
   
   // ORDER TESTS HERE
   test_buy_limit_button();
   test_sell_limit_button();
   test_buy_stop_button();
   test_sell_stop_button();
   summarize();
}

void TradeTool_Tests::toggle_sl_tp(){
   trigger_button_press(SL_ON);
   trigger_button_press(TP_ON);
}

void TradeTool_Tests::test_buy_limit_button() {
   //trigger_button_press(pending_sparam);
   double entry_price = tradetool_main.util_ask() - tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   edit_entry(PENDING_FIELD, entry_price);
   
   
   double sl_points = tradetool_main.util_get_values(SL_FIELD);
   double tp_points = tradetool_main.util_get_values(TP_FIELD);
   
   double sl_step = sl_points * point();
   double tp_step = tp_points * point();
   
   double expected_sl = entry_price - sl_step;
   double expected_tp = entry_price + tp_step;
   
   trigger_button_press(BUY_LIMIT);
   
   int s = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
   double true_sl = OrderStopLoss();
   double true_tp = OrderTakeProfit();
   double true_entry = OrderOpenPrice();
   
   validate("buy_limit_sl", (string)expected_sl, (string)true_sl);
   validate("buy_limit_tp", (string)expected_tp, (string)true_tp);
   validate("buy_limit_entry",(string)tradetool_main.TRADE_ENTRY, (string) true_entry);
   
   delete_pending_tests();
   
   edit_entry(PENDING_FIELD, "0");
}

void TradeTool_Tests::test_sell_limit_button() {
   
   double entry_price = tradetool_main.util_bid() + tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   edit_entry(PENDING_FIELD, entry_price);
   
   double sl_points = tradetool_main.util_get_values(SL_FIELD);
   double tp_points = tradetool_main.util_get_values(TP_FIELD);
   
   double sl_step = sl_points * point();
   double tp_step = tp_points * point();
   
   double expected_sl = entry_price + sl_step;
   double expected_tp = entry_price - tp_step;
   
   trigger_button_press(SELL_LIMIT);
   
   int s = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
   double true_sl = OrderStopLoss();
   double true_tp = OrderTakeProfit();
   double true_entry = OrderOpenPrice();
   
   validate("sell_limit_sl", (string)expected_sl, (string)true_sl);
   validate("sell_limit_tp", (string)expected_tp, (string)true_tp);
   validate("sell_limit_entry",(string)tradetool_main.TRADE_ENTRY, (string) true_entry);
   
   delete_pending_tests();  
   
   string pending_field = tradetool_app.adjust_pending.field_name;
   edit_entry(pending_field, "0");

}

void TradeTool_Tests::test_buy_stop_button(){
   
   double entry_price = tradetool_main.util_ask() + tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   edit_entry(PENDING_FIELD, entry_price);
   
   double sl_points = tradetool_main.util_get_values(SL_FIELD);
   double tp_points = tradetool_main.util_get_values(TP_FIELD);
   
   double sl_step = sl_points * point();
   double tp_step = tp_points * point();
   
   double expected_sl = entry_price - sl_step;
   double expected_tp = entry_price + tp_step;
   
   trigger_button_press(BUY_STOP);
   
   int s = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
   double true_sl = OrderStopLoss();
   double true_tp = OrderTakeProfit();
   double true_entry = OrderOpenPrice();
   
   validate("buy_stop_sl", (string)expected_sl, (string)true_sl);
   validate("buy_stop_tp", (string)expected_tp, (string)true_tp);
   validate("buy_stop_entry",(string)tradetool_main.TRADE_ENTRY, (string) true_entry);
   
   delete_pending_tests();   
   string pending_field = tradetool_app.adjust_pending.field_name;
   edit_entry(pending_field, "0");
}

void TradeTool_Tests::test_sell_stop_button(){
   
   double entry_price = tradetool_main.util_bid() - tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   edit_entry(PENDING_FIELD, entry_price);
   
   double sl_points = tradetool_main.util_get_values(SL_FIELD);
   double tp_points = tradetool_main.util_get_values(TP_FIELD);
   
   double sl_step = sl_points * point();
   double tp_step = tp_points * point();
   
   double expected_sl = entry_price + sl_step;
   double expected_tp = entry_price - tp_step;
   
   trigger_button_press(SELL_STOP);
   
   int s = OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
   double true_sl = OrderStopLoss();
   double true_tp = OrderTakeProfit();
   double true_entry = OrderOpenPrice();
   
   validate("sell_stop_sl", (string)expected_sl, (string)true_sl);
   validate("sell_stop_tp", (string)expected_tp, (string)true_tp);
   validate("sell_stop_entry",(string)tradetool_main.TRADE_ENTRY, (string) true_entry);
   
   delete_pending_tests();  
   string pending_field = tradetool_app.adjust_pending.field_name;
   edit_entry(pending_field, "0");
}

void TradeTool_Tests::test_toggle_sl_on(){

   
   bool value = tradetool_main.TRADE_SL_ON;
   bool expected_value = !value; 
   
   trigger_button_press(SL_ON);
      
   bool true_value = tradetool_main.TRADE_SL_ON;
   
   validate("toggle_sl_on", (string)expected_value, (string)true_value);   
}

void TradeTool_Tests::test_toggle_sl_off(){
   bool value = tradetool_main.TRADE_SL_ON;
   bool expected_value = !value;
   
   trigger_button_press(SL_OFF);
   
   bool true_value = tradetool_main.TRADE_SL_ON;
   
   validate("toggle_sl_off", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_toggle_tp_on(){
   bool value = tradetool_main.TRADE_TP_ON;
   bool expected_value = !value;
   
   trigger_button_press(TP_ON);
   
   bool true_value = tradetool_main.TRADE_TP_ON;
   
   validate("toggle_tp_on", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_toggle_tp_off(){
   
   bool value = tradetool_main.TRADE_TP_ON;
   bool expected_value = !value;
   
   trigger_button_press(TP_OFF);
   
   bool true_value = tradetool_main.TRADE_TP_ON;
   
   validate("toggle_tp_off", (string)expected_value, (string)true_value);
}

double TradeTool_Tests::get_parent_value(string sparam){
   AdjustButton button = tradetool_app.GetAdjustFunction(sparam);
   string parent = button.parent;
   double parent_value = tradetool_main.util_get_values(parent);
   return parent_value;
}

void TradeTool_Tests::test_increment_sl(){
   
   double field_value = get_parent_value(SL_INC);
   double expected_value = field_value + tradetool_main.POINTS_STEP_INPUT;
   // TRIGGER BUTTON PRESS HERE 
   trigger_button_press(SL_INC);
   
   // PRINT OUTPUT VALUE 
   double true_value = get_parent_value(SL_INC);
   
   validate("increment_sl", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_decrement_sl(){
   
   double field_value = get_parent_value(SL_DEC);
   double expected_value = field_value - tradetool_main.POINTS_STEP_INPUT;
   
   trigger_button_press(SL_DEC);
   
   double true_value = get_parent_value(SL_DEC);
   
   validate("decrement_sl", (string)expected_value, (string)true_value);
   
}

void TradeTool_Tests::test_increment_tp(){
   
   double field_value = get_parent_value(TP_INC);
   double expected_value = field_value + tradetool_main.POINTS_STEP_INPUT;
   // TRIGGER BUTTON PRESS HERE 
   trigger_button_press(TP_INC);
   
   // PRINT OUTPUT VALUE 
   double true_value = get_parent_value(TP_INC);
   
   validate("increment_tp", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_decrement_tp(){
   
   double field_value = get_parent_value(TP_DEC);
   double expected_value = field_value - tradetool_main.POINTS_STEP_INPUT;
   
   trigger_button_press(TP_DEC);
   
   double true_value = get_parent_value(TP_DEC);
   
   validate("decrement_tp", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_increment_vol(){
   
   double field_value = get_parent_value(VOL_INC);
   double expected_value = field_value == tradetool_main.MAX_LOT ? tradetool_main.MAX_LOT : field_value + tradetool_main.LOT_STEP;
   
   trigger_button_press(VOL_INC);
   
   double true_value = get_parent_value(VOL_INC);
   
   validate("increment_volume", (string)expected_value, (string)true_value);
   
}

void TradeTool_Tests::test_decrement_vol(){

   
   double field_value = get_parent_value(VOL_DEC);
   double expected_value = field_value == tradetool_main.MIN_LOT ? tradetool_main.MIN_LOT : field_value - tradetool_main.LOT_STEP;
   
   trigger_button_press(VOL_DEC);
   
   double true_value = get_parent_value(VOL_DEC);
   
   validate("decrement_volume", (string)expected_value, (string)true_value);
}

void TradeTool_Tests::test_increment_pending(){
   
   double field_value = get_parent_value(PENDING_INC);
   field_value = field_value == 0 ? tradetool_main.util_bid() : field_value;
   
   double expected_value = field_value + tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   
   trigger_button_press(PENDING_INC);
   
   double true_value = get_parent_value(PENDING_INC);
   
   validate("increment_pending", (string)expected_value, (string)true_value);
   
}


void TradeTool_Tests::test_decrement_pending(){
   double field_value = get_parent_value(PENDING_DEC);
   field_value = field_value == 0 ? tradetool_main.util_bid() : field_value;
   double expected_value = field_value - tradetool_main.POINTS_STEP_INPUT / tradetool_main.CONTRACT;
   
   trigger_button_press(PENDING_DEC);
   
   double true_value = get_parent_value(PENDING_DEC);
   
   validate("decrement_pending", (string)expected_value, (string)true_value);
}



void TradeTool_Tests::trigger_button_press(string sparam){
   int id = 0;
   long lparam = 0;
   double daram = 0.0; 
   
   OnChartEvent(id, lparam, daram, sparam);
}

void TradeTool_Tests::success(){
   total ++;
   passed ++;
}

void TradeTool_Tests::fail(){
   total ++;
   failed ++;
}

void TradeTool_Tests::add_tests(TestFunction &test_function){
   int current_size = ArraySize(added);
   ArrayResize(added, current_size + 1);
   added[current_size] = test_function;
}

void TradeTool_Tests::reset_tests(){
   ArrayFree(added);
}


void TradeTool_Tests::summarize(){
   PrintFormat("%i out of %i tests passed.", passed, total);
   
   for (int i = 0; i < ArraySize(added); i ++){
      string method = added[i].method;
      string expected = added[i].expected_bool;
      string true_val = added[i].true_value_bool;
      string test_result = EnumToString(added[i].result);
      //Print(test_result);
      PrintFormat("Method: %s, Expected: %s, True: %s, Result: %s", method, (string)expected, (string)true_val, test_result);
      
   }
   reset_tests();
}


void TradeTool_Tests::validate(string function, string expected, string true_value){
   testfunc.stat(function, expected, true_value);
   add_tests(testfunc);
   if (expected == true_value) success();
   else fail();
}


void TradeTool_Tests::delete_pending_tests(){

   int orders_total = OrdersTotal();
   int pending_tickets[];
   
   for (int i = 0; i < orders_total; i ++){
      int t = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (is_pending()){
         int num_pending = ArraySize(pending_tickets);
         ArrayResize(pending_tickets, num_pending + 1);
         pending_tickets[num_pending] = OrderTicket();
      }
   }
   
   int num_pending = ArraySize(pending_tickets);
   
   for (int i = 0; i < num_pending; i++){
      int ticket = pending_tickets[i];
      int d = OrderDelete(ticket, clrNONE);
   }
}

bool TradeTool_Tests::is_pending(){
   int ord_type = OrderType();
   
   switch(ord_type){
      case 0: 
      case 1:
         return false; 
         break; 
      case 2:
      case 3: 
      case 4:
      case 5: 
         return true; 
         break;
      default:
         return false; 
   }
   return false;
}


void TradeTool_Tests::test_max_lot(bool expected, double lot){

   bool true_value = tradetool_app.MaxLot(lot);
   
   testfunc.stat("max_lot", expected, true_value);
   add_tests(testfunc);
   
   if (expected == true_value) success();
   else fail();
   
}

void TradeTool_Tests::test_min_lot(bool expected, double lot){

   bool true_value = tradetool_app.MinLot(lot);
      
   
   validate("min_lot", (string)expected, (string)true_value);
}

void TradeTool_Tests::test_min_points_value(int expected){
   
   int true_value = 0;
   
   validate("min_points", (string)expected, (string)true_value);
   
}

void TradeTool_Tests::test_min_points_bool(bool expected, double points){
   bool true_value = tradetool_app.MinPoints(points);
   
   
   validate("min_points", (string)expected, (string)true_value);

}

void TradeTool_Tests::test_buy_limit(){
   /*
   Testing Pending Orders: First set trade parameters. entry, stop, target
   */
   
   ENUM_ORDER_TYPE ord = ORDER_TYPE_BUY_LIMIT;
   
   double entry = ask() - step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = true_value > 0 ? true_value : 100;
   

   validate("success_buy_lim", (string)expected, (string)true_value);
   delete_pending_tests();
}

void TradeTool_Tests::test_buy_limit_error(){
   
   ENUM_ORDER_TYPE ord = ORDER_TYPE_BUY_LIMIT;

   double entry = ask() + step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = -30;
   
   
   validate("err_buy_lim", (string)expected, (string)true_value);
   delete_pending_tests();
}

void TradeTool_Tests::test_sell_limit(){
   
   ENUM_ORDER_TYPE ord = ORDER_TYPE_SELL_LIMIT;
   
   double entry = bid() + step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = true_value > 0 ? true_value : 100;
   
   
   validate("success_sell_lim", (string)expected, (string)true_value);
   delete_pending_tests();
}

void TradeTool_Tests::test_sell_limit_error(){
   
   ENUM_ORDER_TYPE ord = ORDER_TYPE_SELL_LIMIT;
   
   double entry = bid() - step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = -40;
   
   validate("err_sell_lim", (string)expected, (string)true_value);
   delete_pending_tests();
   
}

void TradeTool_Tests::test_buy_stop(){
   
   ENUM_ORDER_TYPE ord = ORDER_TYPE_BUY_STOP;
   
   double entry = ask() + step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = true_value > 0 ? true_value : 100;
   
   
   validate("success_buy_stop", (string)expected, (string)true_value);
   delete_pending_tests();
   
}

void TradeTool_Tests::test_buy_stop_error(){

   ENUM_ORDER_TYPE ord = ORDER_TYPE_BUY_STOP;
   
   double entry = ask() - step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = -50;
   
   
   validate("err_buy_stop", (string)expected, (string)true_value);
   delete_pending_tests();
}

void TradeTool_Tests::test_sell_stop(){
   ENUM_ORDER_TYPE ord = ORDER_TYPE_SELL_STOP;
   
   double entry = bid() - step;
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = true_value > 0 ? true_value : 100;
   
   
   validate("success_sell_stop", (string)expected, (string)true_value);
   delete_pending_tests();
}

void TradeTool_Tests::test_sell_stop_error(){
   ENUM_ORDER_TYPE ord = ORDER_TYPE_SELL_STOP;
   
   
   double entry = bid() + step;
   
   edit_entry("EDITPENDING", (string)entry);
   
   int true_value = tradetool_main.SendOrder(ord);
   int expected = -60;
   
   validate("err_sell_stop", (string)expected, (string)true_value);
   delete_pending_tests();
}


TradeTool_Tests tradetool_tests;

double point()                         { return SymbolInfoDouble(tradetool_main.SYMBOL, SYMBOL_POINT); }

double ask()   { return tradetool_main.util_ask(); }
double bid()   { return tradetool_main.util_bid(); }

