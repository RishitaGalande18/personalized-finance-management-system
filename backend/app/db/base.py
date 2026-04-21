from sqlalchemy import inspect, text

from app.db.database import engine, Base

# Import all models so SQLAlchemy registers them
from app.models.user import User
from app.models.income import Income
from app.models.expense import Expense
from app.models.category import Category
from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.models.goal_investment_link import GoalInvestmentLink
from app.models.investment import Investment
from app.models.debt import Debt
from app.models.debt_payment import DebtPayment
from app.models.alert import Alert
from app.models.goal_allocation import GoalAllocation
from app.models.user_training_data import UserTrainingData

def _ensure_debt_schema():
    inspector = inspect(engine)
    if not inspector.has_table("debts"):
        return

    existing_columns = {
        column["name"]
        for column in inspector.get_columns("debts")
    }

    column_definitions = {
        "remaining_amount": "NUMERIC(10, 2)",
        "emi_amount": "NUMERIC(10, 2)",
        "interest_rate": "NUMERIC(5, 2)",
        "due_date": "DATE",
        "is_active": "BOOLEAN DEFAULT TRUE",
        "created_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
        "updated_at": "TIMESTAMP WITH TIME ZONE DEFAULT NOW()",
    }

    with engine.begin() as conn:
        for column_name, column_type in column_definitions.items():
            if column_name not in existing_columns:
                conn.execute(
                    text(f"ALTER TABLE debts ADD COLUMN {column_name} {column_type}")
                )

        conn.execute(
            text(
                """
                UPDATE debts
                SET remaining_amount = COALESCE(remaining_amount, principal_amount),
                    is_active = COALESCE(is_active, TRUE)
                """
            )
        )

        if engine.dialect.name == "postgresql":
            conn.execute(
                text("ALTER TABLE debts ALTER COLUMN remaining_amount SET NOT NULL")
            )
            conn.execute(
                text("ALTER TABLE debts ALTER COLUMN is_active SET NOT NULL")
            )


def create_tables():
    Base.metadata.create_all(bind=engine)
    _ensure_debt_schema()
