
#include <B63/CObjects.mqh>
#include "definition.mqh"
#include <B63/ui/CInterface.mqh>
#include "tradetool_main.mqh"

CTradeToolMain tradetool_main(InpDefLots, InpDefStop, InpDefTP, InpMagic, InpPointsStep);
// CINTERFACE: LAYOUT
// CTRADETOOLAPP: EVENT HANDLING


/*
TODOS

Clean up naming convention and methods 
Migrate Event Handling
Padding, UI etc
*/

struct Elements_List{
   string elements[];
};

class CTradeToolApp : public CInterface{
   protected:
   private:
      color          THEME_FONT_COLOR, THEME_BUTTON_BORDER_COLOR, THEME_BUY_COLOR, THEME_SELL_COLOR, THEME_ROW_BUTTON_BG_COLOR, THEME_ROW_BUTTON_BORDER_COLOR, THEME_EDIT_COLOR; 
      int            APP_COL_1, APP_COL_2, APP_ROW_1, APP_ROW_2, APP_ROW_3;
      
      // MARKET
      //string         SYMBOL;
      //double         MAX_LOT, MIN_LOT, LOT_STEP, CONTRACT;
      //int            DIGITS;
      
   public: 
   
      CTradeToolApp(int ui_x, int ui_y, int ui_width, int ui_height);
      ~CTradeToolApp() {}
      
      Button         order_buttons[];
      AdjustRow      adjust_row[];
      Toggle         switches[];
      
      
      Terminal       terminal;
      Button         market_buy, market_sell, buy_limit, sell_limit, buy_stop, sell_stop;
      Toggle         sl_toggle, tp_toggle, vol_toggle, pending_toggle;
      AdjustRow      adjust_sl, adjust_tp, adjust_volume, adjust_pending;
      AdjustButton   sl_inc, sl_dec, tp_inc, tp_dec, vol_inc, vol_dec, pending_inc, pending_dec;
      RectLabel      main, header_1, header_2;
      Elements_List  Elements;
      
   
      //void        SetMarketLimits();
      void        InitializeUIElements();
      
      // OBJECTS
      void        DrawOrderButton(Button &button, ENUM_ORDER_TYPE order_type, string name, int x, int y_adjust, double width_factor, double height_factor, color button_color, string label_handle, string label_name, int label_adjust, int label_x_offset);
      void        DrawRectLabel(RectLabel &rect, string name, int x, int y, int width, int height,ENUM_BORDER_TYPE border, int line_width);
      void        DrawAdjustRow(AdjustRow &adjust_element, string prefix, int bg_x, int bg_y, int bg_width, int bg_height, int edit_width, int edit_height, int bt_size, string edit_text, int font_size);
      void        DrawMainRow(Toggle &toggle_element, AdjustRow &adjust_element, string row_name, int row, string edit_text, bool state, bool show_switch, int bg_x);
      void        DrawSLRow(double inp = NULL, bool state = NULL);
      void        DrawTPRow(double inp = NULL, bool state = NULL);
      void        DrawVolRow(double inp = NULL);
      void        DrawPORow(double inp = NULL);
      void        UpdatePrice(string ask, string bid);
      
      // EVENT 
      void        EVENT_TRADE(string sparam, CTradeToolMain &tradetool);
      void        EVENT_ADJUST(AdjustButton &adjust);
      void        EVENT_EDIT(string sparam);
      void        EVENT_TOGGLE(string sparam);
      
      // UTILITIES
      void        AddObjectToList(Button &order_button, Button &list[]);
      bool        ObjectIsButton(string name, Button &list[]);  
      bool        ObjectIsRow(string name, AdjustRow &list[]);
      bool        ObjectIsEdit(string name, AdjustRow &list[]);
      bool        ObjectIsToggle(string name, Toggle &list[]);
      
      AdjustButton      GetAdjustFunction(string name);
      
      bool        MinLot(double lot);
      bool        MaxLot(double lot);
      bool        MinPoints(double points);
      
      string      Norm(double val, int digits = NULL);
      double      Adjust(double inp, double step, string sparam, double lower_limit = -1, double upper_limit = -1);
      double      NormLot(double lot, int digits = 2);
      
      
};

//+-------------------+
// CONSTRUCTOR        |
//                    |
//+-------------------+
CTradeToolApp::CTradeToolApp(int ui_x, int ui_y, int ui_width, int ui_height){

   UI_X = ui_x;
   UI_Y = ui_y;
   UI_WIDTH = 235;
   UI_HEIGHT = UI_Y - 5;
   
   UI_BORDER = BORDER_RAISED;
   UI_BG_COLOR = clrBlack;
   
   
   APP_COL_1 = 15;
   APP_COL_2 = 125;
   APP_ROW_1 = UI_Y - 45;
   APP_ROW_2 = UI_Y - 75;
   APP_ROW_3 = UI_Y - 105;
   
   DefFontStyle = UI_FONT;
   DefFontStyleBold = UI_FONT_BOLD;
   DefFontSize = FONT_SIZE;
   
   THEME_FONT_COLOR                    = DEF_FONT_COLOR; 
   THEME_BUTTON_BORDER_COLOR           = BUTTON_BORD_COLOR; 
   THEME_BUY_COLOR                     = BUY_COLOR;
   THEME_SELL_COLOR                    = SELL_COLOR;
   THEME_ROW_BUTTON_BG_COLOR           = ROW_BUTTON_BG;
   THEME_ROW_BUTTON_BORDER_COLOR       = ROW_BUTTON_BORD;
   THEME_EDIT_COLOR                    = EDIT_COLOR;
   
   tradetool_main.SetMarketLimits();
}

void CTradeToolApp::InitializeUIElements(){
   
   int RectLabelWidth      = 235; 
   int HeaderLineLen       = 205;
   int HeaderLineHeight    = 0; 
   
   int HeaderY             = UI_Y - 20;
   int HeaderX             = 15; 
   int HeaderFontSize      = 13; 


   UI_Terminal(terminal, "MAIN");
  
   CTextLabel("Symbol", HeaderX, HeaderY, Symbol(), HeaderFontSize, DefFontStyle, DefFontColor);
   DrawRectLabel(header_1, "Header", HeaderX, HeaderY - 15, HeaderLineLen, HeaderLineHeight, BORDER_FLAT, 1);
   DrawRectLabel(header_2, "Header2", HeaderX, HeaderY - 175, HeaderLineLen, HeaderLineHeight, BORDER_FLAT, 1);

   DrawOrderButton(market_buy, ORDER_TYPE_BUY, "BTBuy", APP_COL_2, 0, 1, 1, THEME_BUY_COLOR, "BuyLabel", "BUY", 0, 0);
   DrawOrderButton(market_sell, ORDER_TYPE_SELL,  "BTSell", APP_COL_1, 0, 1, 1, THEME_SELL_COLOR, "SellLabel", "SELL", 0, 0);
   DrawOrderButton(buy_limit, ORDER_TYPE_BUY_LIMIT, "BTBuyLim", APP_COL_2, 100, 1, 0.6, THEME_BUY_COLOR, "BuyLimitLabel", "BUY LIMIT", 100, 8);
   DrawOrderButton(sell_limit, ORDER_TYPE_SELL_LIMIT, "BTSellLim", APP_COL_1, 100, 1, 0.6, THEME_SELL_COLOR, "SellLimitLabel", "SELL LIMIT", 100, 8);
   DrawOrderButton(buy_stop, ORDER_TYPE_BUY_STOP, "BTBuyStop", APP_COL_2, 135, 1, 0.6, THEME_BUY_COLOR, "BuyStopLabel", "BUY STOP", 135, 8);
   DrawOrderButton(sell_stop, ORDER_TYPE_SELL_STOP, "BTSellStop", APP_COL_1, 135, 1, 0.6, THEME_SELL_COLOR, "SellStopLabel", "SELL STOP", 135, 8);
   
   const int x_offset = 15;
   CTextLabel("TFSL", x_offset, APP_ROW_1 - 13, "SL", 10, DefFontStyle);
   CTextLabel("TFTP", x_offset, APP_ROW_2 - 12, "TP", 10, DefFontStyle);
   CTextLabel("TFVol", x_offset, APP_ROW_3 - 11, "VOL", 10, DefFontStyle);
   CTextLabel("TFVolLots", x_offset + 175, APP_ROW_3 - 11, "Lots", 10, DefFontStyle);
   CTextLabel("TFPending", x_offset, APP_ROW_3 - 110, "PENDING", 10, DefFontStyle);
   
   DrawSLRow();
   DrawTPRow();
   DrawVolRow();
   DrawPORow();
   
}



void CTradeToolApp::DrawOrderButton(
      Button &button, 
      ENUM_ORDER_TYPE order_type, 
      string name, 
      int x, 
      int y_adjust, 
      double width_factor, 
      double height_factor, 
      color button_color, 
      string label_handle, 
      string label_name, 
      int label_adjust, 
      int label_x_offset){
   
   int DefButtonWidth = 105;
   int DefButtonHeight = 50; 
   int APP_YOffset = DefButtonHeight + UI_Y - 185;
   int OrdButtonYOffset = APP_YOffset - 13;
   
   int y = APP_YOffset - y_adjust;
   
   int width = (int)(DefButtonWidth * width_factor);
   int height = (int)(DefButtonHeight * height_factor);
   
   int label_offset = OrdButtonYOffset - label_adjust;
   int label_x = x + 10 + label_x_offset;
   long ZOrder = 5;
   
   button.button_name = name;
   button.button_order_type = order_type;
   AddObjectToList(button, order_buttons);
   
   CButton(name, x, y, width, height, DefFontSize, DefFontStyle, "", THEME_FONT_COLOR, button_color, THEME_BUTTON_BORDER_COLOR, DefCorner, DefHidden, ZOrder);
   CTextLabel(label_handle, label_x, label_offset, label_name, DefFontSize, DefFontStyle, THEME_FONT_COLOR);
}

void CTradeToolApp::DrawRectLabel(RectLabel &rect, string name, int x, int y, int width, int height,ENUM_BORDER_TYPE border, int line_width){

   rect.rect_name = name;
   CRectLabel(name, x, y, width, height, DefBGColor, DefBorderColor, DefCorner, DefBorderType, STYLE_SOLID, line_width);
   
}

void CTradeToolApp::DrawAdjustRow(
      AdjustRow &adjust_element,
      string prefix, 
      int bg_x, 
      int bg_y, 
      int bg_width, 
      int bg_height, 
      int edit_width, 
      int edit_height, 
      int bt_size, 
      string edit_text, 
      int font_size){
   
   
   const int space      = 3;
   
   const int edit_x     = (bg_width / 2) + bg_x - (edit_width / 2);
   const int bg_x_2     = bg_x + bg_width;
   const int bt_x_plus  = bg_x_2 - bt_size - space;
   const int bt_x_minus = bg_x + space;
   const int y_gap      = bg_y - space;
   
   string   field_name     = prefix; 
   string   increment_name = "BT" + prefix + "+";
   string   decrement_name = "BT" + prefix + "-";
   
   string   row_font_style    = "Calibri";
   
   adjust_element.field_name = field_name;
   
   adjust_element.increment.parent = field_name;
   adjust_element.increment.name = increment_name;
   adjust_element.increment.function = "increment";
   
   adjust_element.decrement.parent = field_name;
   adjust_element.decrement.name = decrement_name;
   adjust_element.decrement.function = "decrement";
   
   //TODO
   CEdit(prefix + "BG", bg_x, bg_y, bg_width, bg_height, "", font_size, row_font_style, THEME_FONT_COLOR, THEME_EDIT_COLOR, THEME_EDIT_COLOR, true);
   CEdit(field_name, edit_x, y_gap, edit_width, edit_height, edit_text, font_size, row_font_style, THEME_FONT_COLOR, THEME_EDIT_COLOR, THEME_EDIT_COLOR, false);
   
   CButton(increment_name, bt_x_plus, y_gap, bt_size, bt_size, font_size, row_font_style, "+", THEME_FONT_COLOR, THEME_ROW_BUTTON_BG_COLOR, THEME_ROW_BUTTON_BORDER_COLOR);
   CButton(decrement_name, bt_x_minus, y_gap, bt_size, bt_size, font_size, row_font_style, "-", THEME_FONT_COLOR, THEME_ROW_BUTTON_BG_COLOR, THEME_ROW_BUTTON_BORDER_COLOR);

   // APPEND
   int num_elements = ArraySize(adjust_row);
   ArrayResize(adjust_row, num_elements + 1);
   adjust_row[num_elements] = adjust_element;
}

void CTradeToolApp::DrawMainRow(Toggle &toggle_element, AdjustRow &adjust_element, string row_name, int row, string edit_text, bool state = false, bool show_switch = false, int bg_x = 50){

   const int button_size = 18; 
   const int space = 3;
   const int off_x = bg_x + 130 + 5;
   const int on_x = off_x + button_size - 2;
   
   string edit_name = "EDIT"+row_name;
   string switch_name = row_name+"SWITCH";
   

   
   int BGWIDTH = 130;
   int BGHEIGHT = 25; 
   
   int EDITWIDTH = 80;
   int EDITHEIGHT = 18;
   
   int FONTSIZE = 10;
   
   DrawAdjustRow(adjust_element, edit_name, bg_x, row, BGWIDTH, BGHEIGHT, EDITWIDTH, EDITHEIGHT, button_size, edit_text, FONTSIZE);
   
   if (show_switch) {
   
      UI_Switch(switch_name, off_x, row - space, button_size, button_size, state);
      
      toggle_element.switch_name = switch_name;
      toggle_element.on_name = switch_name+"ON";
      toggle_element.off_name = switch_name+"OFF";
      
      int num_switches = ArraySize(switches);
      ArrayResize(switches, num_switches + 1);
      switches[num_switches] = toggle_element;   
   }
}


void CTradeToolApp::DrawSLRow(double inp = NULL, bool state = NULL){ 

   inp = inp == NULL ? tradetool_main.SL_INPUT : inp;
   state = state == NULL ? tradetool_main.TRADE_SL_ON : state;
   DrawMainRow(sl_toggle, adjust_sl, "SL", APP_ROW_1, (string)inp, state, true);
    
}

void CTradeToolApp::DrawTPRow(double inp = NULL, bool state = NULL){ 

   inp = inp == NULL ? tradetool_main.TP_INPUT : inp;
   state = state == NULL ? tradetool_main.TRADE_TP_ON : state;
   DrawMainRow(tp_toggle, adjust_tp, "TP", APP_ROW_2, (string)inp, state, true); 
   
}

void CTradeToolApp::DrawVolRow(double inp = NULL){

   inp = inp == NULL ? tradetool_main.TRADE_VOLUME : inp; 
   DrawMainRow(vol_toggle, adjust_volume, "VOL", APP_ROW_3, Norm(inp, 2)); 
   
}

void CTradeToolApp::DrawPORow(double inp = NULL){

   inp = inp == NULL ? tradetool_main.TRADE_ENTRY : inp;
   DrawMainRow(pending_toggle, adjust_pending, "PENDING", APP_ROW_3 - 100, (string)inp, false, false, 80);
   
}


void CTradeToolApp::UpdatePrice(string ask, string bid){
   
   const int y_offset = UI_Y - 170;
   const int font_size = 13; 
   
   const int buy_offset = APP_COL_2 + 10;
   const int sell_offset = APP_COL_1 + 10;
   
   // DONT FORGET TO NORMALIZE BID AND ASK
   CTextLabel("BuyPrice", buy_offset, y_offset, ask, font_size, DefFontStyleBold, THEME_FONT_COLOR);
   CTextLabel("SellPrice", sell_offset, y_offset, bid, font_size, DefFontStyleBold, THEME_FONT_COLOR);
   
}


//+-------------------+
// EVENT HANDLING     |
//                    |
//+-------------------+

void CTradeToolApp::EVENT_TRADE(string sparam, CTradeToolMain &tradetool){

   UI_Reset_Object(sparam);
   
   int num_elements = ArraySize(order_buttons);
   
   for (int i = 0; i < num_elements; i++){
   
      Button current_button = order_buttons[i];
      
      if (sparam == current_button.button_name) {
      
         tradetool.SendOrder(current_button.button_order_type);
         break;
         
      }
      // send order
      
   }
}

void CTradeToolApp::EVENT_ADJUST(AdjustButton &adjust){

   string function = adjust.function;
   int multiplier = function == "decrement" ? -1 : 1;
   string parent = adjust.parent;
   string sparam = adjust.name;
   
   if (parent == adjust_sl.field_name){
   
      int step = multiplier * tradetool_main.POINTS_STEP_INPUT;
      tradetool_main.SL_INPUT = Adjust(tradetool_main.SL_INPUT, step, sparam,0);
      DrawSLRow(tradetool_main.SL_INPUT, NULL);
      return;
      
   } 
   
   if (parent == adjust_tp.field_name){
   
      int step = multiplier * tradetool_main.POINTS_STEP_INPUT; 
      tradetool_main.TP_INPUT = Adjust(tradetool_main.TP_INPUT, step, sparam, 0);
      DrawTPRow(tradetool_main.TP_INPUT, NULL);
      return;
      
   }
   
   if (parent == adjust_volume.field_name){
   
      double step = multiplier * tradetool_main.LOT_STEP;
      tradetool_main.TRADE_VOLUME = (float)Adjust(NormLot(tradetool_main.TRADE_VOLUME), step, sparam, tradetool_main.MIN_LOT, tradetool_main.MAX_LOT);
      DrawVolRow(tradetool_main.TRADE_VOLUME);
      return;
      
   }
   
   if (parent == adjust_pending.field_name){
   
      double step = (multiplier * tradetool_main.POINTS_STEP_INPUT) / tradetool_main.CONTRACT; 
      tradetool_main.TRADE_ENTRY = tradetool_main.TRADE_ENTRY == 0.0 ? tradetool_main.util_bid() : tradetool_main.TRADE_ENTRY;
      tradetool_main.TRADE_ENTRY = NormLot(Adjust(tradetool_main.TRADE_ENTRY, step, sparam, 0), 6);
      DrawPORow(tradetool_main.TRADE_ENTRY);
      return;
      
   }
   
}

void CTradeToolApp::EVENT_EDIT(string sparam){

   double val = tradetool_main.util_get_values(sparam);
   
   if (sparam == adjust_sl.field_name){
   
      tradetool_main.SL_INPUT = !MinPoints(val) ? val : 0;
      DrawSLRow();
      return;      
      
   }
   
   if (sparam == adjust_tp.field_name){
   
      tradetool_main.TP_INPUT = !MinPoints(val) ? val : 0;
      DrawTPRow();
      return;
      
   }
   
   if (sparam == adjust_volume.field_name){
   
      tradetool_main.TRADE_VOLUME = !MinLot(val) ? !MaxLot(val) ? (float)val : (float)tradetool_main.MAX_LOT : (float)tradetool_main.MIN_LOT;
      DrawVolRow();
      return;
      
   }
   
   if (sparam == adjust_pending.field_name){
   
      tradetool_main.TRADE_ENTRY = val;
      DrawPORow();
      return;
      
   }
}

void CTradeToolApp::EVENT_TOGGLE(string sparam){

   if (sparam == sl_toggle.on_name || sparam == sl_toggle.off_name) {
   
      tradetool_main.TRADE_SL_ON = !tradetool_main.TRADE_SL_ON;
      DrawSLRow(NULL, tradetool_main.TRADE_SL_ON);
      return;
      
   }
   
   if (sparam == tp_toggle.on_name || sparam == tp_toggle.off_name) {
   
      tradetool_main.TRADE_TP_ON = !tradetool_main.TRADE_TP_ON;
      DrawTPRow(NULL, tradetool_main.TRADE_TP_ON);
      return;
      
   }
   
}


void CTradeToolApp::AddObjectToList(Button &order_button, Button &list[]){

   int num_elements = ArraySize(list);
   
   ArrayResize(list, num_elements + 1);
   list[num_elements] = order_button;
}



//+-------------------+
// OBJECT VALIDATION  |
//                    |
//+-------------------+

bool CTradeToolApp::ObjectIsButton(string name, Button &list[]){

   int num_elements = ArraySize(list);
   
   for (int i = 0; i < num_elements; i ++){
   
      string element_name = list[i].button_name;
      if (name == element_name) return true; 
      
   }
   
   return false;
}

bool CTradeToolApp::ObjectIsRow(string name, AdjustRow &list[]){

   int num_elements = ArraySize(list);
   
   for (int i = 0; i < num_elements; i ++){
   
      AdjustRow row_element = list[i];
      if (name == row_element.field_name) return true;
      if (name == row_element.increment.name) return true;
      if (name == row_element.decrement.name) return true;
      
   }
   
   return false;
}

bool CTradeToolApp::ObjectIsToggle(string name, Toggle &list[]){

   int num_elements = ArraySize(list);
   
   for (int i = 0; i < num_elements; i++){
   
      Toggle toggle_element = list[i];
      if (name == toggle_element.on_name) return true;
      if (name == toggle_element.off_name) return true;
   }
   
   return false;
}


AdjustButton CTradeToolApp::GetAdjustFunction(string name){

   int num_elements = ArraySize(adjust_row);
   
   for (int i = 0; i < num_elements ;i++){
      AdjustRow row_element = adjust_row[i];
      if (name == row_element.increment.name) return row_element.increment;
      if (name == row_element.decrement.name) return row_element.decrement;
   }
   AdjustButton dummy;
   return dummy;
   
}



string CTradeToolApp::Norm(double val, int digits = NULL){

   int num_digits = digits == NULL ? tradetool_main.DIGITS : digits; 
   
   return DoubleToString(val, num_digits);
}



bool CTradeToolApp::MinLot(double lot){
   if (lot > tradetool_main.MIN_LOT) return false;
   return true;
}

bool CTradeToolApp::MaxLot(double lot){
   if (lot < tradetool_main.MAX_LOT) return false;
   return true;
}



double CTradeToolApp::Adjust(double inp, double step, string sparam, double lower_limit = -1, double upper_limit = -1){

   double val = inp + step;
   UI_Reset_Object(sparam);
   if (lower_limit == -1 && upper_limit == -1) return val; 
   if (step < 0 && lower_limit >= 0 && inp <= lower_limit) return inp; // return if minus, and already at limit
   if (step > 0 && upper_limit >= 0 && inp >= upper_limit) return inp; 
   return val; 

}

double CTradeToolApp::NormLot(double lot, int digits = 2) { return NormalizeDouble(lot, digits); }

bool CTradeToolApp::MinPoints(double points){
   if (points > 0) return false;
   return true;
}