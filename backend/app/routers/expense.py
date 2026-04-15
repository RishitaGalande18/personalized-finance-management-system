from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from decimal import Decimal

from app.models.expense import Expense
from app.models.category import Category
from app.schemas.expense import ExpenseCreate, ExpenseResponse
from app.utils.dependencies import get_db
from app.utils.auth_dependencies import get_current_user
from app.models.user import User
from app.ml.self_learning_classifier import classify_expense


router = APIRouter(
    prefix="/expense",
    tags=["Expense"]
)


# ---------------- ADD EXPENSE ----------------

@router.post(
    "/",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED
)
def add_expense(
    expense: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    auto_categorized = False
    category_id = expense.category_id

    # ---------------------------------------------
    # 🤖 If no category → Use Self Learning Model
    # ---------------------------------------------
    if not category_id:

        if not expense.description:
            raise HTTPException(
                status_code=400,
                detail="Description required"
            )

        predicted_category, model_source = classify_expense(
            db,
            current_user.id,
            expense.description
        )

        category = db.query(Category).filter(
            Category.name == predicted_category,
            Category.user_id == current_user.id
        ).first()

        if not category:
            raise HTTPException(
                status_code=400,
                detail=f"Predicted category '{predicted_category}' not found"
            )

        category_id = category.id
        auto_categorized = True

    # Manual category validation
    else:
        category = db.query(Category).filter(
            Category.id == category_id,
            Category.user_id == current_user.id
        ).first()

        if not category:
            raise HTTPException(
                status_code=404,
                detail="Category not found"
            )

    new_expense = Expense(
        user_id=current_user.id,
        category_id=category_id,
        amount=expense.amount,
        date=expense.date,
        description=expense.description,
        auto_categorized=auto_categorized
    )

    db.add(new_expense)
    db.commit()
    db.refresh(new_expense)

    return new_expense


# ---------------- EXPENSE SUMMARY ----------------

@router.get("/summary")
def expense_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expenses = db.query(Expense).filter(
        Expense.user_id == current_user.id
    ).all()

    total_expense = sum((e.amount for e in expenses), Decimal("0"))

    category_breakdown = {}
    for e in expenses:
        category = db.query(Category).filter(Category.id == e.category_id).first()
        if category:
            category_name = category.name
            category_breakdown[category_name] = category_breakdown.get(category_name, Decimal("0")) + e.amount

    return {
    "total_expense": float(total_expense),
    "category_breakdown": {
        k: float(v) for k, v in category_breakdown.items()
    }
}

# // ---------------- RECENT EXPENSES ----------------

@router.get("/")
def get_expenses(
    category_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    query = (
        db.query(
            Expense,
            Category.name.label("category"),
            Category.id.label("category_id"),
        )
        .join(Category, Expense.category_id == Category.id)
        .filter(Expense.user_id == current_user.id)
    )

    if category_id is not None:
        query = query.filter(Expense.category_id == category_id)

    query = query.order_by(Expense.date.desc())

    if category_id is None:
        query = query.limit(10)

    expenses = query.all()

    result = []
    for expense, category_name, category_id in expenses:
        result.append({
            "id": expense.id,
            "amount": expense.amount,
            "date": expense.date,
            "description": expense.description,
            "category": category_name,
            "category_id": category_id,
            "auto_categorized": expense.auto_categorized,
        })

    return {"expenses": result}
