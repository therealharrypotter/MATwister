//+------------------------------------------------------------------+
//|                                                    MATwister.mq5 |
//|                             Copyright 2024, Tradity Capital Ltd. |
//|                                   https://www.traditycapital.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Tradity Capital Ltd."
#property link      "https://www.traditycapital.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
string asset = Symbol();
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Time
datetime time = iTime(asset, PERIOD_CURRENT,0);
datetime Local_time = TimeCurrent();
MqlDateTime localT;
TimeToStruct(Local_time, localT);
int min = localT.min;
int hour = localT.hour;
int day = localT.day_of_week;

//---MAs


//---Execution logic
   
  }
//+------------------------------------------------------------------+
