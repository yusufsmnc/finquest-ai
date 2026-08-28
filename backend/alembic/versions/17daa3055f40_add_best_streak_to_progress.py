"""add best_streak to progress

Revision ID: 17daa3055f40
Revises: 9781aa6f123e
Create Date: 2026-08-28 10:52:32.753678
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "17daa3055f40"
down_revision: str | None = "9781aa6f123e"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Added in two steps rather than one: a NOT NULL column needs a value for
    # every existing row, and the right value is not the default.
    op.add_column(
        "progress",
        sa.Column("best_streak", sa.Integer(), nullable=False, server_default="0"),
    )

    # Backfill. Without this every existing user would report a best streak of
    # zero while their current streak is positive — "best" lower than "current"
    # is visibly wrong, and the profile shows both side by side. The current
    # streak is the only lower bound the history gives us for free.
    op.execute("UPDATE progress SET best_streak = streak_count")

    # The server default existed only to satisfy NOT NULL during the add. The
    # application sets the value from here on, so drop it and keep exactly one
    # source of truth.
    op.alter_column("progress", "best_streak", server_default=None)


def downgrade() -> None:
    op.drop_column("progress", "best_streak")
