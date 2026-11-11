from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.profile import router as profile_router
from app.api.v1.chat import router as chat_router
from app.api.v1.finance import router as finance_router
from app.api.v1.health import router as health_router
from app.api.v1.astrologers import router as astrologers_router
from app.api.v1.integrations import router as integrations_router

api_router = APIRouter()

api_router.include_router(auth_router)
api_router.include_router(profile_router)
api_router.include_router(chat_router)
api_router.include_router(finance_router)
api_router.include_router(health_router)
api_router.include_router(astrologers_router)
api_router.include_router(integrations_router)
