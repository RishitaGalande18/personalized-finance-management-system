import yfinance as yf

def get_live_price(symbol: str):
    try:
        stock = yf.Ticker(symbol)
        data = stock.history(period="1d")

        if data.empty:
            return None

        return float(data["Close"].iloc[-1])
    except Exception as e:
        print("Error fetching price:", e)
        return None