"""Declarative base.

Kept model-free to avoid circular imports (models import ``Base`` from here).
The full model registry is assembled in ``app.db.metadata``.
"""
from __future__ import annotations

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass
