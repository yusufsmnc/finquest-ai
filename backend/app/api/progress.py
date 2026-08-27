"""Progress + achievements for the authenticated user — read-only.

There is deliberately no write endpoint here. Progress is authoritative state
that the backend owns (CLAUDE.md), and the only thing allowed to move it is a
scenario decision: ``POST /scenarios/{id}/decision`` applies the rules in
``app.services.gamification`` and returns the result. A client that could PATCH
its own xp/level/streak would make every number in the system a suggestion.

A ``PATCH /me/progress`` did exist and accepted whatever it was sent. Nothing
ever called it — the Flutter client only reads this path — so it was removed in
Faz 6b rather than narrowed to an endpoint whose sole valid request is a no-op.
The path still answers GET, so a PATCH now gets 405 Method Not Allowed.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.achievement import Achievement
from app.models.progress import Progress
from app.models.user import User
from app.schemas.achievement import AchievementOut
from app.schemas.progress import ProgressOut
from app.services.progress_stats import build_progress_out

router = APIRouter(prefix="/me", tags=["me"])


def _get_or_create_progress(db: Session, user: User) -> Progress:
    if user.progress is None:
        user.progress = Progress(xp=0, level=1, streak_count=0)
        db.add(user.progress)
        db.commit()
        db.refresh(user.progress)
    return user.progress


@router.get("/progress", response_model=ProgressOut)
def get_progress(
    db: Session = Depends(get_db), user: User = Depends(get_current_user)
) -> ProgressOut:
    return build_progress_out(db, _get_or_create_progress(db, user))


@router.get("/achievements", response_model=list[AchievementOut])
def list_achievements(
    db: Session = Depends(get_db), user: User = Depends(get_current_user)
) -> list[Achievement]:
    return list(
        db.scalars(select(Achievement).where(Achievement.user_id == user.id)).all()
    )
