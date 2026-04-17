from pydantic import BaseModel, Field, ConfigDict
from decimal import Decimal
from datetime import date as date_type


class GoalCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    target_amount: Decimal = Field(..., gt=0)
    deadline: date_type
    priority: int = Field(..., ge=1, le=5)


class GoalResponse(GoalCreate):
    id: int
    saved_amount: Decimal = Decimal("0")
    investment_contribution: Decimal = Decimal("0")
    total_saved_amount: Decimal = Decimal("0")
    remaining_amount: Decimal = Decimal("0")
    progress_percentage: Decimal = Decimal("0")
    days_left: int | None = None
    months_left: int | None = None
    required_monthly_saving: Decimal | None = None
    status: str = "on_track"

    model_config = ConfigDict(from_attributes=True)


class GoalContributionCreate(BaseModel):
    amount: Decimal = Field(..., gt=0)


class GoalInvestmentLinkCreate(BaseModel):
    investment_id: int = Field(..., gt=0)


class GoalContributionResponse(BaseModel):
    amount: Decimal
    date: date_type | None = None
    source: str
    label: str | None = None

    model_config = ConfigDict(from_attributes=True)


class GoalInvestmentLinkResponse(BaseModel):
    message: str
    goal_id: int
    investment_id: int


class LinkedInvestmentResponse(BaseModel):
    investment_id: int
    investment_name: str
    investment_type: str
    contribution: Decimal = Decimal("0")
    is_active: bool


class GoalDetailResponse(GoalResponse):
    linked_investments: list[LinkedInvestmentResponse] = Field(default_factory=list)
    contribution_history: list[GoalContributionResponse] = Field(default_factory=list)


class GoalSummaryResponse(BaseModel):
    total_goals: int
    total_target_amount: Decimal = Decimal("0")
    total_saved_amount: Decimal = Decimal("0")
    overall_progress_percentage: Decimal = Decimal("0")
