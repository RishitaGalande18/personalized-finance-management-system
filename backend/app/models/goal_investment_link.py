from sqlalchemy import Column, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base


class GoalInvestmentLink(Base):
    __tablename__ = "goal_investment_links"
    __table_args__ = (
        UniqueConstraint("investment_id", name="uq_goal_investment_links_investment_id"),
    )

    id = Column(Integer, primary_key=True, index=True)
    goal_id = Column(Integer, ForeignKey("goals.id"), nullable=False)
    investment_id = Column(Integer, ForeignKey("investments.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    goal = relationship("Goal", back_populates="investment_links")
    investment = relationship("Investment", back_populates="goal_link")
