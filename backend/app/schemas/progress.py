from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    xp: int
    level: int
    streak_count: int
    last_active: datetime | None
    # Derived counts (computed from scenario_history, not stored columns).
    # Used by the frontend to render mission/achievement progress bars.
    decisions_made: int = 0
    decisions_today: int = 0


class ProgressUpdate(BaseModel):
    """Partial update of authoritative progress (PATCH /me/progress)."""

    xp: int | None = Field(default=None, ge=0)
    level: int | None = Field(default=None, ge=1)
    streak_count: int | None = Field(default=None, ge=0)
