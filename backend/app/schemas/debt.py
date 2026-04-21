from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class DebtCreate(BaseModel):
    debt_type: str
    principal_amount: Decimal = Field(..., gt=0)
    emi_amount: Decimal = Field(..., gt=0)
    interest_rate: Decimal | None = Field(default=None, ge=0)
    due_date: date | None = None


class DebtPaymentCreate(BaseModel):
    amount: Decimal = Field(..., gt=0)
    payment_date: date | None = None


class DebtPaymentResponse(BaseModel):
    id: int
    amount: Decimal
    payment_date: date

    model_config = ConfigDict(from_attributes=True)


class DebtResponse(BaseModel):
    id: int
    debt_type: str
    principal_amount: Decimal
    remaining_amount: Decimal
    emi_amount: Decimal | None = None
    interest_rate: Decimal | None = None
    due_date: date | None = None
    is_active: bool
    paid_amount: Decimal
    progress_paid_percentage: Decimal
    progress_remaining_percentage: Decimal
    payments: list[DebtPaymentResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)
