import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base, SessionLocal
from app.core.errors import AppError, app_error_handler, unhandled_exception_handler
from app.api.v1.api import api_router
from app.api.v1.astrologers import seed_demo_astrologers_if_empty
# Import all models to ensure metadata registration
import app.models

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("avara.main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB tables
    logger.info("Initializing AVARA SQLite/Postgres database tables...")
    Base.metadata.create_all(bind=engine)
    
    # Seed initial demo astrologers
    db = SessionLocal()
    try:
        seed_demo_astrologers_if_empty(db)
        logger.info("Database initialized successfully with demonstration profiles.")
    finally:
        db.close()
        
    yield
    logger.info("Shutting down AVARA Core API.")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="AVARA Core Multilingual AI Backend (Teammate 2 Implementation)",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

# Include versioned API router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/health", tags=["Health Check"])
def health_check():
    """System and LLM provider status check."""
    from app.services.llm_service import LLMService
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "llm_provider": settings.LLM_PROVIDER,
        "live_ai_configured": LLMService.is_configured(),
        "database": "sqlite_local" if settings.DATABASE_URL.startswith("sqlite") else "postgresql",
        "teammate_1_interfaces": "active"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
