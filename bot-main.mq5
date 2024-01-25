//+------------------------------------------------------------------+
//|                                                    MATwister.mq5 |
//|                             Copyright 2024, Tradity Capital Ltd. |
//|                                   https://www.traditycapital.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Tradity Capital Ltd."
#property link      "https://www.traditycapital.com"
#property version   "1.00"
#include<Trade\Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert inputs                                                    |
//+------------------------------------------------------------------+
input int period_MA1 = 13;
input int period_MA2 = 21;
input int period_MA3 = 50;
input ENUM_MA_METHOD MA_all_Method = MODE_SMA;
input ENUM_APPLIED_PRICE PRICE_USED_WITH_MA = PRICE_OPEN;

input int number_of_trades_per_signal = 1;

input int ATR_Period_lots = 16;
input double Risk_Percent = 0.01;
input double account_exposure = 0.4;//RISK EXPOSURE
input double ATR_Multiplier_lots = 1.5;


//+------------------------------------------------------------------+
//| Expert Variable declarations                                   |
//+------------------------------------------------------------------+
string asset = _Symbol;
bool tradesPlacedForCurrentSignal = false; // Flag to check if trades have been placed for the current signal
double Lot_Size_atr_value;
double stoploss;
double risk_amount;
double Account_balance;
double tick_value;
double risk_perc;
double lotsize_atr_result;
int ticketnumber;
int i;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   datetime time = iTime(asset, PERIOD_CURRENT,0), Local_time = TimeCurrent();
   MqlDateTime localT;
   TimeToStruct(Local_time, localT);
   int sec = localT.sec, min = localT.min, hour = localT.hour, day = localT.day_of_week;


//---MAs
   double MA1Array[],MA2Array[],MA3Array[];
   double MA1 = iMA(asset,_Period,period_MA1,0,MA_all_Method,PRICE_USED_WITH_MA),
          MA2 = iMA(asset,_Period,period_MA2,0,MA_all_Method,PRICE_USED_WITH_MA),
          MA3 = iMA(asset,_Period,period_MA3,0,MA_all_Method,PRICE_USED_WITH_MA);

   ArraySetAsSeries(MA1Array,true);
   ArraySetAsSeries(MA2Array,true);
   ArraySetAsSeries(MA3Array,true);

   CopyBuffer(MA1,0,0,3,MA1Array);
   CopyBuffer(MA2,0,0,3,MA2Array);
   CopyBuffer(MA3,0,0,3,MA2Array);

//---Lot size logic
   Lot_Size_atr_value = iATR(asset,PERIOD_CURRENT,ATR_Period_lots);

   tick_value = SymbolInfoDouble(asset, SYMBOL_TRADE_TICK_VALUE);
   risk_perc = Risk_Percent * 100;
   Account_balance = account_exposure * AccountInfoDouble(ACCOUNT_BALANCE);
   risk_amount = Account_balance * Risk_Percent;
   double points = SymbolInfoDouble(asset,SYMBOL_POINT);
   double Smallest_Lot = NormalizeDouble(SymbolInfoDouble(asset, SYMBOL_VOLUME_MIN),2);
   double Largest_Lot = NormalizeDouble(SymbolInfoDouble(asset, SYMBOL_VOLUME_MAX),2);

   double iATR_value[];
   ArraySetAsSeries(iATR_value,true);
   CopyBuffer(Lot_Size_atr_value,0,0,3,iATR_value);

   stoploss = ATR_Multiplier_lots * iATR_value[1]/points;

   lotsize_atr_result = NormalizeDouble(risk_amount/(stoploss*tick_value),2);

   if(lotsize_atr_result < Smallest_Lot)
     {
      lotsize_atr_result = Smallest_Lot;
     }

   if(lotsize_atr_result > Largest_Lot)
     {
      lotsize_atr_result = Largest_Lot;
     }



//---Execution logic

   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);

   if(((MA1Array[1] && MA2Array[1]) > MA3Array[1] && (MA1Array[0] && MA2Array[0]) < MA3Array[0]) ||
      ((MA1Array[1] && MA2Array[1]) < MA3Array[1] && (MA1Array[0] && MA2Array[0]) > MA3Array[0]))
     {
      tradesPlacedForCurrentSignal = false;
     }


   if(!tradesPlacedForCurrentSignal /*&& today_profit <= daily_target && today_profit >= daily_allowable_DD && localT.hour>Launch_Time && localT.hour<end_of_trading*/)
     {
      if(min < 1 && sec < 1)
        {

         if(OrderExists() == false /*&& difference <= max_diff*/)
           {
            if((MA1Array[1] && MA2Array[1]) > MA3Array[1] && (MA1Array[0] && MA2Array[0]) < MA3Array[0])
              {

               for(i = 0; i<=number_of_trades_per_signal; i++)
                 {

                  ticketnumber = trade.Buy(lotsize_atr_result, NULL, Ask,0,0,"FX_SG_MATwister-> BUY");
                 }
               tradesPlacedForCurrentSignal = true; //flag set to true after placing trades
              }

            if((MA1Array[1] && MA2Array[1]) < MA3Array[1] && (MA1Array[0] && MA2Array[0]) > MA3Array[0])
              {

               for(i = 0; i<=number_of_trades_per_signal; i++)
                 {
                  ticketnumber = trade.Sell(lotsize_atr_result, NULL, Bid,0,0,"FX_SG_MATwister-> SELL");
                 }
               tradesPlacedForCurrentSignal = true; //flag set to true after placing trades
              }

           }
        }

     }
  }
// Define the function to check if there is an existing order
bool OrderExists()
  {
// Loop through all the orders

   for(int i=0; i<PositionsTotal(); i++)
     {
      ulong ticket=PositionGetTicket(i);
      // Get the order information
      if(ticket>0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {

         // An existing order has been found
         return true;
        }
     }


// No existing order of the specified type has been found
   return false;
  }
//+------------------------------------------------------------------+
