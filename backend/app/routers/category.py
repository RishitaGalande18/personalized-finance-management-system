from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryResponse
from app.utils.dependencies import get_db
from app.utils.auth_dependencies import get_current_user
from app.models.user import User

router = APIRouter(
    prefix="/category",
    tags=["Category"]
)


# ---------------- ADD CATEGORY ----------------

@router.post(
    "",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED
)
def add_category(
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_category = Category(
        name=category.name,
        budget_limit=category.budget_limit,
        user_id=current_user.id
    )

    db.add(new_category)
    db.commit()
    db.refresh(new_category)

    return new_category


class CategoryLimitUpdate(BaseModel):
    category_id: int
    limit: Optional[Decimal] = None


@router.post(
    "/limit",
    response_model=CategoryResponse,
    status_code=status.HTTP_200_OK,
)
def update_category_limit(
    limit_request: CategoryLimitUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    category = db.query(Category).filter(
        Category.id == limit_request.category_id,
        Category.user_id == current_user.id,
    ).first()

    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    category.budget_limit = limit_request.limit
    db.commit()
    db.refresh(category)

    return category

@router.get("/")
def get_categories(
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    return db.query(Category).filter(Category.user_id == current_user.id).all()