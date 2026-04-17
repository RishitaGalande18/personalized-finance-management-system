from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from decimal import Decimal

from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.models.goal_investment_link import GoalInvestmentLink
from app.models.investment import Investment
from app.schemas.goal import (
    GoalContributionCreate,
    GoalContributionResponse,
    GoalCreate,
    GoalDetailResponse,
    GoalInvestmentLinkCreate,
    GoalInvestmentLinkResponse,
    GoalResponse,
    GoalSummaryResponse,
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
    contributions = db.query(GoalContribution).filter(
        GoalContribution.goal_id == goal.id
    ).order_by(
        GoalContribution.date.desc(),
        GoalContribution.id.desc()
    ).all()

    return GoalDetailResponse(
        id=goal.id,
        name=goal.name,
        target_amount=goal.target_amount,
        deadline=goal.deadline,
        priority=goal.priority,
        saved_amount=goal.saved_amount,
        remaining_amount=goal.remaining_amount,
        progress_percentage=goal.progress_percentage.quantize(Decimal("0.01")),
        days_left=goal.days_left,
        months_left=goal.months_left,
        required_monthly_saving=goal.monthly_required_saving,
        status=goal.status,
        contribution_history=[
            GoalContributionResponse.model_validate(contribution)
            for contribution in contributions
        ]
    )


def _build_goal_response(goal: Goal) -> GoalResponse:
    return GoalResponse(
        id=goal.id,
        name=goal.name,
        target_amount=goal.target_amount,
        deadline=goal.deadline,
        priority=goal.priority,
        saved_amount=goal.saved_amount,
        remaining_amount=goal.remaining_amount,
        progress_percentage=goal.progress_percentage.quantize(Decimal("0.01")),
        days_left=goal.days_left,
        months_left=goal.months_left,
        required_monthly_saving=goal.monthly_required_saving,
        status=goal.status
    )

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

    return [_build_goal_response(goal) for goal in goals]


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

    return _build_goal_response(new_goal)


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
        progress = (
            g.progress_percentage
            if g.target_amount else 0
        )
        result.append({
            "goal": g.name,
            "saved_amount": g.saved_amount,
            "remaining_amount": g.remaining_amount,
            "days_left": g.days_left,
            "months_left": g.months_left,
            "required_monthly_saving": g.monthly_required_saving,
            "status": g.status,
            "progress_percentage": round(float(progress), 2)
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
    total_saved_amount = sum((Decimal(goal.saved_amount or 0) for goal in goals), Decimal("0"))

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
    if contribution_amount > goal.remaining_amount:
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
