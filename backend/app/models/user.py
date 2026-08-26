from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.achievement import Achievement
    from app.models.progress import Progress
    from app.models.scenario_history import ScenarioHistory


def _utcnow() -> datetime:
    return datetime.now(UTC)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True, nullable=False
    )
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )

    progress: Mapped[Progress] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    achievements: Mapped[list[Achievement]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    scenario_history: Mapped[list[ScenarioHistory]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
