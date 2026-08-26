"""DTOs for ``POST /mentor``."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

from app.services.mentor_messages import MentorContext


class RecentDecision(BaseModel):
    """One recent decision, as the frontend saw it."""

    scenario_id: str = Field(max_length=64)
    # Mirrors the event contract: the frontend never invents other values.
    result: Literal["DECISION_CORRECT", "DECISION_WRONG"]
    category: str | None = Field(default=None, max_length=48)


class MentorRequest(BaseModel):
    """User context the mentor personalises its nudge from.

    Everything is optional-with-defaults so a bare ``{}`` still yields a
    sensible message — the mentor must never 422 the client into a broken UI.
    """

    context: MentorContext = MentorContext.IDLE
    xp: int = Field(default=0, ge=0, le=10_000_000)
    level: int = Field(default=1, ge=1, le=1000)
    streak: int = Field(default=0, ge=0, le=10_000)
    # Bounded so a client cannot inflate the prompt (cost + injection surface).
    recent_decisions: list[RecentDecision] = Field(default_factory=list, max_length=5)
    # Rotates the static pool so repeated fallbacks don't read identically.
    message_index: int = Field(default=0, ge=0, le=1_000_000)


class MentorResponse(BaseModel):
    message: str
    context: MentorContext
    # Lets the client (and the tests) see which path produced the text.
    # "ai" = live LLM, "fallback" = pre-seeded message, "cache" = recent reuse.
    source: Literal["ai", "fallback", "cache"]
