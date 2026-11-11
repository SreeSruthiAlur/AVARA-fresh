from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Date, Text
from sqlalchemy.sql import func
from app.core.database import Base

class WellnessEntry(Base):
    __tablename__ = "wellness_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    mood = Column(String(50), nullable=False)  # "Great", "Good", "Neutral", "Low", "Stressed"
    mood_score = Column(Integer, nullable=False)  # 1 to 5 scale
    energy_level = Column(Integer, nullable=False)  # 1 to 5 scale
    sleep_hours = Column(Float, nullable=True)
    activity_minutes = Column(Integer, nullable=True)
    wellness_goals = Column(String(255), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
