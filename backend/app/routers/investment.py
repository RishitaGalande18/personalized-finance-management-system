from datetime import date
from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.investment import Investment
from app.models.user import User
from app.schemas.investment import (
    InvestmentCreate,
    InvestmentResponse,
    SellInvestmentRequest,
)
from app.services.investment_engine import update_investment_value
from app.utils.auth_dependencies import get_current_user
from app.utils.dependencies import get_db

router = APIRouter(
    prefix="/investment",
    tags=["Investment"]
)


def _serialize_investment(inv: Investment) -> dict:
    principal = Decimal(inv.principal_amount or 0)

    if inv.is_active:
        current_value = Decimal(update_investment_value(inv))
        unrealized = current_value - principal
        realized = Decimal("0")
    else:
        current_value = Decimal(inv.current_value or inv.principal_amount or 0)
        unrealized = Decimal("0")
        realized = Decimal(inv.realized_profit or 0)

    return_percentage = (unrealized / principal * Decimal("100")) if principal != 0 else Decimal("0")

    return {
        "id": inv.id,
        "investment_type": inv.investment_type,
        "investment_name": inv.investment_name,
        "principal_amount": principal.quantize(Decimal("0.01")),
        "current_value": current_value.quantize(Decimal("0.01")),
        "unrealized_profit": float(unrealized),
        "realized_profit": float(realized),
        "return_percentage": float(return_percentage),
        "is_active": bool(inv.is_active),
        "sell_date": inv.sell_date,
        "rate_of_return": inv.rate_of_return,
        "compounding_frequency": inv.compounding_frequency,
        "symbol": inv.symbol,
        "quantity": inv.quantity,
        "buy_price": inv.buy_price,
        "start_date": inv.start_date,
    }


@router.post("")
def add_investment(
    investment: InvestmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    principal = investment.principal_amount

    if investment.investment_type == "STOCK":
        principal = investment.quantity * investment.buy_price

    new_investment = Investment(
        user_id=current_user.id,
        investment_name=investment.investment_name,
        investment_type=investment.investment_type,
        principal_amount=principal,
        current_value=principal or Decimal("0"),
        rate_of_return=investment.rate_of_return,
        quantity=investment.quantity,
        buy_price=investment.buy_price,
        symbol=investment.symbol,
        start_date=investment.start_date,
        auto_update=investment.auto_update
    )

    db.add(new_investment)
    db.commit()
    db.refresh(new_investment)

    return new_investment


@router.get("", response_model=List[InvestmentResponse])
def list_investments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    investments = db.query(Investment).filter(
        Investment.user_id == current_user.id
    ).all()

    serialized_investments = []
    for inv in investments:
        serialized = _serialize_investment(inv)
        inv.current_value = serialized["current_value"]
        serialized_investments.append(serialized)

    db.commit()
    return serialized_investments


@router.get("/portfolio")
def get_portfolio(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    investments = db.query(Investment).filter(
        Investment.user_id == user.id
    ).all()

    total_value = Decimal("0")
    total_invested = Decimal("0")
    total_realized = Decimal("0")
    investment_list = []

    for inv in investments:
        serialized = _serialize_investment(inv)
        inv.current_value = serialized["current_value"]

        principal = Decimal(serialized["principal_amount"])
        current_value = Decimal(serialized["current_value"])
        realized = Decimal(str(serialized["realized_profit"]))

        total_value += current_value
        total_invested += principal
        total_realized += realized

        investment_list.append({
            **serialized,
            "principal_amount": float(principal),
            "current_value": float(current_value),
            "sell_date": str(serialized["sell_date"]) if serialized["sell_date"] else None,
        })

    total_unrealized = total_value - total_invested

    db.commit()

    return {
        "portfolio_value": float(total_value),
        "total_unrealized": float(total_unrealized),
        "total_realized": float(total_realized),
        "investments": investment_list
    }


@router.post("/sell/{investment_id}")
def sell_investment(
    investment_id: int,
    payload: SellInvestmentRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    investment = db.query(Investment).filter(
        Investment.id == investment_id,
        Investment.user_id == current_user.id,
        Investment.is_active == True
    ).first()

    if not investment:
        raise HTTPException(status_code=404, detail="Active investment not found")

    sell_price = payload.sell_price

    investment.sell_price = sell_price
    investment.sell_date = date.today()

    if investment.investment_type == "STOCK":
        investment.realized_profit = (
            (sell_price - investment.buy_price) * investment.quantity
        )
    elif investment.investment_type in ["FD", "GOLD", "REAL_ESTATE", "SIP"]:
        investment.realized_profit = (
            sell_price - investment.principal_amount
        )
    else:
        investment.realized_profit = (
            sell_price - investment.principal_amount
        )

    investment.current_value = sell_price
    investment.is_active = False

    db.commit()

    return {
        "message": "Investment sold successfully",
        "profit": investment.realized_profit
    }


@router.get("/analytics")
def investment_analytics(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    investments = db.query(Investment).filter(
        Investment.user_id == user.id,
        Investment.is_active == False
    ).all()

    monthly = {}
    yearly = {}

    for inv in investments:
        if not inv.sell_date:
            continue

        month = inv.sell_date.strftime("%Y-%m")
        year = inv.sell_date.strftime("%Y")
        profit = float(inv.realized_profit or 0)

        monthly[month] = monthly.get(month, 0) + profit
        yearly[year] = yearly.get(year, 0) + profit

    return {
        "monthly_profit": monthly,
        "yearly_profit": yearly
    }
