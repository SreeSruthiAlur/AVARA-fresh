from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserRegister(BaseModel):
    email: str = Field(..., pattern=r"^[\w\.\-]+@[\w\.\-]+\.\w+$")
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)
    full_name: Optional[str] = None
    preferred_language: str = Field(default="te", pattern="^(te|en|tanglish)$")
    birth_date: Optional[str] = None
    birth_time: Optional[str] = None
    birth_place: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    user_id: int
    email: str
    username: str
    preferred_language: str

class UserProfileResponse(BaseModel):
    id: int
    email: str
    username: str
    full_name: Optional[str] = None
    preferred_language: str
    response_preference: str
    birth_date: Optional[str] = None
    birth_time: Optional[str] = None
    birth_place: Optional[str] = None
    share_wellness_data: bool
    email_notifications: bool
    created_at: datetime

    class Config:
        from_attributes = True

class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    preferred_language: Optional[str] = Field(None, pattern="^(te|en|tanglish)$")
    response_preference: Optional[str] = None
    birth_date: Optional[str] = None
    birth_time: Optional[str] = None
    birth_place: Optional[str] = None
    share_wellness_data: Optional[bool] = None
    email_notifications: Optional[bool] = None

class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=6, max_length=100)
