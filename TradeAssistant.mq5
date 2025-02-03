//+------------------------------------------------------------------+
//|                                                TradeAssistant.mq5|
//|                                Copyright 2025, Malinda Rasingolla|
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include <Controls/Button.mqh>
#include "Functions.mqh"

input double RiskPercentage = 1.0;
input int MaxOpenTrades = 1;

int OldNumBars = 0;
bool buttonState = false;

CButton buttonTrade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   DrawButton();
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   buttonTrade.Destroy();
   Comment("");
  }

//+------------------------------------------------------------------+
//| Handle Button Click                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == "TradeButton")
     {
      string buttonText = ObjectGetString(0, "TradeButton", OBJPROP_TEXT);
      if(buttonText == "Disabled")
        {
         ObjectSetString(0, "TradeButton", OBJPROP_TEXT, "Enabled");
         buttonState = true;
        }
      else
        {
         ObjectSetString(0, "TradeButton", OBJPROP_TEXT, "Disabled");
         buttonState = false;
        }
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Function to draw the button                                      |
//+------------------------------------------------------------------+
void DrawButton()
  {
// Define button parameters
   string buttonName = "TradeButton";
   int xPos = 100;
   int yPos = 50;
   int width = 80;
   int height = 30;

// Create the button using CButton class
   buttonTrade.Create(0, buttonName, 0, xPos, yPos, width, height);

// Set button properties using ObjectSetInteger and ObjectSetString
   ObjectSetInteger(0, buttonName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, yPos);
   ObjectSetInteger(0, buttonName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, buttonName, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, buttonName, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, buttonName, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   ObjectSetString(0, buttonName, OBJPROP_TEXT, "Disabled");

// Set button event handler
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double takeProfit = NormalizeDouble(ObjectGetDouble(0, "tp", OBJPROP_PRICE), _Digits);
   double stopLoss = NormalizeDouble(ObjectGetDouble(0, "sl", OBJPROP_PRICE), _Digits);
   
   string comment = "";
   comment = "✖ ️";
   if(takeProfit>0 || stopLoss>0)
      if(buttonState == true)
         comment = "✔️ ";
      
   if(NumOfTrades() > 0)
     {
      comment += " | Open positions : " + IntegerToString(NumOfTrades(),0,0);
      comment +=  " | " + "Balance : " + calculateProfitLoss() + "\n" + CalculateRiskToReward();
     }
   Comment(comment);

   if(!NewBarPresent(OldNumBars))
      return;
   OldNumBars = Bars(_Symbol, _Period);

   if(!buttonState)
      return;

   

   if(stopLoss > takeProfit)
      Sell(takeProfit, stopLoss, RiskPercentage, MaxOpenTrades);

   if(stopLoss < takeProfit)
      Buy(takeProfit, stopLoss, RiskPercentage, MaxOpenTrades);
  }
//+------------------------------------------------------------------+
