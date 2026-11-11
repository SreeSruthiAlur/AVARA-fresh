import os
from typing import List
from pydantic import BaseModel, Field

class Settings(BaseModel):
    PROJECT_NAME: str = "AVARA Core API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str = Field(default_factory=lambda: os.getenv("AVARA_SECRET_KEY", "avara-dev-secret-key-teammate2-2026-secure-jwt"))
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Database (Postgres-compatible SQLAlchemy, defaults to SQLite for local dev)
    DATABASE_URL: str = Field(default_factory=lambda: os.getenv("DATABASE_URL", "sqlite:///./avara.db"))
    
    # Shared LLM Configuration (Configurable, Backend-only keys)
    LLM_PROVIDER: str = Field(default_factory=lambda: os.getenv("LLM_PROVIDER", "none"))  # "gemini" | "openai" | "none"
    LLM_API_KEY: str = Field(default_factory=lambda: os.getenv("LLM_API_KEY", ""))
    LLM_MODEL: str = Field(default_factory=lambda: os.getenv("LLM_MODEL", "gemini-3.8-flash"))
    LLM_TIMEOUT_SECONDS: int = 15
    LLM_MAX_RETRIES: int = 2
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]
    
    # Safety Helplines
    EMERGENCY_HELPLINE: str = "112 (National Emergency), 14416 (Tele-MANAS Mental Health Support India)"

settings = Settings()
