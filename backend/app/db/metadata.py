"""Imports every model so ``Base.metadata`` is fully populated.

Import this module (not ``app.db.base``) whenever you need the complete schema
— e.g. Alembic autogenerate. Keeping the model imports here avoids the circular
import between models and the declarative base.
"""
from __future__ import annotations

from app.db.base import Base
from app.models.achievement import Achievement  # noqa: F401
from app.models.progress import Progress  # noqa: F401
from app.models.scenario_history import ScenarioHistory  # noqa: F401
from app.models.user import User  # noqa: F401

__all__ = ["Base", "User", "Progress", "Achievement", "ScenarioHistory"]