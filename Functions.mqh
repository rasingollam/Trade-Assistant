#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh> // Include necessary libraries
#include <ChartObjects/ChartObjectsTxtControls.mqh>

CTrade Trade;
CPositionInfo PositionInfo;

//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
void Buy(double takeProfit, double stopLoss, double localRiskPercentage, int maximumTrades)
{
  if (!BuySignal(maximumTrades))
    return;

  double MaxDrawdown = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * localRiskPercentage / 100), 2);
  double ASK = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
  double LotSize = CalculatePositionSize(MaxDrawdown, stopLoss);

  if (!Trade.Buy(LotSize, NULL, ASK, stopLoss, takeProfit, "TradeAssistant_Buy"))
    Print("Failed TA Buy : ", GetLastError());
}

//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
void Sell(double takeProfit, double stopLoss, double localRiskPercentage, int maximumTrades)
{
  if (!SellSignal(maximumTrades))
    return;

  double MaxDrawdown = NormalizeDouble((AccountInfoDouble(ACCOUNT_BALANCE) * localRiskPercentage / 100), 2);
  double BID = SymbolInfoDouble(Symbol(), SYMBOL_BID);
  double LotSize = CalculatePositionSize(MaxDrawdown, stopLoss);

  if (!Trade.Sell(LotSize, NULL, BID, stopLoss, takeProfit, "TradeAssistant_Sell"))
    Print("Failed TA Sell : ", GetLastError());
}

//+------------------------------------------------------------------+
//| Check if a new bar is present                                    |
//+------------------------------------------------------------------+
bool NewBarPresent(int &OldNumBar)
{
  int bars = Bars(_Symbol, _Period);
  if (OldNumBar != bars)
  {
    OldNumBar = bars;
    return true;
  }
  return false;
}

//+------------------------------------------------------------------+
//| Calculate the position size                                      |
//+------------------------------------------------------------------+
double CalculatePositionSize(double MaxDrawdown, double stopLoss)
{
  double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
  double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
  double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
  double stopLossPoints = MathAbs(stopLoss - SymbolInfoDouble(Symbol(), SYMBOL_ASK));

  if (tickSize == 0 || tickValue == 0 || lotStep == 0)
    return 0;

  double moneyLotStep = (stopLossPoints / tickSize) * tickValue * lotStep;
  if (moneyLotStep == 0)
    return 0;

  double lots = MathFloor(MaxDrawdown / moneyLotStep) * lotStep;
  if (_Symbol == "XAUUSD")
    lots = MathFloor(MaxDrawdown / (moneyLotStep * 100)) * lotStep;

  return lots;
}

//+------------------------------------------------------------------+
//| Calculate Position Risk to Reward                                |
//+------------------------------------------------------------------+
string CalculateRiskToReward()
{
  int totalPositions = PositionsTotal();
  double profitLoss = 0;
  double riskToReward = 0;
  int positionCount = 0;

  for (int i = totalPositions - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket))
    {
      if (PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
        double positionPoints = 0;
        double positionTpPoints = 0;
        double slPoints = MathAbs(PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN));
        double tpPoints = MathAbs(PositionGetDouble(POSITION_TP) - PositionGetDouble(POSITION_PRICE_OPEN));

        if (PositionInfo.PositionType() == POSITION_TYPE_BUY)
          positionPoints = PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN);
        positionTpPoints = MathAbs(PositionGetDouble(POSITION_TP) - PositionGetDouble(POSITION_PRICE_OPEN));
        if (PositionInfo.PositionType() == POSITION_TYPE_SELL)
          positionPoints = PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT);
        positionTpPoints = MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_TP));

        profitLoss += (positionPoints / slPoints);
        riskToReward += (positionTpPoints / slPoints);
        positionCount++;
      }
    }
  }
  return DoubleToString(profitLoss / positionCount, 2) + "  R ( " + DoubleToString(riskToReward / positionCount, 2) + " )";
}

//+------------------------------------------------------------------+
//| Calculate Position Profit                                        |
//+------------------------------------------------------------------+
string calculateProfitLoss()
{
  int totalPositions = PositionsTotal();
  double profitLoss = 0;
  for (int i = totalPositions - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket))
    {
      if (PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
        profitLoss += PositionGetDouble(POSITION_PROFIT);
      }
    }
  }
  return DoubleToString(NormalizeDouble(profitLoss, 2), 2);
}

//+------------------------------------------------------------------+
//| Number of Trades                                                 |
//+------------------------------------------------------------------+
int NumOfTrades()
{
  int Num = 0;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    if (!PositionInfo.SelectByIndex(i))
      continue;
    if (PositionInfo.Symbol() != _Symbol)
      continue;
    Num++;
  }
  return Num;
}

//+------------------------------------------------------------------+
//| Buy Signal                                                       |
//+------------------------------------------------------------------+
bool BuySignal(int maximumTrades)
{
  int numOfTrades = NumOfTrades();

  // Check if there are no trades and the last candle is bearish
  if (numOfTrades == 0)
  {
    double openPrice = iOpen(_Symbol, _Period, 1);
    double closePrice = iClose(_Symbol, _Period, 1);
    if (closePrice < openPrice)
    {
      return true;
    }
  }

  // Check if the number of trades is between 0 and maximumTrades
  if (numOfTrades > 0 && numOfTrades < maximumTrades)
  {
    double lowestEntryPrice = GetLowestEntryPrice();

    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    if (currentPrice < lowestEntryPrice)
    {
      return true;
    }
  }

  return false;
}

//+------------------------------------------------------------------+
//| Get Lowest Entry Price                                           |
//+------------------------------------------------------------------+
double GetLowestEntryPrice()
{
  double lowestEntryPrice = DBL_MAX;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    if (!PositionInfo.SelectByTicket(PositionGetTicket(i)))
      continue;
    if (PositionInfo.Symbol() != _Symbol)
      continue;
    if (PositionInfo.PositionType() != POSITION_TYPE_BUY)
      continue;

    double entryPrice = PositionInfo.PriceOpen();
    if (entryPrice < lowestEntryPrice)
    {
      lowestEntryPrice = entryPrice;
    }
  }
  return lowestEntryPrice;
}

//+------------------------------------------------------------------+
//| Sell Signal                                                      |
//+------------------------------------------------------------------+
bool SellSignal(int maximumTrades)
{
  int numOfTrades = NumOfTrades();

  // Check if there are no trades and the last candle is bullish
  if (numOfTrades == 0)
  {
    double openPrice = iOpen(_Symbol, _Period, 1);
    double closePrice = iClose(_Symbol, _Period, 1);
    if (closePrice > openPrice)
    {
      return true;
    }
  }

  // Check if there are trades and the current price is above the highest entry price
  if (numOfTrades > 0 && numOfTrades <= maximumTrades)
  {
    double highestEntryPrice = GetHighestEntryPrice();

    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if (currentPrice > highestEntryPrice)
    {
      return true;
    }
  }

  return false;
}

//+------------------------------------------------------------------+
//| Get Highest Entry Price                                          |
//+------------------------------------------------------------------+
double GetHighestEntryPrice()
{
  double highestEntryPrice = 0;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    if (!PositionInfo.SelectByTicket(PositionGetTicket(i)))
      continue;
    if (PositionInfo.Symbol() != _Symbol)
      continue;
    if (PositionInfo.PositionType() != POSITION_TYPE_SELL)
      continue;

    double entryPrice = PositionInfo.PriceOpen();
    if (entryPrice > highestEntryPrice)
    {
      highestEntryPrice = entryPrice;
    }
  }
  return highestEntryPrice;
}
