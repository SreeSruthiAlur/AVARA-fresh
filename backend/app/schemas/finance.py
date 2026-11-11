from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, datetime

class ExpenseCreate(BaseModel):
    amount: float = Field(..., gt=0)
    category: str = Field(..., min_length=1, max_length=100)
    date: date
    description: Optional[str] = None
    payment_method: str = Field(default="UPI", max_length=50)

class ExpenseUpdate(BaseModel):
    amount: Optional[float] = Field(None, gt=0)
    category: Optional[str] = Field(None, min_length=1, max_length=100)
    date: Optional[date] = None
    description: Optional[str] = None
    payment_method: Optional[str] = None

class ExpenseResponse(BaseModel):
    id: int
    user_id: int
    amount: float
    category: str
    date: date
    description: Optional[str] = None
    payment_method: str
    created_at: datetime

    class Config:
        from_attributes = True

class BudgetCreate(BaseModel):
    month: str = Field(..., pattern=r"^\d{4}-\d{2}$")  # YYYY-MM
    total_budget: float = Field(..., gt=0)
    category_limits: Dict[str, float] = Field(default_factory=dict)

class BudgetUpdate(BaseModel):
    total_budget: Optional[float] = Field(None, gt=0)
    category_limits: Optional[Dict[str, float]] = None

class BudgetResponse(BaseModel):
    id: int
    user_id: int
    month: str
    total_budget: float
    category_limits: Dict[str, float]
    created_at: datetime

    class Config:
        from_attributes = True

class CategorySpending(BaseModel):
    category: str
    amount: float
    percentage: float
    budget_limit: Optional[float] = None
    is_over_budget: bool = False

class FinanceDashboardResponse(BaseModel):
    current_month: str
    total_spending_month: float
    total_budget_month: Optional[float] = None
    remaining_budget_month: Optional[float] = None
    budget_utilization_pct: Optional[float] = None
    threshold_alert: Optional[str] = None
    category_breakdown: List[CategorySpending] = []
    recent_transactions: List[ExpenseResponse] = []
    total_transactions_count: int

class AIAssistantQueryRequest(BaseModel):
    query: str = Field(..., min_length=2)

class AIAssistantQueryResponse(BaseModel):
    query: str
    deterministic_answer: str
    detected_intent: str
    calculation_details: Dict[str, Any] = {}
    is_live_llm_used: bool = False
    safety_note: Optional[str] = None
