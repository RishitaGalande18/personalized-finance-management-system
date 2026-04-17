from datetime import date, datetime
from math import ceil
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from decimal import Decimal

from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.models.goal_investment_link import GoalInvestmentLink
from app.models.investment import Investment
from app.services.investment_engine import update_investment_value
from app.schemas.goal import (
    GoalContributionCreate,
    GoalContributionResponse,
    GoalCreate,
    GoalDetailResponse,
    GoalInvestmentLinkCreate,
    GoalInvestmentLinkResponse,
    GoalResponse,
    GoalSummaryResponse,
    LinkedInvestmentResponse,
)
from app.utils.dependencies import get_db
from app.utils.auth_dependencies import get_current_user
from app.models.user import User
from app.services.goal_allocation_service import allocate_monthly_savings

router = APIRouter(
    prefix="/goal",
    tags=["Goal"]
)


def _get_user_goal_or_404(db: Session, goal_id: int, user_id: int) -> Goal:
    goal = db.query(Goal).filter(
        Goal.id == goal_id,
        Goal.user_id == user_id
    ).first()

    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )

    return goal


def _build_goal_detail_response(db: Session, goal: Goal) -> GoalDetailResponse:
    goal_amounts = _calculate_goal_amounts(db, goal)
    goal_metrics = _calculate_goal_metrics(goal, goal_amounts["total_saved_amount"])
    contribution_history = _build_goal_contribution_history(db, goal)

    return GoalDetailResponse(
        id=goal.id,
        name=goal.name,
        target_amount=goal.target_amount,
        deadline=goal.deadline,
        priority=goal.priority,
        saved_amount=goal_amounts["total_saved_amount"],
        investment_contribution=goal_amounts["investment_contribution"],
        total_saved_amount=goal_amounts["total_saved_amount"],
        remaining_amount=goal_metrics["remaining_amount"],
        progress_percentage=goal_metrics["progress_percentage"],
        days_left=goal_metrics["days_left"],
        months_left=goal_metrics["months_left"],
        required_monthly_saving=goal_metrics["required_monthly_saving"],
        status=goal_metrics["status"],
        linked_investments=goal_amounts["linked_investments"],
        contribution_history=contribution_history
    )


def _build_goal_response(db: Session, goal: Goal) -> GoalResponse:
    goal_amounts = _calculate_goal_amounts(db, goal)
    goal_metrics = _calculate_goal_metrics(goal, goal_amounts["total_saved_amount"])

    return GoalResponse(
        id=goal.id,
        name=goal.name,
        target_amount=goal.target_amount,
        deadline=goal.deadline,
        priority=goal.priority,
        saved_amount=goal_amounts["total_saved_amount"],
        investment_contribution=goal_amounts["investment_contribution"],
        total_saved_amount=goal_amounts["total_saved_amount"],
        remaining_amount=goal_metrics["remaining_amount"],
        progress_percentage=goal_metrics["progress_percentage"],
        days_left=goal_metrics["days_left"],
        months_left=goal_metrics["months_left"],
        required_monthly_saving=goal_metrics["required_monthly_saving"],
        status=goal_metrics["status"]
    )


def _quantize_money(value: Decimal | int | float) -> Decimal:
    return Decimal(value or 0).quantize(Decimal("0.01"))


def _calculate_investment_goal_contribution(investment: Investment) -> Decimal:
    principal_amount = Decimal(investment.principal_amount or 0)

    if investment.is_active:
        current_value = (
            Decimal(update_investment_value(investment))
            if investment.auto_update
            else Decimal(investment.current_value or investment.principal_amount or 0)
        )
        return (current_value - principal_amount).quantize(Decimal("0.01"))

    return Decimal(investment.realized_profit or 0).quantize(Decimal("0.01"))


def _calculate_goal_amounts(db: Session, goal: Goal) -> dict[str, Decimal | list[LinkedInvestmentResponse]]:
    manual_total = Decimal("0.00")
    for (amount,) in db.query(GoalContribution.amount).filter(
        GoalContribution.goal_id == goal.id
    ).all():
        manual_total += Decimal(amount or 0)

    investment_total = Decimal("0.00")
    linked_investments = db.query(GoalInvestmentLink, Investment).join(
        GoalInvestmentLink,
        GoalInvestmentLink.investment_id == Investment.id
    ).filter(
        GoalInvestmentLink.goal_id == goal.id
    ).all()
    linked_investment_responses: list[LinkedInvestmentResponse] = []

    for link, investment in linked_investments:
        contribution = _calculate_investment_goal_contribution(investment)
        investment_total += contribution
        linked_investment_responses.append(
            LinkedInvestmentResponse(
                investment_id=investment.id,
                investment_name=investment.investment_name or investment.investment_type,
                investment_type=investment.investment_type,
                contribution=contribution,
                is_active=bool(investment.is_active)
            )
        )

    investment_total = investment_total.quantize(Decimal("0.01"))
    total_saved_amount = (manual_total + investment_total).quantize(Decimal("0.01"))

    return {
        "manual_contribution": manual_total.quantize(Decimal("0.01")),
        "investment_contribution": investment_total,
        "total_saved_amount": total_saved_amount,
        "linked_investments": linked_investment_responses,
    }


def _build_goal_contribution_history(
    db: Session,
    goal: Goal
) -> list[GoalContributionResponse]:
    history: list[GoalContributionResponse] = []

    manual_contributions = db.query(GoalContribution).filter(
        GoalContribution.goal_id == goal.id
    ).order_by(
        GoalContribution.date.desc(),
        GoalContribution.id.desc()
    ).all()

    for contribution in manual_contributions:
        history.append(
            GoalContributionResponse(
                amount=Decimal(contribution.amount or 0).quantize(Decimal("0.01")),
                date=contribution.date,
                source="manual",
                label="Manual"
            )
        )

    linked_investments = db.query(GoalInvestmentLink, Investment).join(
        Investment,
        Investment.id == GoalInvestmentLink.investment_id
    ).filter(
        GoalInvestmentLink.goal_id == goal.id
    ).all()

    for link, investment in linked_investments:
        created_at = link.created_at
        history.append(
            GoalContributionResponse(
                amount=_calculate_investment_goal_contribution(investment),
                date=created_at.date() if created_at else None,
                source="investment",
                label=investment.investment_name or investment.investment_type
            )
        )

    history.sort(
        key=lambda entry: (
            entry.date or date.min,
            1 if entry.source == "manual" else 0
        ),
        reverse=True
    )
    return history


def _calculate_goal_metrics(goal: Goal, total_saved_amount: Decimal) -> dict[str, Decimal | int | str | None]:
    target_amount = Decimal(goal.target_amount or 0)
    remaining_amount = max(target_amount - total_saved_amount, Decimal("0")).quantize(Decimal("0.01"))

    if target_amount <= 0:
        progress_percentage = Decimal("0.00")
    else:
        progress_percentage = min(
            (total_saved_amount / target_amount) * Decimal("100"),
            Decimal("100")
        ).quantize(Decimal("0.01"))

    days_left: int | None = None
    months_left: int | None = None
    required_monthly_saving: Decimal | None = None

    if goal.deadline:
        days_left = max((goal.deadline - date.today()).days, 0)

        if remaining_amount <= 0:
            months_left = 0
            required_monthly_saving = Decimal("0.00")
        else:
            months_left = max(ceil(days_left / 30), 1)
            required_monthly_saving = (
                remaining_amount / Decimal(months_left)
            ).quantize(Decimal("0.01"))

    created_at = goal.created_at
    if isinstance(created_at, str):
        created_at = datetime.fromisoformat(created_at)
    created_date = (
        created_at
        if isinstance(created_at, date) and not isinstance(created_at, datetime)
        else created_at.date() if created_at else date.today()
    )
    elapsed_days = max((date.today() - created_date).days, 0)
    elapsed_months = max(ceil(elapsed_days / 30), 1)
    current_monthly_contribution_rate = (
        total_saved_amount / Decimal(elapsed_months)
    ).quantize(Decimal("0.01"))

    if remaining_amount <= 0:
        status_value = "completed"
    elif goal.deadline and days_left == 0:
        status_value = "behind"
    elif required_monthly_saving is None or current_monthly_contribution_rate >= required_monthly_saving:
        status_value = "on_track"
    else:
        status_value = "behind"

    return {
        "remaining_amount": remaining_amount,
        "progress_percentage": progress_percentage,
        "days_left": days_left,
        "months_left": months_left,
        "required_monthly_saving": required_monthly_saving,
        "status": status_value
    }

# ---------------- CREATE GOAL ----------------

@router.get("", response_model=list[GoalResponse])
@router.get("/", response_model=list[GoalResponse])
def list_goals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goals = db.query(Goal).filter(
        Goal.user_id == current_user.id
    ).order_by(Goal.deadline.asc(), Goal.created_at.desc()).all()

    return [_build_goal_response(db, goal) for goal in goals]


@router.post(
    "",
    response_model=GoalResponse,
    status_code=status.HTTP_201_CREATED
)
@router.post(
    "/",
    response_model=GoalResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False
)
def create_goal(
    goal: GoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_goal = Goal(
        user_id=current_user.id,
        name=goal.name,
        target_amount=goal.target_amount,
        deadline=goal.deadline,
        priority=goal.priority
    )

    db.add(new_goal)
    db.commit()
    db.refresh(new_goal)

    return _build_goal_response(db, new_goal)


# ---------------- GOAL PROGRESS ----------------

@router.get("/progress")
def goal_progress(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goals = db.query(Goal).filter(
        Goal.user_id == current_user.id
    ).all()

    result = []
    for g in goals:
        goal_amounts = _calculate_goal_amounts(db, g)
        goal_metrics = _calculate_goal_metrics(g, goal_amounts["total_saved_amount"])
        result.append({
            "goal": g.name,
            "saved_amount": goal_amounts["total_saved_amount"],
            "investment_contribution": goal_amounts["investment_contribution"],
            "total_saved_amount": goal_amounts["total_saved_amount"],
            "remaining_amount": goal_metrics["remaining_amount"],
            "days_left": goal_metrics["days_left"],
            "months_left": goal_metrics["months_left"],
            "required_monthly_saving": goal_metrics["required_monthly_saving"],
            "status": goal_metrics["status"],
            "progress_percentage": round(float(goal_metrics["progress_percentage"]), 2)
        })

    return result

@router.get("/summary", response_model=GoalSummaryResponse)
def goal_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goals = db.query(Goal).filter(
        Goal.user_id == current_user.id
    ).all()

    total_goals = len(goals)
    total_target_amount = sum((Decimal(goal.target_amount or 0) for goal in goals), Decimal("0"))
    total_saved_amount = Decimal("0.00")
    for goal in goals:
        total_saved_amount += _calculate_goal_amounts(db, goal)["total_saved_amount"]

    overall_progress_percentage = Decimal("0.00")
    if total_target_amount > 0:
        overall_progress_percentage = (
            (total_saved_amount / total_target_amount) * Decimal("100")
        ).quantize(Decimal("0.01"))

    return GoalSummaryResponse(
        total_goals=total_goals,
        total_target_amount=total_target_amount.quantize(Decimal("0.01")),
        total_saved_amount=total_saved_amount.quantize(Decimal("0.01")),
        overall_progress_percentage=overall_progress_percentage
    )

@router.post("/allocate-monthly")
def allocate_monthly(
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    return allocate_monthly_savings(db, user.id)


@router.get("/{id}", response_model=GoalDetailResponse)
def get_goal(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = _get_user_goal_or_404(db, id, current_user.id)
    return _build_goal_detail_response(db, goal)


@router.post(
    "/{id}/contribute",
    response_model=GoalDetailResponse,
    status_code=status.HTTP_201_CREATED
)
def contribute_to_goal(
    id: int,
    contribution: GoalContributionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = _get_user_goal_or_404(db, id, current_user.id)

    contribution_amount = Decimal(contribution.amount)
    goal_amounts = _calculate_goal_amounts(db, goal)
    goal_metrics = _calculate_goal_metrics(goal, goal_amounts["total_saved_amount"])
    if contribution_amount > goal_metrics["remaining_amount"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contribution exceeds remaining goal amount"
        )

    db.add(GoalContribution(
        goal_id=goal.id,
        amount=contribution_amount,
        source="manual"
    ))
    db.commit()

    updated_goal = _get_user_goal_or_404(db, id, current_user.id)
    return _build_goal_detail_response(db, updated_goal)


@router.post(
    "/{goal_id}/link-investment",
    response_model=GoalInvestmentLinkResponse,
    status_code=status.HTTP_201_CREATED
)
def link_investment_to_goal(
    goal_id: int,
    payload: GoalInvestmentLinkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = _get_user_goal_or_404(db, goal_id, current_user.id)

    investment = db.query(Investment).filter(
        Investment.id == payload.investment_id,
        Investment.user_id == current_user.id
    ).first()

    if not investment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found"
        )

    existing_link = db.query(GoalInvestmentLink).filter(
        GoalInvestmentLink.investment_id == payload.investment_id
    ).first()

    if existing_link:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Investment is already linked to a goal"
        )

    goal_investment_link = GoalInvestmentLink(
        goal_id=goal.id,
        investment_id=investment.id
    )

    db.add(goal_investment_link)
    db.commit()

    return GoalInvestmentLinkResponse(
        message="Investment linked to goal successfully",
        goal_id=goal.id,
        investment_id=investment.id
    )


@router.delete(
    "/{goal_id}/unlink-investment/{investment_id}",
    response_model=GoalInvestmentLinkResponse
)
def unlink_investment_from_goal(
    goal_id: int,
    investment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    _get_user_goal_or_404(db, goal_id, current_user.id)

    goal_investment_link = db.query(GoalInvestmentLink).join(
        Investment,
        Investment.id == GoalInvestmentLink.investment_id
    ).filter(
        GoalInvestmentLink.goal_id == goal_id,
        GoalInvestmentLink.investment_id == investment_id,
        Investment.user_id == current_user.id
    ).first()

    if not goal_investment_link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Linked investment not found"
        )

    db.delete(goal_investment_link)
    db.commit()

    return GoalInvestmentLinkResponse(
        message="Investment unlinked from goal successfully",
        goal_id=goal_id,
        investment_id=investment_id
    )
