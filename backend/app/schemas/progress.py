from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


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
