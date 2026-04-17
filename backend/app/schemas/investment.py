from pydantic import BaseModel, model_validator
from typing import Optional
from decimal import Decimal
from datetime import date


class InvestmentCreate(BaseModel):
    investment_type: str
    investment_name: Optional[str] = None  # ✅ NEW

    # Common
    start_date: Optional[date] = None
    auto_update: bool = True

    # FD / SIP / GOLD / REAL_ESTATE
    principal_amount: Optional[Decimal] = None
    rate_of_return: Optional[Decimal] = None

    # STOCK
    quantity: Optional[Decimal] = None
    buy_price: Optional[Decimal] = None
    symbol: Optional[str] = None  # ✅ NEW

    @model_validator(mode="after")
    def validate_fields(self):

        if self.investment_type in ["FD", "SIP", "GOLD", "REAL_ESTATE"]:
            if not self.principal_amount:
                raise ValueError("principal_amount required")

        if self.investment_type == "STOCK":
            if not self.quantity or not self.buy_price:
                raise ValueError("quantity and buy_price required for STOCK")

        return self


class InvestmentResponse(BaseModel):
    id: int
    investment_type: str
    investment_name: Optional[str]

    # Core values
    principal_amount: Decimal
    current_value: Decimal

    # Profit separation ✅
    unrealized_profit: float
    realized_profit: float

    return_percentage: float

    # Meta
    is_active: bool
    sell_date: Optional[date]

    # Optional fields (keep for compatibility)
    rate_of_return: Optional[Decimal]
    compounding_frequency: Optional[str]
    symbol: Optional[str]
    quantity: Optional[Decimal]
    buy_price: Optional[Decimal]
    start_date: Optional[date]

    class Config:
        from_attributes = True


class SellInvestmentRequest(BaseModel):
    sell_price: Decimal
