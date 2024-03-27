

#define app_font           "Segoe UI Semibold"
#define app_font_bold      "Segoe UI Bold"
#define app_def_y          315
#define app_def_x          5
#define app_corner         CORNER_LEFT_LOWER
#define app_line_style        STYLE_SOLID
#define app_border_type       BORDER_FLAT
#define app_main_border_type  BORDER_RAISED
#define app_line_width        1





input int      InpMagic       = 232323; //Magic Number
input double   InpDefLots     = 0.01; //Volume
input int      InpDefStop     = 200; //Default SL (Points)
input int      InpDefTP       = 200; //Default TP (Points)
input int      InpPointsStep  = 100; //Step (Points)
bool     InpRunTests    = false; // Run Unit Tests


color    DEF_FONT_COLOR       = clrWhite;
color    BUTTON_BORD_COLOR    = clrGray; 
color    BUY_COLOR            = clrDodgerBlue;
color    SELL_COLOR           = clrCrimson;

color    ROW_BUTTON_BG        = clrDimGray;
color    ROW_BUTTON_BORD      = clrDarkGray;
color    EDIT_COLOR           = clrGray;

string   UI_FONT              = "Segoe UI Semibold";
string   UI_FONT_BOLD         = "Segoe UI Bold";

int      FONT_SIZE            = 10;


int      UI_X                 = 5;
int      UI_Y                 = 315;
int      UI_WIDTH             = 235;
int      UI_HEIGHT            = 300;