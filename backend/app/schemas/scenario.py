from __future__ import annotations

from typing import Literal

from pydantic import BaseModel

from app.schemas.progress import ProgressOut


class DecisionRequest(BaseModel):
    choice: str
    # The frontend reports the outcome; the backend applies authoritative XP.
    correct: bool


class DecisionResponse(BaseModel):
    # Event names mirror the immutable frontend event contract (CLAUDE.md).
    result: Literal["DECISION_CORRECT", "DECISION_WRONG"]
    xp_delta: int
    events: list[str]
    progress: ProgressOut
