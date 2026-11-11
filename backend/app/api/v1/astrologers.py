from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from app.core.database import get_db
from app.core.errors import NotFoundError, AppError
from app.middleware.auth import get_current_user
from app.models.user import User
from app.models.astrologer import Astrologer, ConsultationBooking
from app.schemas.astrologer import AstrologerResponse, BookingCreate, BookingResponse

router = APIRouter(prefix="/astrologers", tags=["AVARA Astrologers"])

DEMO_PROFILES = [
    {
        "name": "Dr. V. Sharma (Demonstration Profile)",
        "title": "Vedic Astrologer & Muhurtha Consultant",
        "bio": "Specializes in Vedic birth chart guidance, muhurtha selection, and career growth reflections. (Sample profile for demonstration)",
        "areas_of_expertise": ["Vedic Astrology", "Career Guidance", "Muhurtha"],
        "languages": ["Telugu", "English", "Hindi"],
        "experience_years": 14,
        "consultation_fee": 750.0,
        "rating": 4.9,
        "is_demo": True,
        "available_slots": ["10:00 AM", "02:00 PM", "05:00 PM", "07:30 PM"]
    },
    {
        "name": "Smt. Annapurna Devi (Demonstration Profile)",
        "title": "KP Astrology & Family Wellbeing Specialist",
        "bio": "Experienced in KP Astrology, life transitions, and personal growth consultations in Telugu and English. (Sample profile for demonstration)",
        "areas_of_expertise": ["KP Astrology", "Personal Wellbeing", "Relationship Harmony"],
        "languages": ["Telugu", "English"],
        "experience_years": 10,
        "consultation_fee": 500.0,
        "rating": 4.8,
        "is_demo": True,
        "available_slots": ["11:00 AM", "03:30 PM", "06:00 PM"]
    }
]

def seed_demo_astrologers_if_empty(db: Session):
    count = db.query(Astrologer).count()
    if count == 0:
        for p in DEMO_PROFILES:
            astro = Astrologer(**p)
            db.add(astro)
        db.commit()

@router.get("", response_model=List[AstrologerResponse])
def list_astrologers(
    language: Optional[str] = Query(None),
    expertise: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """
    List verified consultation astrologers.
    Demonstration profiles are explicitly marked with is_demo=True.
    """
    seed_demo_astrologers_if_empty(db)
    astrologers = db.query(Astrologer).all()
    
    # Filter in-memory for JSON list fields
    filtered = astrologers
    if language:
        filtered = [a for a in filtered if any(language.lower() in l.lower() for l in a.languages)]
    if expertise:
        filtered = [a for a in filtered if any(expertise.lower() in e.lower() for e in a.areas_of_expertise)]

    return filtered

@router.get("/{astrologer_id}", response_model=AstrologerResponse)
def get_astrologer(astrologer_id: int, db: Session = Depends(get_db)):
    """Retrieve single astrologer profile with available time slots."""
    astro = db.query(Astrologer).filter(Astrologer.id == astrologer_id).first()
    if not astro:
        raise NotFoundError("Astrologer profile not found")
    return astro

@router.post("/bookings", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def book_consultation(
    booking_in: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit a consultation booking request."""
    astro = db.query(Astrologer).filter(Astrologer.id == booking_in.astrologer_id).first()
    if not astro:
        raise NotFoundError("Astrologer not found")

    booking = ConsultationBooking(
        user_id=current_user.id,
        astrologer_id=booking_in.astrologer_id,
        booking_date=booking_in.booking_date,
        time_slot=booking_in.time_slot,
        consultation_topic=booking_in.consultation_topic,
        notes=booking_in.notes,
        status="requested",
        is_demo=astro.is_demo
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)

    resp = BookingResponse.model_validate(booking)
    resp.astrologer_name = astro.name
    return resp

@router.get("/bookings/me", response_model=List[BookingResponse])
def get_my_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieve all consultation bookings for the authenticated user."""
    bookings = db.query(ConsultationBooking).filter(
        ConsultationBooking.user_id == current_user.id
    ).order_by(ConsultationBooking.booking_date.desc()).all()

    result = []
    for b in bookings:
        astro = db.query(Astrologer).filter(Astrologer.id == b.astrologer_id).first()
        b_resp = BookingResponse.model_validate(b)
        b_resp.astrologer_name = astro.name if astro else "Unknown"
        result.append(b_resp)

    return result

@router.delete("/bookings/{booking_id}")
def cancel_booking(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel a consultation booking."""
    booking = db.query(ConsultationBooking).filter(
        ConsultationBooking.id == booking_id,
        ConsultationBooking.user_id == current_user.id
    ).first()
    if not booking:
        raise NotFoundError("Booking not found")

    booking.status = "cancelled"
    db.add(booking)
    db.commit()
    return {"success": True, "message": "Booking consultation cancelled"}
