"""Helpers for the derived decision counts exposed on progress responses."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.progress import Progress
from app.models.scenario_history import ScenarioHistory
from app.schemas.progress import ProgressOut


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


def build_progress_out(db: Session, progress: Progress) -> ProgressOut:
    """ProgressOut enriched with the derived decision counts."""
    return ProgressOut(
        xp=progress.xp,
        level=progress.level,
        streak_count=progress.streak_count,
        last_active=progress.last_active,
        decisions_made=count_decisions(db, progress.user_id),
        decisions_today=count_decisions_today(db, progress.user_id),
    )
