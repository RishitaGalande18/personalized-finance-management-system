from datetime import date
from operator import inv
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List
from decimal import Decimal

from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentResponse, SellInvestmentRequest
from app.utils.dependencies import get_db
from app.utils.auth_dependencies import get_current_user
from app.models.user import User

from app.services.portfolio_service import update_user_portfolio
from app.services.investment_engine import update_investment_value
from app.schemas import investment

router = APIRouter(
    prefix="/investment",
    tags=["Investment"]
)

# ---------------- CREATE INVESTMENT ----------------

@router.post("")
def add_investment(
    investment: InvestmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    principal = investment.principal_amount

    # Auto calculate for STOCK
    if investment.investment_type == "STOCK":
        principal = investment.quantity * investment.buy_price

    new_investment = Investment(
        user_id=current_user.id,
        investment_type=investment.investment_type,
        principal_amount=principal,
        rate_of_return=investment.rate_of_return,
        quantity=investment.quantity,
        buy_price=investment.buy_price,
        start_date=investment.start_date,
        auto_update=investment.auto_update
    )

    db.add(new_investment)
    db.commit()
    db.refresh(new_investment)

    return new_investment



# ---------------- LIST INVESTMENTS ----------------

@router.get(
    "",
    response_model=List[InvestmentResponse]
)
def list_investments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Investment).filter(
        Investment.user_id == current_user.id
    ).all()

# ---------------- GET PORTFOLIO VALUE ----------------

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

        if inv.is_active:
          current_value = update_investment_value(inv)
          inv.current_value = current_value
        else:
          current_value = inv.current_value or inv.principal_amount

        principal = inv.principal_amount or Decimal("0")

        # 🔥 PROFIT LOGIC
        if inv.is_active:
            unrealized = current_value - principal
            realized = Decimal("0")
        else:
            unrealized = Decimal("0")
            realized = inv.realized_profit or Decimal("0")

        percent = (unrealized / principal * 100) if principal != 0 else 0

        total_value += current_value
        total_invested += principal
        total_realized += realized

        investment_list.append({
            "id": inv.id,
            "investment_type": inv.investment_type,
            "investment_name": inv.investment_name,
            "principal_amount": float(principal),
            "current_value": float(current_value),
            "unrealized_profit": float(unrealized),
            "realized_profit": float(realized),
            "return_percentage": float(percent),
            "is_active": inv.is_active,
            "sell_date": str(inv.sell_date) if inv.sell_date else None
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
    payload: SellInvestmentRequest,   # ✅ body
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
    
    # TYPE BASED SELL LOGIC
    if investment.investment_type == "STOCK":
     investment.realized_profit = (
        (sell_price - investment.buy_price) * investment.quantity
    )

    elif investment.investment_type in ["FD", "GOLD", "REAL_ESTATE"]:
     investment.realized_profit = (
        sell_price - investment.principal_amount
    )

    elif investment.investment_type == "SIP":
     investment.realized_profit = (
        sell_price - investment.principal_amount
    )

    else:
     investment.realized_profit = (
        sell_price - investment.principal_amount
    )

    investment.is_active = False

    db.commit()

    return {
        "message": "Investment sold successfully",
        "profit": investment.realized_profit
    }

# ---------------- Analytics Api ----------------

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