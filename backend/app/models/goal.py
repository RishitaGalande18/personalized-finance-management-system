from sqlalchemy import (
    Column,
    Integer,
    String,
    Date,
    ForeignKey,
    DateTime,
    Numeric,
    select,
    text
)
from sqlalchemy.sql import func
from sqlalchemy.orm import column_property, relationship
from sqlalchemy.ext.hybrid import hybrid_property
from decimal import Decimal
from datetime import date, datetime
from math import ceil

from app.db.database import Base
from app.models.goal_contribution import GoalContribution
from app.models.goal_investment_link import GoalInvestmentLink

class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String(100), nullable=False)

    # Financial precision
    target_amount = Column(Numeric(10, 2), nullable=False)
    legacy_saved_amount = Column(
        "saved_amount",
        Numeric(10, 2),
        nullable=False,
        default=Decimal("0.00"),
        server_default=text("0")
    )
    _saved_amount_expression = column_property(
        select(func.coalesce(func.sum(GoalContribution.amount), 0))
        .where(GoalContribution.goal_id == id)
        .correlate_except(GoalContribution)
        .scalar_subquery()
    )

    deadline = Column(Date, nullable=True)

    # Example: 1 = high, 2 = medium, 3 = low
    priority = Column(Integer, nullable=True)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    # ORM relationship
    user = relationship("User", backref="goals")
    contributions = relationship(
        "GoalContribution",
        back_populates="goal",
        cascade="all, delete-orphan"
    )
    investment_links = relationship(
        "GoalInvestmentLink",
        back_populates="goal",
        cascade="all, delete-orphan"
    )

    @hybrid_property
    def saved_amount(self) -> Decimal:
        if "contributions" in self.__dict__:
            total = sum(
                (Decimal(contribution.amount or 0) for contribution in self.contributions),
                Decimal("0")
            )
            return total.quantize(Decimal("0.01"))

        return Decimal(self._saved_amount_expression or 0).quantize(Decimal("0.01"))

    @saved_amount.expression
    def saved_amount(cls):
        return cls._saved_amount_expression

    @property
    def remaining_amount(self) -> Decimal:
        remaining = Decimal(self.target_amount or 0) - Decimal(self.saved_amount or 0)
        return max(remaining, Decimal("0"))

    @property
    def progress_percentage(self) -> Decimal:
        target_amount = Decimal(self.target_amount or 0)
        if target_amount <= 0:
            return Decimal("0")

        progress = (Decimal(self.saved_amount or 0) / target_amount) * Decimal("100")
        return min(progress, Decimal("100"))

    @property
    def days_left(self) -> int | None:
        if not self.deadline:
            return None

        return max((self.deadline - date.today()).days, 0)

    @property
    def months_left(self) -> int | None:
        if not self.deadline:
            return None

        if self.remaining_amount <= 0:
            return 0

        return max(ceil(self.days_left / 30), 1)

    @property
    def monthly_required_saving(self) -> Decimal | None:
        if not self.deadline:
            return None

        remaining_amount = self.remaining_amount
        if remaining_amount <= 0:
            return Decimal("0.00")

        months_left = self.months_left
        if not months_left:
            return remaining_amount.quantize(Decimal("0.01"))

        return (remaining_amount / Decimal(months_left)).quantize(Decimal("0.01"))

    @property
    def current_monthly_contribution_rate(self) -> Decimal:
        created_at = self.created_at
        if not created_at:
            return Decimal("0.00")

        if isinstance(created_at, str):
            created_at = datetime.fromisoformat(created_at)
        created_date = (
            created_at
            if isinstance(created_at, date) and not isinstance(created_at, datetime)
            else created_at.date()
        )

        elapsed_days = max((date.today() - created_date).days, 0)
        elapsed_months = max(ceil(elapsed_days / 30), 1)
        return (Decimal(self.saved_amount or 0) / Decimal(elapsed_months)).quantize(Decimal("0.01"))

    @property
    def status(self) -> str:
        if self.remaining_amount <= 0:
            return "completed"

        if self.deadline and self.days_left == 0:
            return "behind"

        required_monthly_saving = self.monthly_required_saving
        if required_monthly_saving is None:
            return "on_track"

        if self.current_monthly_contribution_rate >= required_monthly_saving:
            return "on_track"

        return "behind"
