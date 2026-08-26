"""Guards that the Alembic migrations and the SQLAlchemy models stay in step.

CLAUDE.md forbids hand-editing the schema: every change goes through a
migration. Nothing enforced that until now — the migration was only ever
exercised by hand, in the cluster.

In CI these run against the Postgres service *after* ``alembic upgrade head``,
so the comparison is against a genuinely migrated database. Locally the schema
comes from ``create_all`` and the drift check is trivially satisfied; the head
and naming checks below are meaningful either way.
"""

from __future__ import annotations

from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import inspect
from sqlalchemy.engine import Engine

from app.db.metadata import Base


def _script_directory() -> ScriptDirectory:
    return ScriptDirectory.from_config(Config("alembic.ini"))


def test_the_migration_history_has_exactly_one_head():
    """Two heads mean `alembic upgrade head` is ambiguous and will fail."""
    assert len(_script_directory().get_heads()) == 1


def test_every_revision_is_reachable_from_the_head():
    script = _script_directory()
    head = script.get_current_head()

    walked = {revision.revision for revision in script.walk_revisions("base", head)}

    assert walked == {revision.revision for revision in script.walk_revisions()}


def test_every_model_table_exists_in_the_database(engine: Engine):
    present = set(inspect(engine).get_table_names())

    missing = set(Base.metadata.tables) - present
    assert not missing, (
        f"tables declared on the models but absent from the DB: {missing}"
    )


def test_every_model_column_exists_in_the_database(engine: Engine):
    inspector = inspect(engine)

    drift: dict[str, set[str]] = {}
    for name, table in Base.metadata.tables.items():
        actual = {column["name"] for column in inspector.get_columns(name)}
        missing = {column.name for column in table.columns} - actual
        if missing:
            drift[name] = missing

    assert not drift, f"columns on the models with no counterpart in the DB: {drift}"


def test_the_four_expected_tables_are_declared():
    """The data model from CLAUDE.md, locked in."""
    assert set(Base.metadata.tables) == {
        "users",
        "progress",
        "achievements",
        "scenario_history",
    }
