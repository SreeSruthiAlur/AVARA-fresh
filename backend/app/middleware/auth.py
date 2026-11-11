from fastapi import Depends, Header, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import decode_access_token
from app.core.errors import UnauthorizedError, ForbiddenError
from app.models.user import User
from typing import Optional

async def get_current_user(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> User:
    """Validate Bearer token and return authenticated User record."""
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedError("Missing or invalid Authorization header. Expected 'Bearer <token>'")

    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload:
        raise UnauthorizedError("Access token is invalid or has expired")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedError("Invalid token payload")

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise UnauthorizedError("User associated with token no longer exists")

    if not user.is_active:
        raise ForbiddenError("User account has been deactivated")

    return user
