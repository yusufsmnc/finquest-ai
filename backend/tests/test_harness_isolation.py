"""The guarantees the test harness itself makes.

If these fail, every other result in the suite is suspect: the tests would be
sharing state, or worse, writing into the developer's real database.
"""

from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user import User


def test_the_suite_never_points_at_the_development_database():
    assert "finquest.db" not in settings.database_url


def test_the_mentor_cannot_reach_a_paid_endpoint():
    """No key in the test environment, whatever sits in the local .env."""
    assert settings.openai_api_key == ""


def test_each_test_starts_from_an_empty_users_table(db_session: Session):
    """Paired with the test below: proves the rollback actually happens."""
    assert db_session.scalar(select(func.count()).select_from(User)) == 0


def test_rows_written_by_a_test_do_not_survive_it(client: TestClient, register):
    register()
    register()

    # The assertion that matters is in the previous test, which runs against
    # the same database and still sees zero rows.
    assert True


def test_the_users_table_is_still_empty_afterwards(db_session: Session):
    assert db_session.scalar(select(func.count()).select_from(User)) == 0
