from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, datetime

class WellnessEntryCreate(BaseModel):
    date: date
    mood: str = Field(..., min_length=2, max_length=50)  # "Great", "Good", "Neutral", "Low", "Stressed"
    mood_score: int = Field(..., ge=1, le=5)
    energy_level: int = Field(..., ge=1, le=5)
    sleep_hours: Optional[float] = Field(None, ge=0.0, le=24.0)
    activity_minutes: Optional[int] = Field(None, ge=0, le=1440)
    wellness_goals: Optional[str] = None
    notes: Optional[str] = None

class WellnessEntryUpdate(BaseModel):
    mood: Optional[str] = Field(None, min_length=2, max_length=50)
    mood_score: Optional[int] = Field(None, ge=1, le=5)
    energy_level: Optional[int] = Field(None, ge=1, le=5)
    sleep_hours: Optional[float] = Field(None, ge=0.0, le=24.0)
    activity_minutes: Optional[int] = Field(None, ge=0, le=1440)
    wellness_goals: Optional[str] = None
    notes: Optional[str] = None

class WellnessEntryResponse(BaseModel):
    id: int
    user_id: int
    date: date
    mood: str
    mood_score: int
    energy_level: int
    sleep_hours: Optional[float] = None
    activity_minutes: Optional[int] = None
    wellness_goals: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class HealthSummaryResponse(BaseModel):
    total_entries: int
    average_mood_score: Optional[float] = None
    average_energy_level: Optional[float] = None
    average_sleep_hours: Optional[float] = None
    total_activity_minutes: int = 0
    recent_entries: List[WellnessEntryResponse] = []
    wellness_streak_days: int = 0
