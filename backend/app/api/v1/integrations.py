from fastapi import APIRouter, Depends
from typing import Dict, Any
from app.middleware.auth import get_current_user
from app.models.user import User
from app.schemas.integrations import (
    AstrologyBirthChartRequest,
    AstrologyResponse,
    HabitsSummaryResponse,
    InsightsSummaryResponse
)
from app.services.teammate1_adapters import (
    astrology_adapter,
    habits_adapter,
    insights_adapter
)

router = APIRouter(prefix="/integrations", tags=["Teammate 1 Integration Contracts"])

@router.get("/contracts")
def get_integration_contracts():
    """
    Returns API specifications and instructions for Teammate 1.
    Explains how to connect Astrology, Habits, and Insights modules.
    """
    return {
        "status": "ready_for_teammate_1",
        "author": "Teammate 2",
        "supported_shared_services": [
            "FastAPI routing and versioned APIs (/api/v1)",
            "JWT Authentication & User Session Management",
            "Telugu, English, and Tanglish Language Detection",
            "Pre-routing Safety Classification & Emergency Helplines",
            "Automatic Intent Routing to Teammate 1 endpoints",
            "Shared LLM Service (Configurable Gemini / OpenAI / Fallbacks)",
            "SQLite / PostgreSQL Database Engine with SQLAlchemy"
        ],
        "contracts": {
            "astrology": {
                "endpoint": "POST /api/v1/integrations/astrology/chart",
                "request_schema": "AstrologyBirthChartRequest (birth_date, birth_time, birth_place, preferred_language)",
                "response_schema": "AstrologyResponse (sun_sign, moon_sign, planetary_positions, interpretation_summary, evidence_notes)",
                "how_to_implement": "Subclass BaseAstrologyAdapter in app/services/teammate1_adapters.py and connect your calculation engine."
            },
            "habits": {
                "endpoint": "GET /api/v1/integrations/habits/summary",
                "response_schema": "HabitsSummaryResponse (habits, completion_rate_pct, consistency_score)",
                "how_to_implement": "Subclass BaseHabitsAdapter in app/services/teammate1_adapters.py and connect your habit tracking models."
            },
            "insights": {
                "endpoint": "GET /api/v1/integrations/insights/summary",
                "response_schema": "InsightsSummaryResponse (reflection_summary, key_observations, practical_suggestions)",
                "how_to_implement": "Subclass BaseInsightsAdapter in app/services/teammate1_adapters.py and connect your synthesis engine."
            }
        }
    }

@router.post("/astrology/chart", response_model=AstrologyResponse)
async def get_astrology_chart(
    req: AstrologyBirthChartRequest,
    current_user: User = Depends(get_current_user)
):
    """Astrology integration endpoint: calculates birth chart and interpretation via adapter."""
    return await astrology_adapter.get_chart_and_interpretation(req)

@router.get("/habits/summary", response_model=HabitsSummaryResponse)
async def get_habits_summary(
    current_user: User = Depends(get_current_user)
):
    """Habits integration endpoint: retrieves habit consistency statistics via adapter."""
    return await habits_adapter.get_user_habits_summary(current_user.id)

@router.get("/insights/summary", response_model=InsightsSummaryResponse)
async def get_insights_summary(
    current_user: User = Depends(get_current_user)
):
    """Insights integration endpoint: retrieves reflection observations via adapter."""
    return await insights_adapter.get_user_insights(current_user.id)
