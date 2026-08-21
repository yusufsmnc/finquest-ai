from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    xp: int
    level: int
    streak_count: int
    last_active: datetime | None


class ProgressUpdate(BaseModel):
    """Partial update of authoritative progress (PATCH /me/progress)."""

    xp: int | None = Field(default=None, ge=0)
    level: int | None = Field(default=None, ge=1)
    streak_count: int | None = Field(default=None, ge=0)
