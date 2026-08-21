from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AchievementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    code: str
    unlocked_at: datetime
