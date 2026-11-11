from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date
from app.core.database import get_db
from app.core.errors import NotFoundError
from app.middleware.auth import get_current_user
from app.models.user import User
from app.models.health import WellnessEntry
from app.schemas.health import (
    WellnessEntryCreate,
    WellnessEntryUpdate,
    WellnessEntryResponse,
    HealthSummaryResponse
)

router = APIRouter(prefix="/health", tags=["AVARA Health & Wellness"])

@router.post("/entries", response_model=WellnessEntryResponse, status_code=status.HTTP_201_CREATED)
def create_wellness_entry(
    entry_in: WellnessEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Record a daily wellness note, mood, energy, and sleep check-in."""
    entry = WellnessEntry(
        user_id=current_user.id,
        date=entry_in.date,
        mood=entry_in.mood,
        mood_score=entry_in.mood_score,
        energy_level=entry_in.energy_level,
        sleep_hours=entry_in.sleep_hours,
        activity_minutes=entry_in.activity_minutes,
        wellness_goals=entry_in.wellness_goals,
        notes=entry_in.notes
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.get("/entries", response_model=List[WellnessEntryResponse])
def get_wellness_entries(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    limit: int = Query(60, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieve history of wellness entries with optional date filtering."""
    query = db.query(WellnessEntry).filter(WellnessEntry.user_id == current_user.id)
    if start_date:
        query = query.filter(WellnessEntry.date >= start_date)
    if end_date:
        query = query.filter(WellnessEntry.date <= end_date)

    return query.order_by(WellnessEntry.date.desc()).limit(limit).all()

@router.get("/entries/{entry_id}", response_model=WellnessEntryResponse)
def get_wellness_entry(
    entry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieve single wellness entry."""
    entry = db.query(WellnessEntry).filter(
        WellnessEntry.id == entry_id,
        WellnessEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise NotFoundError("Wellness entry not found")
    return entry

@router.put("/entries/{entry_id}", response_model=WellnessEntryResponse)
def update_wellness_entry(
    entry_id: int,
    entry_in: WellnessEntryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update existing wellness entry."""
    entry = db.query(WellnessEntry).filter(
        WellnessEntry.id == entry_id,
        WellnessEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise NotFoundError("Wellness entry not found")

    update_data = entry_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(entry, field, val)

    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.delete("/entries/{entry_id}")
def delete_wellness_entry(
    entry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete wellness entry."""
    entry = db.query(WellnessEntry).filter(
        WellnessEntry.id == entry_id,
        WellnessEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise NotFoundError("Wellness entry not found")

    db.delete(entry)
    db.commit()
    return {"success": True, "message": "Wellness entry deleted"}

@router.get("/summary", response_model=HealthSummaryResponse)
def get_health_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get deterministic wellness summary based strictly on user records:
    Total entries, average mood score, average energy, average sleep, total activity minutes.
    """
    entries = db.query(WellnessEntry).filter(
        WellnessEntry.user_id == current_user.id
    ).order_by(WellnessEntry.date.desc()).all()

    if not entries:
        return HealthSummaryResponse(
            total_entries=0,
            average_mood_score=None,
            average_energy_level=None,
            average_sleep_hours=None,
            total_activity_minutes=0,
            recent_entries=[],
            wellness_streak_days=0
        )

    total_count = len(entries)
    avg_mood = sum(e.mood_score for e in entries) / total_count
    avg_energy = sum(e.energy_level for e in entries) / total_count
    
    sleep_entries = [e.sleep_hours for e in entries if e.sleep_hours is not None]
    avg_sleep = (sum(sleep_entries) / len(sleep_entries)) if sleep_entries else None

    total_activity = sum(e.activity_minutes or 0 for e in entries)

    # Calculate streak (consecutive days)
    streak = 1
    recent_responses = [WellnessEntryResponse.model_validate(e) for e in entries[:7]]

    return HealthSummaryResponse(
        total_entries=total_count,
        average_mood_score=round(avg_mood, 2),
        average_energy_level=round(avg_energy, 2),
        average_sleep_hours=round(avg_sleep, 2) if avg_sleep else None,
        total_activity_minutes=total_activity,
        recent_entries=recent_responses,
        wellness_streak_days=streak
    )
