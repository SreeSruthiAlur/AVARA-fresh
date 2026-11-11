from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON, Text
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    preferred_language = Column(String(20), default="te", nullable=False)  # "te" (Telugu), "en" (English), "tanglish"
    response_preference = Column(String(50), default="balanced", nullable=False)  # "balanced", "concise", "detailed"
    
    # Birth details stored as requested for future Teammate 1 integration
    birth_date = Column(String(50), nullable=True)
    birth_time = Column(String(50), nullable=True)
    birth_place = Column(String(255), nullable=True)
    
    # Privacy & account settings
    is_active = Column(Boolean, default=True, nullable=False)
    share_wellness_data = Column(Boolean, default=False, nullable=False)
    email_notifications = Column(Boolean, default=True, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
