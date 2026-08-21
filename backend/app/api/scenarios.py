"""Scenario decision endpoint — applies authoritative gamification."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.progress import Progress
from app.models.scenario_history import ScenarioHistory
from app.models.user import User
from app.schemas.scenario import DecisionRequest, DecisionResponse
from app.services.gamification import apply_decision

router = APIRouter(prefix="/scenarios", tags=["scenarios"])


@router.post("/{scenario_id}/decision", response_model=DecisionResponse)
def make_decision(
    scenario_id: str,
    payload: DecisionRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> DecisionResponse:
    progress = user.progress
    if progress is None:
        progress = Progress(xp=0, level=1, streak_count=0)
        user.progress = progress
        db.add(progress)

    outcome = apply_decision(progress, payload.correct)

    db.add(
        ScenarioHistory(
            user_id=user.id,
            scenario_id=scenario_id,
            choice=payload.choice,
            result=outcome.result,
            xp_delta=outcome.xp_delta,
        )
    )
    db.commit()
    db.refresh(progress)

    return DecisionResponse(
        result=outcome.result,
        xp_delta=outcome.xp_delta,
        events=outcome.events,
        progress=progress,
    )
