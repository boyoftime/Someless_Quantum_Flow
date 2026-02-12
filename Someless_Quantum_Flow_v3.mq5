//+------------------------------------------------------------------+
//|                                        Someless_Quantum_Flow.mq5 |
//|                                     Copyright 2026, Someless Dev |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Someless Dev"
#property link      "https://www.mql5.com"
#property version   "3.0"
#property description "RSI Reversal Indicator with Labels"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- Plot Buy (Up Arrow)
#property indicator_label1  "Quantum Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- Plot Sell (Down Arrow)
#property indicator_label2  "Quantum Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- INPUTS
input int      RSIPeriod   = 14;    // Signal Period
input double   OverSold    = 30.0;  // Buy Zone
input double   OverBought  = 70.0;  // Sell Zone

//--- Buffers
double BuyBuffer[];
double SellBuffer[];

//--- Indicator Handle
int rsiHandle;

//--- Branding Object Names
string labelName = "SomelessBrandingLabel";
string signalPrefix = "SQF_Label_"; // Prefix for our text objects

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. Map buffers
   SetIndexBuffer(0, BuyBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SellBuffer, INDICATOR_DATA);

   // 2. Set Arrow Codes
   PlotIndexSetInteger(0, PLOT_ARROW, 233); // Up Arrow
   PlotIndexSetInteger(1, PLOT_ARROW, 234); // Down Arrow
   
   // 3. Initialize empty values
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

   // 4. Create RSI Handle
   rsiHandle = iRSI(_Symbol, _Period, RSIPeriod, PRICE_CLOSE);
   if(rsiHandle == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle");
      return(INIT_FAILED);
     }

   // 5. Create the Branding Label
   CreateBranding();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Remove the branding text
   ObjectDelete(0, labelName);
   // Remove all Buy/Sell text labels created by this indicator
   ObjectsDeleteAll(0, signalPrefix);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   // Check branding
   if(ObjectFind(0, labelName) < 0) CreateBranding();

   // Set Series
   ArraySetAsSeries(BuyBuffer, true);
   ArraySetAsSeries(SellBuffer, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(time, true); // Important for object creation
   
   double rsiValues[];
   ArraySetAsSeries(rsiValues, true);

   // Calculate limit
   int limit = rates_total - prev_calculated;
   if(limit > 1) limit = rates_total - 2;
   if(prev_calculated > 0) limit++;

   // Copy Data
   int copied = CopyBuffer(rsiHandle, 0, 0, limit + 2, rsiValues);
   if(copied <= 0) return(0);

   // Main Loop
   for(int i = limit; i >= 0; i--)
     {
      BuyBuffer[i] = 0.0;
      SellBuffer[i] = 0.0;
      
      if(i >= rates_total - 1) continue;

      double range = high[i] - low[i];
      if(range == 0) range = 1.0 * _Point; // Prevent zero math

      // --- SELL LOGIC ---
      if(rsiValues[i] < OverBought && rsiValues[i+1] >= OverBought)
        {
         // 1. Draw Arrow
         double arrowPrice = high[i] + range * 0.3;
         SellBuffer[i] = arrowPrice;
         
         // 2. Draw Text Label
         CreateSignalLabel(time[i], arrowPrice + (range * 0.4), "SELL", clrRed, true);
        }

      // --- BUY LOGIC ---
      if(rsiValues[i] > OverSold && rsiValues[i+1] <= OverSold)
        {
         // 1. Draw Arrow
         double arrowPrice = low[i] - range * 0.3;
         BuyBuffer[i] = arrowPrice;
         
         // 2. Draw Text Label
         CreateSignalLabel(time[i], arrowPrice - (range * 0.4), "BUY", clrLime, false);
        }
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Helper: Create "BUY" or "SELL" text objects                      |
//+------------------------------------------------------------------+
void CreateSignalLabel(datetime time, double price, string text, color clr, bool isSell)
{
   string name = signalPrefix + (string)time + text; // Unique name based on time
   
   // Only create if it doesn't exist yet
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Verdana Bold");
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      
      // Alignments
      if(isSell)
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LOWER); // Text sits on top of point
      else
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER); // Text hangs below point
         
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//| Helper: Create the Developer Watermark                           |
//+------------------------------------------------------------------+
void CreateBranding()
{
   ObjectDelete(0, labelName);
   if(ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetString(0, labelName, OBJPROP_TEXT, "✨ Someless Quantum Flow | Dev: Someless");
      ObjectSetString(0, labelName, OBJPROP_FONT, "Verdana Bold");
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrForestGreen);
      
      // Top Left Corner
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 20); 
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 30); 
      
      ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
      ChartRedraw(0);
   }

}
