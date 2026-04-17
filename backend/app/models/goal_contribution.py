from datetime import date

from sqlalchemy import Column, Date, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship

from app.db.database import Base


class GoalContribution(Base):
    __tablename__ = "goal_contributions"

    id = Column(Integer, primary_key=True, index=True)
    goal_id = Column(Integer, ForeignKey("goals.id"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    date = Column(Date, nullable=False, default=date.today)
    source = Column(String(20), nullable=False)

    goal = relationship("Goal", back_populates="contributions")
