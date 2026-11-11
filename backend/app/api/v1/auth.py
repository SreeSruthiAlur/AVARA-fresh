from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_password_hash, verify_password, create_access_token
from app.core.errors import ConflictError, UnauthorizedError, AppError
from app.core.config import settings
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, TokenResponse, UserProfileResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    """Register a new user account and return JWT access token."""
    # Check if email or username already exists
    existing_email = db.query(User).filter(User.email == user_in.email.lower()).first()
    if existing_email:
        raise ConflictError("An account with this email address already exists")

    existing_username = db.query(User).filter(User.username == user_in.username).first()
    if existing_username:
        raise ConflictError("This username is already taken")

    user = User(
        email=user_in.email.lower(),
        username=user_in.username,
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name,
        preferred_language=user_in.preferred_language,
        birth_date=user_in.birth_date,
        birth_time=user_in.birth_time,
        birth_place=user_in.birth_place,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(subject=user.id)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in_seconds=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        email=user.email,
        username=user.username,
        preferred_language=user.preferred_language
    )

@router.post("/login", response_model=TokenResponse)
def login(creds: UserLogin, db: Session = Depends(get_db)):
    """Authenticate user with email/username and password."""
    # Search by email or username
    user = db.query(User).filter(
        (User.email == creds.email.lower()) | (User.username == creds.email)
    ).first()

    if not user or not verify_password(creds.password, user.hashed_password):
        raise UnauthorizedError("Invalid email or password")

    if not user.is_active:
        raise UnauthorizedError("This account has been disabled")

    token = create_access_token(subject=user.id)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in_seconds=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        email=user.email,
        username=user.username,
        preferred_language=user.preferred_language
    )

@router.post("/logout")
def logout():
    """Client-side token disposal confirmation."""
    return {"success": True, "message": "Successfully logged out. Client token should be removed."}
