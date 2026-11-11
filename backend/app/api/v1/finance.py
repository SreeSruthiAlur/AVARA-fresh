from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import extract, desc, asc
from typing import List, Optional
from datetime import date
from app.core.database import get_db
from app.core.errors import NotFoundError, AppError
from app.middleware.auth import get_current_user
from app.models.user import User
from app.models.finance import Expense, Budget
from app.schemas.finance import (
    ExpenseCreate,
    ExpenseUpdate,
    ExpenseResponse,
    BudgetCreate,
    BudgetUpdate,
    BudgetResponse,
    FinanceDashboardResponse,
    AIAssistantQueryRequest,
    AIAssistantQueryResponse
)
from app.services.finance_service import FinanceService

router = APIRouter(prefix="/finance", tags=["AVARA Finance"])

# ---------------- EXPENSES ----------------

@router.post("/expenses", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_expense(
    exp_in: ExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a new expense record."""
    expense = Expense(
        user_id=current_user.id,
        amount=exp_in.amount,
        category=exp_in.category,
        date=exp_in.date,
        description=exp_in.description,
        payment_method=exp_in.payment_method
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense

@router.get("/expenses", response_model=List[ExpenseResponse])
def get_expenses(
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search description or category"),
    start_date: Optional[date] = Query(None, description="Filter from date"),
    end_date: Optional[date] = Query(None, description="Filter to date"),
    sort_by: str = Query("date", description="'date' or 'amount'"),
    order: str = Query("desc", description="'asc' or 'desc'"),
    limit: int = Query(100, ge=1, le=500),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """List, search, filter, and sort user expenses."""
    query = db.query(Expense).filter(Expense.user_id == current_user.id)

    if category:
        query = query.filter(Expense.category == category)

    if search:
        query = query.filter(
            (Expense.description.ilike(f"%{search}%")) | (Expense.category.ilike(f"%{search}%"))
        )

    if start_date:
        query = query.filter(Expense.date >= start_date)

    if end_date:
        query = query.filter(Expense.date <= end_date)

    # Sorting
    sort_column = Expense.amount if sort_by == "amount" else Expense.date
    if order == "asc":
        query = query.order_by(asc(sort_column))
    else:
        query = query.order_by(desc(sort_column))

    return query.limit(limit).all()

@router.get("/expenses/{expense_id}", response_model=ExpenseResponse)
def get_expense_by_id(
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get single expense record."""
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise NotFoundError("Expense record not found")
    return expense

@router.put("/expenses/{expense_id}", response_model=ExpenseResponse)
def update_expense(
    expense_id: int,
    exp_in: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Edit existing expense record."""
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise NotFoundError("Expense record not found")

    update_data = exp_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(expense, field, val)

    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense

@router.delete("/expenses/{expense_id}")
def delete_expense(
    expense_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete an expense record."""
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise NotFoundError("Expense record not found")

    db.delete(expense)
    db.commit()
    return {"success": True, "message": "Expense successfully deleted"}

# ---------------- BUDGETS ----------------

@router.post("/budgets", response_model=BudgetResponse)
def set_monthly_budget(
    b_in: BudgetCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Set or update monthly and category-level budget."""
    existing = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.month == b_in.month
    ).first()

    if existing:
        existing.total_budget = b_in.total_budget
        existing.category_limits = b_in.category_limits
        db.add(existing)
        db.commit()
        db.refresh(existing)
        return existing

    budget = Budget(
        user_id=current_user.id,
        month=b_in.month,
        total_budget=b_in.total_budget,
        category_limits=b_in.category_limits
    )
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget

@router.get("/budgets/{month}", response_model=BudgetResponse)
def get_monthly_budget(
    month: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get budget for specified month (YYYY-MM)."""
    budget = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.month == month
    ).first()
    if not budget:
        raise NotFoundError(f"No budget set for month {month}")
    return budget

# ---------------- DASHBOARD & AI ASSISTANT ----------------

@router.get("/dashboard", response_model=FinanceDashboardResponse)
def get_finance_dashboard(
    month: Optional[str] = Query(None, description="Month in YYYY-MM format"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get complete deterministic Finance dashboard summary:
    Total spending, category breakdown, budget utilization, threshold alert, recent transactions.
    """
    return FinanceService.get_dashboard_summary(db=db, user_id=current_user.id, target_month=month)

@router.post("/ai-assistant", response_model=AIAssistantQueryResponse)
def query_finance_assistant(
    req: AIAssistantQueryRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deterministic AI Finance Assistant answering queries about user's own recorded data.
    """
    result = FinanceService.query_finance_assistant(
        db=db,
        user_id=current_user.id,
        query=req.query,
        language=current_user.preferred_language
    )
    return AIAssistantQueryResponse(
        query=result["query"],
        deterministic_answer=result["deterministic_answer"],
        detected_intent=result["detected_intent"],
        calculation_details=result.get("calculation_details", {}),
        is_live_llm_used=result.get("is_live_llm_used", False)
    )
