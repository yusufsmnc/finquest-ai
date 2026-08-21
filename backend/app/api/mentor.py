"""Mentor endpoint — the only place the app talks to an LLM.

Always answers 200 with a usable message: when the LLM is unavailable the
service degrades to the pre-seeded messages (see ``services/mentor.py``). No
provider error, and certainly no API key, is ever surfaced to the client.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.mentor import MentorRequest, MentorResponse
from app.services import mentor

router = APIRouter(tags=["mentor"])


@router.post("/mentor", response_model=MentorResponse)
def post_mentor(
    payload: MentorRequest,
    user: User = Depends(get_current_user),
) -> MentorResponse:
    """Turn the caller's game context into a short, supportive nudge.

    Called per decision or on demand — never on every micro-event; the
    per-user throttle in the service is the backstop for that.
    """
    result = mentor.generate(payload, user_key=str(user.id))
    return MentorResponse(
        message=result.message,
        context=payload.context,
        source=result.source,
    )