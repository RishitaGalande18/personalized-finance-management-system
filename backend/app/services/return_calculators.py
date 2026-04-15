from decimal import Decimal, getcontext
from datetime import date
import yfinance as yf

getcontext().prec = 10


def calculate_fd(principal, rate, start_date):
    if not start_date or not rate:
        return principal

    years = Decimal((date.today() - start_date).days) / Decimal(365)
    rate = Decimal(rate) / Decimal(100)

    amount = Decimal(principal) * ((Decimal(1) + rate) ** years)
    return amount.quantize(Decimal("0.01"))


def calculate_sip(principal, rate, start_date):
    if not start_date or not rate:
        return principal

    months = (
        (date.today().year - start_date.year) * 12 +
        (date.today().month - start_date.month)
    )

    monthly_rate = Decimal(rate) / Decimal(100) / Decimal(12)

    if monthly_rate == 0:
        return Decimal(principal)

    future_value = Decimal(principal) * (
        ((Decimal(1) + monthly_rate) ** months - 1) / monthly_rate
    )

    return future_value.quantize(Decimal("0.01"))


def calculate_stock(quantity, buy_price, symbol=None):
    if not quantity or not buy_price:
        return Decimal("0")

    try:
        if not symbol:
            return Decimal(quantity) * Decimal(buy_price)

        import yfinance as yf
        stock = yf.Ticker(symbol)
        data = stock.history(period="1d")

        if data.empty:
            return Decimal(quantity) * Decimal(buy_price)

        live_price = Decimal(str(data["Close"].iloc[-1]))

        return (Decimal(quantity) * live_price).quantize(Decimal("0.01"))

    except Exception as e:
        print("Stock fetch error:", e)
        return (Decimal(quantity) * Decimal(buy_price)).quantize(Decimal("0.01"))