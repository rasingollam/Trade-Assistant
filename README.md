# Trade Assistant

A MetaTrader 5 Expert Advisor that assists in semi-automated trading with risk management features.

## Features

- Semi-automated trading with manual entry points
- Risk-based position sizing
- Multiple trade management with maximum trade limit
- Real-time profit/loss tracking
- Risk-to-Reward ratio calculation
- User-friendly interface with enable/disable button
- Support for both Buy and Sell positions

## Installation

1. Copy the following files to your MetaTrader 5 Experts folder:
   - `TradeAssistant.mq5`
   - `Functions.mqh`

2. Compile the Expert Advisor in MetaTrader 5
3. Attach the EA to your desired chart

## Configuration

### Input Parameters

- `RiskPercentage` (default: 1.0): Maximum risk per trade as a percentage of account balance
- `MaxOpenTrades` (default: 1): Maximum number of simultaneous open trades allowed

## Usage

1. Draw take profit (tp) and stop loss (sl) lines on the chart
2. Click the "Enable" button in the top right corner to activate the EA
3. The EA will automatically:
   - Calculate position size based on risk percentage
   - Enter trades when conditions are met
   - Track profit/loss and risk-to-reward ratios
   - Manage multiple trades within the specified limit

### Trading Logic

- Buy Signal: Triggers when:
  - No open trades and the last candle is bearish
  - Current price is lower than the lowest entry price (for scaling in)
  
- Sell Signal: Triggers when:
  - No open trades and the last candle is bullish
  - Current price is higher than the highest entry price (for scaling in)

### Interface Elements

- Enable/Disable Button: Controls EA's trading activity
- Status Display:
  - ✔️ : EA is enabled and ready to trade
  - ✖️ : EA is disabled or missing tp/sl lines
  - Open positions count
  - Current balance/profit
  - Risk-to-Reward ratio

## Dependencies

- Trade.mqh
- SymbolInfo.mqh
- ChartObjectsTxtControls.mqh
- Controls/Button.mqh

## License

Copyright  @2025, Malinda Rasingolla.