from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Date, Text, Boolean, JSON
from sqlalchemy.sql import func
from app.core.database import Base

class Astrologer(Base):
    __tablename__ = "astrologers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    title = Column(String(255), nullable=False)
    bio = Column(Text, nullable=False)
    areas_of_expertise = Column(JSON, default=list, nullable=False)  # e.g. ["Vedic Astrology", "Career", "Muhurtha"]
    languages = Column(JSON, default=list, nullable=False)  # e.g. ["Telugu", "English"]
    experience_years = Column(Integer, default=5, nullable=False)
    consultation_fee = Column(Float, default=500.0, nullable=False)
    rating = Column(Float, default=4.8, nullable=False)
    is_demo = Column(Boolean, default=True, nullable=False)  # Clearly labels demo profile
    available_slots = Column(JSON, default=list, nullable=False)  # e.g. ["10:00 AM", "02:00 PM", "05:00 PM"]
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

class ConsultationBooking(Base):
    __tablename__ = "consultation_bookings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    astrologer_id = Column(Integer, ForeignKey("astrologers.id", ondelete="CASCADE"), nullable=False, index=True)
    booking_date = Column(Date, nullable=False)
    time_slot = Column(String(50), nullable=False)
    consultation_topic = Column(String(255), nullable=False)
    status = Column(String(50), default="requested", nullable=False)  # "requested", "confirmed", "cancelled"
    notes = Column(Text, nullable=True)
    is_demo = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
