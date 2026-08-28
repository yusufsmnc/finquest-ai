"""Helpers for the derived decision counts exposed on progress responses."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.progress import Progress
from app.models.scenario_history import ScenarioHistory
from app.schemas.progress import ProgressOut

#: The value `apply_decision` writes for a correct answer.
CORRECT_RESULT = "DECISION_CORRECT"


def count_decisions(db: Session, user_id: int) -> int:
    return (
        db.scalar(
            select(func.count())
            .select_from(ScenarioHistory)
            .where(ScenarioHistory.user_id == user_id)
        )
        or 0
    )


def count_decisions_today(db: Session, user_id: int) -> int:
    # UTC day boundary — portable across SQLite/PostgreSQL (Python-side bound).
    start_of_day = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    return (
        db.scalar(
            select(func.count())
            .select_from(ScenarioHistory)
            .where(
                ScenarioHistory.user_id == user_id,
                ScenarioHistory.created_at >= start_of_day,
            )
        )
        or 0
    )


def count_correct_decisions(db: Session, user_id: int) -> int:
    return (
        db.scalar(
            select(func.count())
            .select_from(ScenarioHistory)
            .where(
                ScenarioHistory.user_id == user_id,
                ScenarioHistory.result == CORRECT_RESULT,
            )
        )
        or 0
    )


def sum_xp_earned(db: Session, user_id: int) -> int:
    """Gross XP ever earned: the positive deltas only.

    Not the same as ``progress.xp``, which is the net balance after wrong
    answers deduct from it and is floored at zero. A user who earned 100 and
    lost 40 has 60 XP but earned 100, and the profile says "Total XP Earned".
    """
    return (
        db.scalar(
            select(func.coalesce(func.sum(ScenarioHistory.xp_delta), 0)).where(
                ScenarioHistory.user_id == user_id,
                ScenarioHistory.xp_delta > 0,
            )
        )
        or 0
    )


def build_progress_out(db: Session, progress: Progress) -> ProgressOut:
    """ProgressOut enriched with everything derived from scenario_history."""
    decisions_made = count_decisions(db, progress.user_id)
    correct = count_correct_decisions(db, progress.user_id)
    return ProgressOut(
        xp=progress.xp,
        level=progress.level,
        streak_count=progress.streak_count,
        best_streak=progress.best_streak,
        last_active=progress.last_active,
        decisions_made=decisions_made,
        decisions_today=count_decisions_today(db, progress.user_id),
        correct_decisions=correct,
        accuracy=(correct / decisions_made) if decisions_made else 0.0,
        xp_earned_total=sum_xp_earned(db, progress.user_id),
    )
