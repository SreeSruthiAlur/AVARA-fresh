import re
from datetime import date, datetime
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from app.models.finance import Expense, Budget
from app.schemas.finance import FinanceDashboardResponse, CategorySpending, ExpenseResponse

DEFAULT_CATEGORIES = [
    "Food",
    "Transportation",
    "Shopping",
    "Education",
    "Entertainment",
    "Healthcare",
    "Bills",
    "Other"
]

class FinanceService:
    """
    Deterministic Finance calculation engine and AI Finance Assistant.
    Operates strictly on actual user database records.
    Never fabricates financial figures.
    """

    @staticmethod
    def get_dashboard_summary(db: Session, user_id: int, target_month: Optional[str] = None) -> FinanceDashboardResponse:
        """
        Calculate complete financial summary deterministically for the given user and month (YYYY-MM).
        """
        today = date.today()
        month_str = target_month or today.strftime("%Y-%m")
        year, month = map(int, month_str.split("-"))

        # Query all expenses for user in this month
        expenses = db.query(Expense).filter(
            Expense.user_id == user_id,
            extract('year', Expense.date) == year,
            extract('month', Expense.date) == month
        ).order_by(Expense.date.desc()).all()

        total_spent = sum(e.amount for e in expenses)

        # Query budget for this month
        budget_record = db.query(Budget).filter(
            Budget.user_id == user_id,
            Budget.month == month_str
        ).first()

        total_budget = budget_record.total_budget if budget_record else None
        remaining_budget = (total_budget - total_spent) if total_budget is not None else None
        utilization_pct = round((total_spent / total_budget) * 100, 1) if (total_budget and total_budget > 0) else None

        # Determine threshold alerts
        threshold_alert = None
        if total_budget and total_budget > 0:
            if total_spent > total_budget:
                threshold_alert = f"Alert: You have exceeded your monthly budget by ₹{round(total_spent - total_budget, 2)}!"
            elif utilization_pct >= 80:
                threshold_alert = f"Warning: You have utilized {utilization_pct}% of your monthly budget."

        # Category-wise breakdown
        category_sums: Dict[str, float] = {}
        for exp in expenses:
            category_sums[exp.category] = category_sums.get(exp.category, 0.0) + exp.amount

        cat_breakdown = []
        cat_limits = budget_record.category_limits if budget_record and budget_record.category_limits else {}
        for cat, amt in sorted(category_sums.items(), key=lambda x: x[1], reverse=True):
            pct = round((amt / total_spent * 100), 1) if total_spent > 0 else 0.0
            limit = cat_limits.get(cat)
            is_over = (limit is not None and amt > limit)
            cat_breakdown.append(CategorySpending(
                category=cat,
                amount=round(amt, 2),
                percentage=pct,
                budget_limit=limit,
                is_over_budget=is_over
            ))

        # Recent 5 transactions
        recent_txs = [
            ExpenseResponse.model_validate(e) for e in expenses[:5]
        ]

        # Total transaction count across all time
        total_tx_count = db.query(Expense).filter(Expense.user_id == user_id).count()

        return FinanceDashboardResponse(
            current_month=month_str,
            total_spending_month=round(total_spent, 2),
            total_budget_month=round(total_budget, 2) if total_budget else None,
            remaining_budget_month=round(remaining_budget, 2) if remaining_budget else None,
            budget_utilization_pct=utilization_pct,
            threshold_alert=threshold_alert,
            category_breakdown=cat_breakdown,
            recent_transactions=recent_txs,
            total_transactions_count=total_tx_count
        )

    @classmethod
    def query_finance_assistant(cls, db: Session, user_id: int, query: str, language: str = "english") -> Dict[str, Any]:
        """
        Deterministic AI Finance Assistant answering queries against real DB data.
        Never invents transactions or balances.
        """
        today = date.today()
        current_month_str = today.strftime("%Y-%m")
        dashboard = cls.get_dashboard_summary(db, user_id, current_month_str)

        q_lower = query.lower()

        # 1. Total spent this month
        if any(w in q_lower for w in ["how much", "total", "spent", "spending", "entha", "kharchu", "karchu", "ఖర్చు"]):
            if any(w in q_lower for w in ["this month", "current month", "eeroju", "month", "నెల"]):
                if dashboard.total_spending_month == 0:
                    ans = "మీరు ఈ నెలలో ఇప్పటివరకు ఎలాంటి ఖర్చులు నమోదు చేయలేదు." if language in ["telugu", "tanglish"] else "You have not recorded any expenses for the current month yet."
                else:
                    ans = (
                        f"మీరు ఈ నెల ({current_month_str}) లో మొత్తం ₹{dashboard.total_spending_month:.2f} ఖర్చు చేశారు."
                        if language in ["telugu", "tanglish"] else
                        f"Your total verified spending for {current_month_str} is ₹{dashboard.total_spending_month:.2f}."
                    )
                return {
                    "query": query,
                    "deterministic_answer": ans,
                    "detected_intent": "monthly_total_query",
                    "calculation_details": {
                        "month": current_month_str,
                        "total_spent": dashboard.total_spending_month,
                        "transaction_count": len(dashboard.recent_transactions)
                    },
                    "is_live_llm_used": False
                }

        # 2. Highest spending category
        if any(w in q_lower for w in ["highest", "maximum", "most", "top category", "ekkuva", "ఎక్కువ"]):
            if not dashboard.category_breakdown:
                ans = "ఖర్చుల రికార్డులు లేవు కాబట్టి కేటగిరీ వివరాలు అందుబాటులో లేవు." if language in ["telugu", "tanglish"] else "No expense records found to determine the highest category."
            else:
                top = dashboard.category_breakdown[0]
                ans = (
                    f"మీరు అత్యధికంగా ఖర్చు చేసిన కేటగిరీ '{top.category}' — మొత్తం ₹{top.amount:.2f} ({top.percentage}%)."
                    if language in ["telugu", "tanglish"] else
                    f"Your highest spending category this month is '{top.category}' with ₹{top.amount:.2f} ({top.percentage}% of total)."
                )
            return {
                "query": query,
                "deterministic_answer": ans,
                "detected_intent": "highest_category_query",
                "calculation_details": {
                    "categories": [c.model_dump() for c in dashboard.category_breakdown]
                },
                "is_live_llm_used": False
            }

        # 3. Budget remaining
        if any(w in q_lower for w in ["budget", "remaining", "balance", "migilindi", "మిగిలింది"]):
            if dashboard.total_budget_month is None:
                ans = "మీరు ఈ నెలకు బడ్జెట్ సెట్ చేయలేదు. బడ్జెట్ స్క్రీన్ లో సెట్ చేసుకోండి." if language in ["telugu", "tanglish"] else "You have not set a budget for this month yet. You can set one in the Budgets section."
            else:
                ans = (
                    f"ఈ నెలకు మీ మొత్తం బడ్జెట్ ₹{dashboard.total_budget_month:.2f}. "
                    f"ఖర్చు: ₹{dashboard.total_spending_month:.2f}. మిగిలిన బ్యాలెన్స్: ₹{dashboard.remaining_budget_month:.2f} ({dashboard.budget_utilization_pct}% వినియోగం)."
                    if language in ["telugu", "tanglish"] else
                    f"For {current_month_str}, your total budget is ₹{dashboard.total_budget_month:.2f}. "
                    f"You have spent ₹{dashboard.total_spending_month:.2f}, leaving ₹{dashboard.remaining_budget_month:.2f} remaining ({dashboard.budget_utilization_pct}% utilized)."
                )
            return {
                "query": query,
                "deterministic_answer": ans,
                "detected_intent": "budget_balance_query",
                "calculation_details": {
                    "budget": dashboard.total_budget_month,
                    "spent": dashboard.total_spending_month,
                    "remaining": dashboard.remaining_budget_month,
                    "utilization_pct": dashboard.budget_utilization_pct
                },
                "is_live_llm_used": False
            }

        # Default summary
        ans = (
            f"ఈ నెల సారాంశం: మొత్తం ఖర్చు ₹{dashboard.total_spending_month:.2f}. "
            f"రికార్డుల సంఖ్య: {dashboard.total_transactions_count}."
            if language in ["telugu", "tanglish"] else
            f"Finance Summary for {current_month_str}: Total spending is ₹{dashboard.total_spending_month:.2f} across your recorded transactions."
        )
        return {
            "query": query,
            "deterministic_answer": ans,
            "detected_intent": "general_finance_query",
            "calculation_details": {"month": current_month_str, "total_spent": dashboard.total_spending_month},
            "is_live_llm_used": False
        }
