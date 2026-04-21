from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.debt import Debt
from app.models.debt_payment import DebtPayment
from app.models.user import User
from app.schemas.debt import (
    DebtCreate,
    DebtPaymentCreate,
    DebtPaymentResponse,
    DebtResponse,
)
from app.utils.auth_dependencies import get_current_user
from app.utils.dependencies import get_db

router = APIRouter(
    prefix="/debt",
    tags=["Debt"]
)


def _to_money(value: Decimal | int | float | None) -> Decimal:
    return Decimal(value or 0).quantize(Decimal("0.01"))


def _build_debt_response(debt: Debt) -> DebtResponse:
    principal_amount = _to_money(debt.principal_amount)
    remaining_amount = _to_money(debt.remaining_amount or debt.principal_amount)
    paid_amount = _to_money(principal_amount - remaining_amount)

    if principal_amount <= 0:
        progress_paid = Decimal("0.00")
        progress_remaining = Decimal("0.00")
    else:
        progress_paid = min(
            (paid_amount / principal_amount) * Decimal("100"),
            Decimal("100")
        ).quantize(Decimal("0.01"))
        progress_remaining = max(
            Decimal("0"),
            Decimal("100") - progress_paid
        ).quantize(Decimal("0.01"))

    payments = sorted(
        debt.payments,
        key=lambda payment: (payment.payment_date, payment.id),
        reverse=True
    )

    return DebtResponse(
        id=debt.id,
        debt_type=debt.debt_type,
        principal_amount=principal_amount,
        remaining_amount=remaining_amount,
        emi_amount=_to_money(debt.emi_amount) if debt.emi_amount is not None else None,
        interest_rate=Decimal(debt.interest_rate or 0).quantize(Decimal("0.01"))
        if debt.interest_rate is not None else None,
        due_date=debt.due_date,
        is_active=bool(debt.is_active),
        paid_amount=paid_amount,
        progress_paid_percentage=progress_paid,
        progress_remaining_percentage=progress_remaining,
        payments=[
            DebtPaymentResponse.model_validate(payment)
            for payment in payments
        ]
    )


def _get_user_debt_or_404(db: Session, debt_id: int, user_id: int) -> Debt:
    debt = db.query(Debt).filter(
        Debt.id == debt_id,
        Debt.user_id == user_id
    ).first()

    if not debt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Debt not found"
        )

    return debt


@router.post(
    "",
    response_model=DebtResponse,
    status_code=status.HTTP_201_CREATED
)
@router.post(
    "/",
    response_model=DebtResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False
)
def add_debt(
    debt: DebtCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_debt = Debt(
        user_id=current_user.id,
        debt_type=debt.debt_type,
        principal_amount=debt.principal_amount,
        remaining_amount=debt.principal_amount,
        emi_amount=debt.emi_amount,
        interest_rate=debt.interest_rate,
        due_date=debt.due_date,
        is_active=True
    )

    db.add(new_debt)
    db.commit()
    db.refresh(new_debt)

    return _build_debt_response(new_debt)


@router.get(
    "",
    response_model=list[DebtResponse]
)
@router.get(
    "/",
    response_model=list[DebtResponse],
    include_in_schema=False
)
def list_debts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    debts = db.query(Debt).filter(
        Debt.user_id == current_user.id
    ).all()

    return [_build_debt_response(debt) for debt in debts]


@router.post(
    "/{debt_id}/payment",
    response_model=DebtResponse,
    status_code=status.HTTP_201_CREATED
)
def add_debt_payment(
    debt_id: int,
    payload: DebtPaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    debt = _get_user_debt_or_404(db, debt_id, current_user.id)

    if not debt.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Debt is already fully paid"
        )

    remaining_amount = _to_money(debt.remaining_amount or debt.principal_amount)
    payment_amount = _to_money(payload.amount)

    if payment_amount > remaining_amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment exceeds remaining debt amount"
        )

    payment = DebtPayment(
        debt_id=debt.id,
        amount=payment_amount,
        payment_date=payload.payment_date or date.today()
    )

    debt.remaining_amount = _to_money(remaining_amount - payment_amount)
    debt.is_active = debt.remaining_amount > 0

    db.add(payment)
    db.commit()
    db.refresh(debt)

    return _build_debt_response(debt)
