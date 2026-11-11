from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime

class AstrologerResponse(BaseModel):
    id: int
    name: str
    title: str
    bio: str
    areas_of_expertise: List[str]
    languages: List[str]
    experience_years: int
    consultation_fee: float
    rating: float
    is_demo: bool
    available_slots: List[str]

    class Config:
        from_attributes = True

class BookingCreate(BaseModel):
    astrologer_id: int
    booking_date: date
    time_slot: str = Field(..., min_length=2)
    consultation_topic: str = Field(..., min_length=3, max_length=255)
    notes: Optional[str] = None

class BookingResponse(BaseModel):
    id: int
    user_id: int
    astrologer_id: int
    astrologer_name: Optional[str] = None
    booking_date: date
    time_slot: str
    consultation_topic: str
    status: str
    notes: Optional[str] = None
    is_demo: bool
    created_at: datetime

    class Config:
        from_attributes = True
