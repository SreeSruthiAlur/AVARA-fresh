from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Date, Text, JSON
from sqlalchemy.sql import func
from app.core.database import Base

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    category = Column(String(100), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    description = Column(String(500), nullable=True)
    payment_method = Column(String(50), default="UPI", nullable=False)  # "UPI", "Cash", "Card", "Net Banking", "Other"
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    month = Column(String(7), nullable=False, index=True)  # Format: "YYYY-MM"
    total_budget = Column(Float, nullable=False)
    category_limits = Column(JSON, default=dict, nullable=False)  # e.g. {"Food": 5000, "Shopping": 3000}
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
