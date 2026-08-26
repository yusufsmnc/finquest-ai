"""Shared test fixtures: an isolated database, a client, and auth helpers.

Two things this file guarantees, in order of importance:

1. **The development database is never touched.** ``app.core.config.settings``
   is built at import time from the environment (and the git-ignored
   ``backend/.env``, which points ``DATABASE_URL`` at ``./finquest.db``). The
   environment is therefore rewritten *before* any ``app`` module is imported,
   and an assertion below fails loudly if the dev file ever leaks through.
2. **Tests do not see each other's rows.** Each test runs inside a transaction
   that is rolled back afterwards, so ordering never matters and nothing has to
   be cleaned up by hand.

The schema comes from ``Base.metadata`` with ``checkfirst=True``: locally that
creates the tables in a throwaway SQLite file, while in CI the Postgres service
has already been migrated by ``alembic upgrade head`` and this becomes a no-op.
"""

from __future__ import annotations

import itertools
import os
import tempfile
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest

# ── Environment isolation (must precede every `app` import) ────────────────

#: CI points this at the Postgres service container; locally it is unset and a
#: throwaway SQLite file is used instead. Either way it is never the dev DB.
TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL", "").strip()
if not TEST_DATABASE_URL:
    _tmp_dir = tempfile.mkdtemp(prefix="finquest-tests-")
    TEST_DATABASE_URL = f"sqlite:///{Path(_tmp_dir, 'test.db').as_posix()}"

os.environ["DATABASE_URL"] = TEST_DATABASE_URL
os.environ["ENVIRONMENT"] = "test"
os.environ["JWT_SECRET"] = "test-signing-key-not-a-real-secret"
# Empty on purpose: the mentor must resolve to its static fallback, so no test
# can ever reach a paid endpoint even if a real key sits in the local .env.
os.environ["OPENAI_API_KEY"] = ""
os.environ["CORS_ORIGINS"] = "http://localhost:5000,http://localhost:8080"

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine, event  # noqa: E402
from sqlalchemy.engine import Engine  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.db.metadata import Base  # noqa: E402
from app.db.session import get_db  # noqa: E402
from app.main import app  # noqa: E402

# The safety net. If the env rewrite above ever stops working (an import order
# change, a stray `settings` cache), this fails the whole run instead of
# silently writing test rows into the developer's real database.
assert settings.database_url == TEST_DATABASE_URL, (
    f"settings picked up {settings.database_url!r} instead of the test database"
)
assert "finquest.db" not in settings.database_url, (
    "refusing to run: the tests are pointed at the development database"
)

DEFAULT_PASSWORD = "correct-horse-battery"


# ── Database ───────────────────────────────────────────────────────────────


@pytest.fixture(scope="session")
def engine() -> Iterator[Engine]:
    eng = create_engine(
        TEST_DATABASE_URL,
        connect_args=(
            {"check_same_thread": False}
            if TEST_DATABASE_URL.startswith("sqlite")
            else {}
        ),
        future=True,
    )

    if TEST_DATABASE_URL.startswith("sqlite"):
        # pysqlite opens an implicit transaction of its own and does not emit
        # BEGIN where SQLAlchemy expects it, which breaks the SAVEPOINT the
        # rollback fixture relies on. Take the driver out of the loop and issue
        # BEGIN ourselves. FK enforcement is off by default in SQLite too —
        # switching it on keeps cascade behaviour honest against PostgreSQL.
        @event.listens_for(eng, "connect")
        def _sqlite_connect(dbapi_connection, _record):  # pragma: no cover
            dbapi_connection.isolation_level = None
            dbapi_connection.execute("PRAGMA foreign_keys=ON")

        @event.listens_for(eng, "begin")
        def _sqlite_begin(connection):  # pragma: no cover
            connection.exec_driver_sql("BEGIN")

    # No-op in CI, where alembic has already built the schema.
    Base.metadata.create_all(eng, checkfirst=True)
    yield eng
    eng.dispose()


@pytest.fixture
def db_session(engine: Engine) -> Iterator[Session]:
    """A session whose writes are discarded when the test ends.

    The outer transaction is never committed. ``create_savepoint`` lets the
    application call ``db.commit()`` as usual — those commits land on a
    savepoint inside our transaction, so the endpoint under test behaves
    exactly as it would in production while the rows still disappear.
    """
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection, join_transaction_mode="create_savepoint")
    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


# ── HTTP ───────────────────────────────────────────────────────────────────


@pytest.fixture
def client(db_session: Session) -> Iterator[TestClient]:
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def register(client: TestClient) -> Callable[..., dict[str, str]]:
    """Factory: create a fresh user, return its ``Authorization`` header.

    Emails are generated, so a test that needs two independent users just calls
    it twice and never has to invent unique addresses.
    """
    counter = itertools.count(1)

    def _register(
        email: str | None = None, password: str = DEFAULT_PASSWORD
    ) -> dict[str, str]:
        address = email or f"user{next(counter)}@example.com"
        created = client.post(
            "/auth/register", json={"email": address, "password": password}
        )
        assert created.status_code == 201, created.text
        token = client.post(
            "/auth/login", json={"email": address, "password": password}
        ).json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    return _register


@pytest.fixture
def auth(register: Callable[..., dict[str, str]]) -> dict[str, str]:
    """The common case: headers for one already-registered user."""
    return register()
