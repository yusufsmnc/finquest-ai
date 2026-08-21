"""Authoritative achievement evaluation.

Achievements are backend-owned: criteria are evaluated from the user's
authoritative state (xp / level / streak / total decisions) and persisted to the
``achievements`` table. Unlocks are permanent and idempotent — once earned, a
code is never removed and never inserted twice (guarded by the unique
``user_id + code`` constraint and an explicit existence check).
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.achievement import Achievement

# code -> (metric, threshold). Metrics mirror what the frontend renders.
CRITERIA: dict[str, tuple[str, int]] = {
    # streak (current streak_count)
    "streak_first": ("streak", 1),
    "streak_3": ("streak", 3),
    "streak_5": ("streak", 5),
    "streak_10": ("streak", 10),
    # cumulative xp
    "xp_100": ("xp", 100),
    "xp_500": ("xp", 500),
    "xp_1000": ("xp", 1000),
    "xp_2000": ("xp", 2000),
    # total decisions made
    "decisions_5": ("decisions", 5),
    "decisions_25": ("decisions", 25),
    "decisions_100": ("decisions", 100),
    # level reached
    "level_2": ("level", 2),
    "level_5": ("level", 5),
    "level_10": ("level", 10),
}


def _earned_codes(xp: int, level: int, streak: int, decisions: int) -> set[str]:
    metrics = {
        "xp": xp,
        "level": level,
        "streak": streak,
        "decisions": decisions,
    }
    return {
        code
        for code, (metric, threshold) in CRITERIA.items()
        if metrics[metric] >= threshold
    }


def sync_achievements(
    db: Session,
    *,
    user_id: int,
    xp: int,
    level: int,
    streak: int,
    decisions: int,
) -> list[str]:
    """Insert any newly-earned achievements and return the new codes.

    Does not commit — the caller owns the transaction boundary.
    """
    earned = _earned_codes(xp, level, streak, decisions)
    if not earned:
        return []

    existing = set(
        db.scalars(
            select(Achievement.code).where(Achievement.user_id == user_id)
        )
    )
    new_codes = sorted(earned - existing)
    for code in new_codes:
        db.add(Achievement(user_id=user_id, code=code))
    return new_codes