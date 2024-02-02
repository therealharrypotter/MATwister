//+------------------------------------------------------------------+
//|                                                   FX_SG_Bell.mq5 |
//|                                 Copyright 2023, Stephen Gachanja |
//|                                    https://www.traditycapital.com|
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Tradity Capital Ltd."
#property link      "https://www.traditycapital.com"
#property version   "4.00"

#include<Trade\Trade.mqh>
CTrade trade;

input string balances_parameters = "== STARTING BALANCES ==";
input double balance = 6000;//INITIAL STARTING BALANCE

input string ma_parameters = "== ENTRY PARAMETERS ==";
input int ATR_Period_slow_MA= 21;//PERIOD USED FOR SLOW MA CALCULATION
input int ATR_Period_large_MA= 50;
input ENUM_MA_METHOD MA_Method_for_slow_MA = MODE_SMA;//METHOD USED FOR SLOW MA CALCULATION
input int ATR_Period_fast_MA= 13;//PERIOD USED FOR FAST MA CALCULATION
input ENUM_MA_METHOD MA_Method_for_fast_MA = MODE_SMA;//METHOD USED FOR FAST MA CALCULATION
input ENUM_APPLIED_PRICE PRICE_USED_WITH_MA = PRICE_OPEN;//PRICE USED FOR FAST MA CALCULATION
input int number_of_trades_per_signal = 1;//NUMBER OF TRADES PER SIGNAL
input double max_diff = 400;//MAX POINTS TO ALLOW TRADING
input int volume_limit = 3000;//VOLUME LIMIT
input int min_distance_from_MA = 0;//MIN DISTANCE FROM MA FOR ENTRIES
input int max_distance_from_MA = 3000;//MAX DISTANCE FROM MA FOR ENTRIES

input string timefunction_parameters = "== TIME FUNCTION PARAMETERS ==";
input int number_of_minutes = 0;//NUMBER OF MINUTES FOR EXECUTION PER SIGNAL
input int last_day_of_trading = 5;//LAST DAY OF TRADING(FRIDAY-> 5)
input int Launch_Time = 3;//START OF TRADING DAILY
input int end_of_trading = 7;//END OF TRADING DAILY

input string risk_parameters = "== RISK PARAMETERS ==";
input double RiskRewardRatio = 0.1;//RISK:REWARD RATIO(RRR)
input int ATR_Period_lots = 16;//ATR PERIOD USED TO CALCULATE LOT SIZE & SL
input int maxslippage = 35;//MAXIMUM ALLOWED SLIPPAGE/SPREAD
input double Risk_Percent = 0.01;//RISK IN DECIMAL FORM FOR TP & SL LOT SIZE CALCULATION
input double account_exposure = 0.4;//RISK EXPOSURE
input double ATR_Multiplier_lots = 1.5;//ATR MULTIPLIER IS INVERSELY RELATED TO THE LOT SIZE CALCULATION

input string prop_account_rules = "== PROP ACCOUNT RULES ==";
input double my_target = 10;//MY OVERALL TARGET(%)
input double my_daily_target = 0.5;//MY DAILY TARGET (%)
input double total_drawdown = 6;//MAX TOTAL DRAWDOWN(%)
input double daily_allowable_drawdown = 1;//DAILY ALLOWABLE DRAWDOWN(%)
input double daily_drawdown = 3;//MAX DAILY DRAWDOWN(%)
input int trading_commission = 13;//ACCOUNT COMMISSION PER LOT($)
input double commission_exit_multiplier = 1.01;//COMMISSION FILTER(MULTIPLIER)

input string closetrades = "== CLOSE TRADES/DD MANAGER ==";
input bool Close_Trades_Based_on_Profit = true;//ACTIVATE CLOSURE OF TRADES BASED ON PROFIT
input bool Close_the_Trades_Based_on_Time = true;//ACTIVATE CLOSURE OF TRADES BASED ON TIME
input int time_to_close = 20;//TIME TO CLOSE TRADES

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double lotsize_atr_result;
double Lot_Size_atr;
double ResetTP;
double NormalSL;
double stoploss;
double risk_amount;
double Account_balance;
int tradecount = 0;
string instruments = Symbol();
ENUM_ORDER_TYPE OrderType1 = ORDER_TYPE_BUY;
ENUM_ORDER_TYPE OrderType2 = ORDER_TYPE_SELL;
//double profit;
double  Daily_max_DD;
double Total_max_DD;
double curr_DD;
double Total_balance;
double startingBalanceToday;
double previousDayBalance;
double daily_allowable_DD;
//bool tradesPlacedForCurrentSignal = false; // Flag to check if trades have been placed for the current signal
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Initialize starting balance for the day when the EA is loaded
   startingBalanceToday = AccountInfoDouble(ACCOUNT_BALANCE);
   previousDayBalance = startingBalanceToday; // Backup to compare if a new day starts
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   datetime time = iTime(_Symbol, PERIOD_CURRENT,0);
   int i;
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
   double points = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double Smallest_Lot = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),2);
   double Largest_Lot = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX),2);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double risk_perc = Risk_Percent * 100;
   Account_balance = account_exposure * AccountInfoDouble(ACCOUNT_BALANCE);
   risk_amount = Account_balance * Risk_Percent;
   Total_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   Daily_max_DD = NormalizeDouble(((daily_drawdown/100)*balance),2);
   Total_max_DD = NormalizeDouble(((total_drawdown/100)*balance),2);
   daily_allowable_DD = NormalizeDouble((-1*(daily_allowable_drawdown/100)*balance),2);
   curr_DD = NormalizeDouble(((AccountInfoDouble(ACCOUNT_BALANCE) - balance)/balance)*100,2);
   double prev_balance;
   double today_profit;
   double daily_target;
   datetime Local_time = TimeCurrent();
   static datetime lastExecutionTime = 0;
   MqlDateTime localT;
   TimeToStruct(Local_time,localT);
   int current_min = localT.min;
   int current_hour = localT.hour;
   int current_day = localT.day_of_week;
   int ticketnumber;
/////Calculate daily target
   if(localT.hour ==1)
     {
      // A new trading day has started
      previousDayBalance = startingBalanceToday;
      startingBalanceToday = Total_balance;

     }
   today_profit = NormalizeDouble((Total_balance - startingBalanceToday),2);
   daily_target = NormalizeDouble(((my_daily_target/100)*balance),2);
/////Calculate SL and TP from atr for volume calculation
   Lot_Size_atr = iATR(_Symbol,PERIOD_CURRENT,ATR_Period_lots);

   double iATR_value[];
   ArraySetAsSeries(iATR_value,true);
   CopyBuffer(Lot_Size_atr,0,0,3,iATR_value);

   stoploss = ATR_Multiplier_lots * iATR_value[1]/points;
   ResetTP = stoploss * RiskRewardRatio;
   NormalSL = stoploss;

   lotsize_atr_result = NormalizeDouble(risk_amount/(stoploss*tick_value),2);

   if(lotsize_atr_result < Smallest_Lot)
     {
      lotsize_atr_result = Smallest_Lot;
     }

   if(lotsize_atr_result > Largest_Lot)
     {
      lotsize_atr_result = Largest_Lot;
     }

/////Creating the arrays for the cross MAs
   double myMovingAverageArrayslow[], myMovingAverageArrayfast[],myMovingAverageArraylarge[];

/////Collect MA values for crosses
   double MA1 = iMA(_Symbol,_Period,ATR_Period_slow_MA,0,MA_Method_for_slow_MA,PRICE_OPEN);
   double MA2 = iMA(_Symbol,_Period,ATR_Period_fast_MA,0,MA_Method_for_fast_MA,PRICE_OPEN);
   double MA3 = iMA(_Symbol,_Period,ATR_Period_large_MA,0,MA_Method_for_fast_MA,PRICE_OPEN);

/////Sort the MA price array of slow MA from the current candle downwards
   ArraySetAsSeries(myMovingAverageArrayslow,true);

/////Sort the price array of the fast MA from the current candle downwards
   ArraySetAsSeries(myMovingAverageArrayfast,true);
   ArraySetAsSeries(myMovingAverageArraylarge,true);
/////Defined MA1, one line, current candle, 3 candles, store result
   CopyBuffer(MA1,0,0,3,myMovingAverageArrayslow);

/////Defined MA2, one line, current candle, 3 candles, store result
   CopyBuffer(MA2,0,0,3,myMovingAverageArrayfast);
   CopyBuffer(MA3,0,0,3,myMovingAverageArraylarge);
/////Creating the arrays for the differences calculation
   double diffMAopen[],diffMAclose[];

/////Collect the MA values
   double MAopen = iMA(_Symbol,_Period,1,0,MODE_SMA,PRICE_OPEN);
   double MAclose = iMA(_Symbol,_Period,1,0,MODE_SMA,PRICE_CLOSE);

////Sort the MA price array of diffOpen MA from the current candle downwards
   ArraySetAsSeries(diffMAopen,true);

/////Sort the price array of the diffClose MA from the current candle downwards
   ArraySetAsSeries(diffMAclose,true);

/////Defined Open_MA, one line, current candle, 3 candles, store result
   CopyBuffer(MAopen,0,0,3,diffMAopen);

/////Defined Close_MA, one line, current candle, 3 candles, store result
   CopyBuffer(MAclose,0,0,3,diffMAclose);

/////Pip Difference
   double MAdiff = diffMAopen[1]-diffMAclose[1];
   double difference = NormalizeDouble((MathAbs(MAdiff)/_Point),1);
   bool isabovemin_diff = difference > min_distance_from_MA;
   bool isbelowmax_diff = difference < max_distance_from_MA;


   if(localT.day_of_week<= last_day_of_trading)
      //Output
      Comment("Target: ",my_target, "%",
              "\nDaily Max. DD: $", Daily_max_DD, " Vs Today's Max. Allowable DD: $",daily_allowable_DD,
              "\nTotal Max DD: $",Total_max_DD,
              "\nTotal Current DD: ",curr_DD, "% Vs Target: ",my_target,"%",
              "\nToday's PnL $: ",today_profit," Vs Today's Target: $",daily_target);
     {

      // Reset the flag if a new signal is detected
      /*if((MA1 > MA2 > MA3) ||
         (MA1 < MA2 < MA3))
        {
         tradesPlacedForCurrentSignal = false;
        }*/
      lastExecutionTime = Local_time;
      if(/*!tradesPlacedForCurrentSignal && */today_profit <= daily_target && today_profit >= daily_allowable_DD && localT.hour>Launch_Time && localT.hour<end_of_trading)
        {
         if(localT.min == 0 || localT.min == 5 || localT.min == 10 || localT.min == 15 || localT.min == 20 || localT.min == 25 || localT.min == 30 || localT.min == 35 || localT.min == 40 || localT.min == 45|| localT.min == 50 || localT.min == 55 )
           {

            if(OrderExists() == false && difference <= max_diff)
              {
               if(MA1 > MA2 > MA3)
                 {

                  for(i = 0; i<number_of_trades_per_signal; i++)
                    {

                     ticketnumber = trade.Buy(lotsize_atr_result, NULL, Ask,0,0,"FX_SG_BELL-> BUY");
                    }
                  //tradesPlacedForCurrentSignal = true; //flag set to true after placing trades
                 }

               if(MA1 < MA2 < MA3)
                 {

                  for(i = 0; i<number_of_trades_per_signal; i++)
                    {
                     ticketnumber = trade.Sell(lotsize_atr_result, NULL, Bid,0,0,"FX_SG_BELL-> SELL");
                    }
                  //tradesPlacedForCurrentSignal = true; //flag set to true after placing trades
                 }

              }
           }
        }
     }
   if(Close_Trades_Based_on_Profit)
     {
      CloseTradesOnProfit();
     }


  }
//+------------------------------------------------------------------+
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
//|                                                                  |
//+------------------------------------------------------------------+
void Close_trades()
  {

   if(PositionsTotal()>0)
     {

      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              {

               bool success = trade.PositionClose(ticket,"Order Closed");
               if(success)
                 {
                  Print("Order closed. Ticket---> ",ticket);
                 }
               else
                 {
                  Print("Order close unsuccessful due to error!!!---> ", GetLastError());
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Close trades if profit is more than commission                   |
//+------------------------------------------------------------------+
void CloseTradesOnProfit()
  {
   double commissionPerLot = trading_commission; // USD per lot

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            double positionSize = PositionGetDouble(POSITION_VOLUME);
            double commission = positionSize * commissionPerLot * commission_exit_multiplier;
            double profit = PositionGetDouble(POSITION_PROFIT);

            if(profit > commission)
              {
               bool success = trade.PositionClose(ticket, "Profit exceeds commission");
               if(success)
                 {
                  Print("Order closed: Profit exceeds commission. Ticket---> ",ticket);
                 }
               else
                 {
                  Print("Failed to close order ", ticket, ". Error: ", GetLastError());
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
