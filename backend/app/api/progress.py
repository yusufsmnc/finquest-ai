"""Progress + achievements for the authenticated user."""

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
from app.schemas.progress import ProgressOut, ProgressUpdate
from app.services.gamification import level_for_xp
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


# TODO(Faz 6): restrict client-writable authoritative fields.
# As it stands a client can PATCH its own xp / level / streak_count to any
# value, which contradicts "the backend owns authoritative state" (CLAUDE.md).
# The endpoint exists so the frontend can sync locally-earned progress, but the
# write should be narrowed (server-side reconciliation, or an append-only
# delta) rather than trusted verbatim. Documented as a known gap and covered by
# an xfail test in tests/test_progress_api.py — deliberately NOT fixed here.
@router.patch("/progress", response_model=ProgressOut)
def update_progress(
    payload: ProgressUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> ProgressOut:
    progress = _get_or_create_progress(db, user)
    if payload.xp is not None:
        progress.xp = payload.xp
        # Keep level authoritative/consistent with XP unless explicitly set.
        progress.level = level_for_xp(payload.xp)
    if payload.level is not None:
        progress.level = payload.level
    if payload.streak_count is not None:
        progress.streak_count = payload.streak_count
    db.commit()
    db.refresh(progress)
    return build_progress_out(db, progress)


@router.get("/achievements", response_model=list[AchievementOut])
def list_achievements(
    db: Session = Depends(get_db), user: User = Depends(get_current_user)
) -> list[Achievement]:
    return list(
        db.scalars(select(Achievement).where(Achievement.user_id == user.id)).all()
    )
