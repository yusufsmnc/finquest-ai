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
    old_xp = progress.xp

    if correct:
        progress.xp = max(0, progress.xp + XP_CORRECT)
        progress.streak_count += 1
        # High-water mark: streak_count resets on a wrong answer, this does not.
        # `or 0` because a Progress built in the request and not yet flushed has
        # no column default applied — the attribute is still None at this point.
        if progress.streak_count > (progress.best_streak or 0):
            progress.best_streak = progress.streak_count
        events += ["DECISION_CORRECT", "XP_GAINED", "STREAK_UPDATED"]
        result = "DECISION_CORRECT"
    else:
        progress.xp = max(0, progress.xp + XP_WRONG)
        progress.streak_count = 0
        events += ["DECISION_WRONG", "XP_LOST", "STREAK_UPDATED"]
        result = "DECISION_WRONG"

    # The delta the client animates is the change that was actually applied,
    # not the nominal reward: XP is clamped at zero, so a wrong answer at 5 XP
    # costs 5, not XP_WRONG's 10. The frontend derives its XP_LOST/XP_GAINED
    # amount from this value whenever it has no previous snapshot to diff
    # against, so a nominal delta would animate XP the user never had.
    xp_delta = progress.xp - old_xp

    new_level = level_for_xp(progress.xp)
    if new_level != old_level:
        progress.level = new_level
        if new_level > old_level:
            events.append("LEVEL_UP")

    progress.last_active = datetime.now(UTC)
    return DecisionOutcome(result=result, xp_delta=xp_delta, events=events)
