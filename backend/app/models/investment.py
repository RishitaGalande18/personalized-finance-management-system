from sqlalchemy import Column, Integer, String, ForeignKey, Date, Numeric, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base

class Investment(Base):
    __tablename__ = "investments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    investment_name = Column(String(100), nullable=True)  # e.g Apple, SBI FD, Gold
    investment_type = Column(String(50), nullable=False)  # STOCK, FD, SIP, GOLD, REAL_ESTATE

    principal_amount = Column(Numeric(12,2), nullable=False)
    current_value = Column(Numeric(12,2), default=0)

    rate_of_return = Column(Numeric(5,2), nullable=True)
    compounding_frequency = Column(String(20), nullable=True)  # monthly/yearly

    quantity = Column(Numeric(10,2), nullable=True)  # for stocks
    buy_price = Column(Numeric(10,2), nullable=True)
    symbol = Column(String(20), nullable=True)

    start_date = Column(Date, nullable=False)
    auto_update = Column(Boolean, default=True)

    created_at = Column(Date, server_default=func.now())
    updated_at = Column(Date, server_default=func.now(), onupdate=func.now())

    sell_price = Column(Numeric(12, 2), nullable=True)
    sell_date = Column(Date, nullable=True)

    realized_profit = Column(Numeric(12, 2), nullable=True)

    is_active = Column(Boolean, default=True)

    goal_link = relationship(
        "GoalInvestmentLink",
        back_populates="investment",
        uselist=False
    )
