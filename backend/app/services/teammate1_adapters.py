"""
Teammate 1 Adapter Implementations
===================================
Concrete subclasses that connect the Habits, Insights, and Astrology
integration endpoints to live data.

  - HabitsAdapter        — queries WellnessEntry records to derive habit
                           consistency stats, since AVARA currently tracks
                           wellness streaks (sleep, activity, mood) which
                           function as the primary daily habit signals.

  - InsightsAdapter      — synthesises cross-module observations from the
                           WellnessEntry history and Finance dashboard to
                           produce a weekly reflection + pattern list.

  - AstrologyAdapter     — wraps the user's stored birth details to return
                           a structured chart payload ready for downstream
                           interpretation. Planetary computation requires the
                           sweph C library which only runs in the Flutter/Dart
                           layer, so this adapter returns a 'ready' status with
                           the birth context so the Flutter client can pass it
                           to TeluguKundaliCalculator directly.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from datetime import date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.schemas.integrations import (
    AstrologyBirthChartRequest,
    AstrologyResponse,
    PlanetPosition,
    HabitsSummaryResponse,
    HabitContractItem,
    InsightsSummaryResponse,
    InsightObservation,
)

# =====================================================================
# ABSTRACT INTERFACES (unchanged — kept for type safety)
# =====================================================================

class BaseAstrologyAdapter(ABC):
    """Abstract contract for Astrology calculations (Teammate 1)."""
    @abstractmethod
    async def get_chart_and_interpretation(
        self, request: AstrologyBirthChartRequest
    ) -> AstrologyResponse:
        pass


class BaseHabitsAdapter(ABC):
    """Abstract contract for Habits tracking (Teammate 1)."""
    @abstractmethod
    async def get_user_habits_summary(
        self, user_id: int, db: Optional[Session] = None
    ) -> HabitsSummaryResponse:
        pass


class BaseInsightsAdapter(ABC):
    """Abstract contract for Insights synthesis (Teammate 1)."""
    @abstractmethod
    async def get_user_insights(
        self, user_id: int, db: Optional[Session] = None
    ) -> InsightsSummaryResponse:
        pass


# =====================================================================
# CONCRETE IMPLEMENTATIONS
# =====================================================================

class HabitsAdapter(BaseHabitsAdapter):
    """
    Derives habit-consistency data from the WellnessEntry table.

    Each unique tracked dimension (sleep logging, activity logging, mood
    check-in) is surfaced as a distinct habit item. Completion is measured
    by whether the user logged a value today. Streak = consecutive days
    with an entry.
    """

    async def get_user_habits_summary(
        self, user_id: int, db: Optional[Session] = None
    ) -> HabitsSummaryResponse:
        if db is None:
            # No DB session injected — return a lightweight ready response.
            return HabitsSummaryResponse(
                status="ready",
                provider_module="teammate_1_habits",
                total_active_habits=3,
                habits=[
                    HabitContractItem(id=1, title="Daily mood check-in",
                                      frequency="daily", target_days_per_week=7,
                                      current_streak=0, is_completed_today=False),
                    HabitContractItem(id=2, title="Log sleep hours",
                                      frequency="daily", target_days_per_week=7,
                                      current_streak=0, is_completed_today=False),
                    HabitContractItem(id=3, title="Physical activity",
                                      frequency="daily", target_days_per_week=5,
                                      current_streak=0, is_completed_today=False),
                ],
                completion_rate_pct=0.0,
                consistency_score=0.0,
                message="AVARA Habits: tracking mood, sleep, and activity daily.",
            )

        from app.models.health import WellnessEntry  # local import avoids circular

        today = date.today()
        entries_30 = (
            db.query(WellnessEntry)
            .filter(
                WellnessEntry.user_id == user_id,
                WellnessEntry.date >= today - timedelta(days=30),
            )
            .order_by(WellnessEntry.date.desc())
            .all()
        )

        entry_dates = {e.date for e in entries_30}
        today_entry = next((e for e in entries_30 if e.date == today), None)

        # Compute streak: consecutive days ending today
        streak = 0
        check = today
        while check in entry_dates:
            streak += 1
            check -= timedelta(days=1)

        mood_done = today_entry is not None
        sleep_done = today_entry is not None and today_entry.sleep_hours is not None
        activity_done = (
            today_entry is not None and
            today_entry.activity_minutes is not None and
            today_entry.activity_minutes > 0
        )

        habits = [
            HabitContractItem(id=1, title="Daily mood check-in",
                              frequency="daily", target_days_per_week=7,
                              current_streak=streak, is_completed_today=mood_done),
            HabitContractItem(id=2, title="Log sleep hours",
                              frequency="daily", target_days_per_week=7,
                              current_streak=streak if sleep_done else 0,
                              is_completed_today=sleep_done),
            HabitContractItem(id=3, title="Physical activity",
                              frequency="daily", target_days_per_week=5,
                              current_streak=streak if activity_done else 0,
                              is_completed_today=activity_done),
        ]

        completed_today = sum(1 for h in habits if h.is_completed_today)
        completion_pct = round((completed_today / len(habits)) * 100, 1)
        consistency = round(min(len(entry_dates) / 30.0, 1.0), 3)

        return HabitsSummaryResponse(
            status="ready",
            provider_module="teammate_1_habits",
            total_active_habits=len(habits),
            habits=habits,
            completion_rate_pct=completion_pct,
            consistency_score=consistency,
            message="Live habit data derived from wellness tracking.",
        )


class InsightsAdapter(BaseInsightsAdapter):
    """
    Synthesises cross-module observations from WellnessEntry history and
    Finance dashboard records to produce a weekly reflection summary.
    """

    async def get_user_insights(
        self, user_id: int, db: Optional[Session] = None
    ) -> InsightsSummaryResponse:
        if db is None:
            return InsightsSummaryResponse(
                status="ready",
                provider_module="teammate_1_insights",
                reflection_summary="Small steps are adding up.",
                key_observations=[
                    InsightObservation(
                        category="wellness",
                        title="Wellness",
                        observation="Start logging daily check-ins to unlock personalised insights.",
                        confidence=1.0,
                    ),
                ],
                practical_suggestions=[
                    "Log your mood and sleep daily to build richer insights.",
                    "Track at least one expense per day to see spending patterns.",
                ],
                message="AVARA Insights — data accumulates with daily tracking.",
            )

        from app.models.health import WellnessEntry
        from app.models.finance import Expense

        today = date.today()
        week_start = today - timedelta(days=7)

        # Last 7 days wellness
        wellness_week = (
            db.query(WellnessEntry)
            .filter(
                WellnessEntry.user_id == user_id,
                WellnessEntry.date >= week_start,
            )
            .all()
        )

        # Last 7 days expenses
        expenses_week = (
            db.query(Expense)
            .filter(
                Expense.user_id == user_id,
                Expense.date >= week_start,
            )
            .all()
        )

        observations: List[InsightObservation] = []
        suggestions: List[str] = []

        # --- Wellness observations -------------------------------------------
        if wellness_week:
            avg_mood = sum(e.mood_score for e in wellness_week) / len(wellness_week)
            avg_sleep = (
                sum(e.sleep_hours for e in wellness_week if e.sleep_hours)
                / max(1, sum(1 for e in wellness_week if e.sleep_hours))
            )
            total_activity = sum(
                e.activity_minutes or 0 for e in wellness_week
            )
            streak_days = len({e.date for e in wellness_week})

            observations.append(InsightObservation(
                category="wellness",
                title="Wellness",
                observation=(
                    f"You logged {streak_days}/7 days this week. "
                    f"Average mood: {avg_mood:.1f}/5."
                ),
                confidence=0.95,
            ))

            if avg_sleep >= 7.0:
                observations.append(InsightObservation(
                    category="routine",
                    title="Sleep",
                    observation=f"Great sleep this week — averaging {avg_sleep:.1f}h nightly.",
                    confidence=0.9,
                ))
            elif avg_sleep > 0:
                suggestions.append(
                    "Aim for 7–8 hours of sleep to boost energy and mood consistency."
                )

            if total_activity >= 150:
                observations.append(InsightObservation(
                    category="discipline",
                    title="Activity",
                    observation=f"{total_activity}min of activity logged — above the weekly target.",
                    confidence=0.9,
                ))
            else:
                suggestions.append(
                    "Try to log at least 30 minutes of activity each day."
                )
        else:
            suggestions.append("Start your daily mood check-in to unlock weekly insights.")

        # --- Finance observations ---------------------------------------------
        if expenses_week:
            total_spend = sum(e.amount for e in expenses_week)
            top_cat = max(
                set(e.category for e in expenses_week),
                key=lambda c: sum(
                    e.amount for e in expenses_week if e.category == c
                ),
            )
            observations.append(InsightObservation(
                category="spending",
                title="Spending",
                observation=(
                    f"You spent ₹{total_spend:.0f} this week. "
                    f"Top category: {top_cat}."
                ),
                confidence=0.95,
            ))
        else:
            suggestions.append("Log expenses daily to see personalised spending patterns.")

        # --- Astrology link hint ----------------------------------------------
        observations.append(InsightObservation(
            category="astrology_link",
            title="Astrology Themes",
            observation="Open AVARA Astrology to explore how planetary influences relate to your week.",
            confidence=0.7,
        ))

        # --- Reflection headline ---------------------------------------------
        if len(observations) >= 3:
            reflection = "Small steps are adding up — here's what your week reveals."
        elif wellness_week:
            reflection = "You've been consistent. Keep building the habit."
        else:
            reflection = "Start tracking today to unlock your first weekly reflection."

        if not suggestions:
            suggestions.append("Consistency is key — keep logging daily to see long-term patterns.")

        return InsightsSummaryResponse(
            status="ready",
            provider_module="teammate_1_insights",
            reflection_summary=reflection,
            key_observations=observations,
            practical_suggestions=suggestions,
            message="Live insights synthesised from AVARA wellness and finance data.",
        )


class AstrologyAdapter(BaseAstrologyAdapter):
    """
    Returns the user's stored birth details in a structured 'ready' payload.

    The sweph planetary computation runs in the Flutter/Dart layer via
    TeluguKundaliCalculator (which uses the Swiss Ephemeris C library).
    This adapter therefore acts as a data bridge: it retrieves the user's
    birth_date, birth_time, and birth_place from the user profile so the
    Flutter client has everything it needs to call the math engine, and
    returns a status='ready' AstrologyResponse with those birth details
    embedded in the interpretation_summary for easy parsing.

    When Teammate 1 later adds a server-side Python ephemeris wrapper,
    the concrete planetary_positions list can be filled here.
    """

    async def get_chart_and_interpretation(
        self, request: AstrologyBirthChartRequest
    ) -> AstrologyResponse:
        summary = (
            f"Birth details received — Date: {request.birth_date}, "
            f"Time: {request.birth_time}, Place: {request.birth_place}. "
            f"Language preference: {request.preferred_language}. "
            "Planetary computation is performed client-side via "
            "TeluguKundaliCalculator (Swiss Ephemeris). "
            "Pass these coordinates to calculateFullKundali() in the Flutter layer."
        )
        return AstrologyResponse(
            status="ready",
            provider_module="teammate_1_astrology",
            chart_calculated=False,  # True once server-side sweph wrapper lands
            sun_sign=None,
            moon_sign=None,
            ascendant=None,
            planetary_positions=[],
            interpretation_summary=summary,
            evidence_notes=(
                "Vedic sidereal positions computed using Lahiri ayanamsa via sweph 2.10.3. "
                "See lib/telugu_kundali.dart → calculateFullKundali() for the computation pipeline."
            ),
            disclaimer=(
                "Astrological interpretations are for personal reflection and do not "
                "constitute predictions or guarantees."
            ),
        )


# =====================================================================
# FACTORY SINGLETONS — point at the concrete implementations
# =====================================================================

astrology_adapter: BaseAstrologyAdapter = AstrologyAdapter()
habits_adapter: BaseHabitsAdapter = HabitsAdapter()
insights_adapter: BaseInsightsAdapter = InsightsAdapter()
