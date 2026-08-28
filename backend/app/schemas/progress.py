from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    xp: int
    level: int
    streak_count: int
    # Stored, not derived: the highest streak ever reached.
    best_streak: int = 0
    last_active: datetime | None
    # Derived from scenario_history, not stored columns. The frontend renders
    # these; it does not recompute them, so a reload cannot disagree with the
    # server about how many decisions were made or how many were right.
    decisions_made: int = 0
    decisions_today: int = 0
    correct_decisions: int = 0
    #: correct_decisions / decisions_made, 0.0 when nothing has been decided.
    accuracy: float = 0.0
    #: Gross XP ever earned. Deliberately not `xp`, which is the net balance
    #: after wrong answers deduct from it and is floored at zero.
    xp_earned_total: int = 0
