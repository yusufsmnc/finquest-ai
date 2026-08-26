"""Authoritative gamification rules.

The frontend only *renders* XP/level/streak; the backend owns the numbers
(CLAUDE.md: "NO computation in UI"). Events emitted here reuse the immutable
frontend event contract so the client can drive its animations directly.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime

from app.models.progress import Progress

XP_CORRECT = 20
XP_WRONG = -10
XP_PER_LEVEL = 100


def level_for_xp(xp: int) -> int:
    """Deterministic level curve: one level per 100 XP, starting at level 1."""
    return 1 + max(xp, 0) // XP_PER_LEVEL


@dataclass
class DecisionOutcome:
    result: str
    xp_delta: int
    events: list[str] = field(default_factory=list)


def apply_decision(progress: Progress, correct: bool) -> DecisionOutcome:
    """Mutate ``progress`` in place for a scenario decision and return events."""
    events: list[str] = ["DECISION_MADE"]
    old_level = progress.level

    if correct:
        xp_delta = XP_CORRECT
        progress.xp = max(0, progress.xp + xp_delta)
        progress.streak_count += 1
        events += ["DECISION_CORRECT", "XP_GAINED", "STREAK_UPDATED"]
        result = "DECISION_CORRECT"
    else:
        xp_delta = XP_WRONG
        progress.xp = max(0, progress.xp + xp_delta)
        progress.streak_count = 0
        events += ["DECISION_WRONG", "XP_LOST", "STREAK_UPDATED"]
        result = "DECISION_WRONG"

    new_level = level_for_xp(progress.xp)
    if new_level != old_level:
        progress.level = new_level
        if new_level > old_level:
            events.append("LEVEL_UP")

    progress.last_active = datetime.now(UTC)
    return DecisionOutcome(result=result, xp_delta=xp_delta, events=events)
