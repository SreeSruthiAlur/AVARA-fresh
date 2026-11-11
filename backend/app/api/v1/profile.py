from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_password_hash, verify_password
from app.core.errors import AppError, NotFoundError, UnauthorizedError
from app.middleware.auth import get_current_user
from app.models.user import User
from app.schemas.user import UserProfileResponse, UserProfileUpdate, PasswordUpdate

router = APIRouter(prefix="/profile", tags=["Profile & Settings"])

@router.get("/me", response_model=UserProfileResponse)
def get_my_profile(current_user: User = Depends(get_current_user)):
    """Fetch profile of currently authenticated user."""
    return current_user

@router.patch("/me", response_model=UserProfileResponse)
def update_my_profile(
    profile_in: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update profile fields, preferred language, or response preferences."""
    update_data = profile_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)

    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/change-password")
def change_password(
    pwd_in: PasswordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user password with current password verification."""
    if not verify_password(pwd_in.current_password, current_user.hashed_password):
        raise UnauthorizedError("Current password is incorrect")

    current_user.hashed_password = get_password_hash(pwd_in.new_password)
    db.add(current_user)
    db.commit()
    return {"success": True, "message": "Password successfully updated"}

@router.delete("/me")
def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Deactivate or permanently delete authenticated user account."""
    db.delete(current_user)
    db.commit()
    return {"success": True, "message": "Account successfully deleted"}
