"""Logging configuration: LOG_LEVEL is honoured and the startup line is emitted.

Both were broken in the same way — nothing installed a handler, so the root
logger kept its default WARNING, `LOG_LEVEL` from the ConfigMap was read into
`Settings` and then ignored, and every `logger.info` in the application went
nowhere. The startup diagnostic was invisible in `kubectl logs` for all of
Faz 5.
"""

from __future__ import annotations

import logging
import sys

import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.logging import (
    DEFAULT_LEVEL,
    THIRD_PARTY_LOGGERS,
    configure_logging,
    resolve_level,
)
from app.main import app


@pytest.fixture
def configure(caplog):
    """Apply a configuration, keeping pytest's capture handler attached.

    ``dictConfig`` replaces the root logger's handler list, which removes the
    handler ``caplog`` installed for this test. Re-adding it is what keeps the
    fixture working across a reconfiguration.
    """

    def _configure(level: str) -> str:
        applied = configure_logging(level)
        logging.getLogger().addHandler(caplog.handler)
        return applied

    yield _configure
    configure_logging(settings.log_level)


# ── Levels ─────────────────────────────────────────────────────────────────


def test_info_level_emits_info_but_not_debug(configure, caplog):
    configure("info")
    log = logging.getLogger("finquest")

    log.debug("a debug line")
    log.info("an info line")

    assert "an info line" in caplog.text
    assert "a debug line" not in caplog.text


def test_debug_level_emits_debug_as_well(configure, caplog):
    configure("debug")
    log = logging.getLogger("finquest")

    log.debug("a debug line")
    log.info("an info line")

    assert "a debug line" in caplog.text
    assert "an info line" in caplog.text


def test_the_level_reaches_the_module_loggers_too(configure, caplog):
    """`app.services.mentor` uses `__name__`, not the `finquest` namespace."""
    configure("debug")

    logging.getLogger("app.services.mentor").debug("mentor debug line")

    assert "mentor debug line" in caplog.text


def test_warning_level_silences_info(configure, caplog):
    configure("warning")
    log = logging.getLogger("finquest")

    log.info("an info line")
    log.warning("a warning line")

    assert "an info line" not in caplog.text
    assert "a warning line" in caplog.text


# ── The configured level comes from settings ───────────────────────────────


def test_the_default_comes_from_settings(monkeypatch):
    monkeypatch.setattr(settings, "log_level", "debug")

    assert configure_logging() == "DEBUG"

    configure_logging(settings.log_level)


@pytest.mark.parametrize(
    ("configured", "expected"),
    [
        ("info", "INFO"),
        ("INFO", "INFO"),
        ("  debug  ", "DEBUG"),
        ("warning", "WARNING"),
        ("", DEFAULT_LEVEL),
        (None, DEFAULT_LEVEL),
        ("chatty", DEFAULT_LEVEL),
    ],
)
def test_level_strings_are_normalised(configured, expected):
    assert resolve_level(configured) == expected


def test_an_unusable_level_does_not_crash_the_app(configure, caplog):
    """A typo in the ConfigMap must degrade to INFO, not take the pod down."""
    assert configure("not-a-level") == DEFAULT_LEVEL

    logging.getLogger("finquest").info("still logging")

    assert "still logging" in caplog.text


# ── Handler shape ──────────────────────────────────────────────────────────


def test_records_go_to_stdout(configure):
    """Containers collect stdout; stderr or a file would hide them."""
    configure("info")

    handlers = logging.getLogger().handlers
    streams = [h.stream for h in handlers if isinstance(h, logging.StreamHandler)]
    assert sys.stdout in streams


def test_uvicorn_shares_the_one_handler(configure):
    """Server and application lines in one format, printed once."""
    configure("info")

    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        log = logging.getLogger(name)
        assert log.handlers == [], f"{name} kept its own handler"
        assert log.propagate is True


# ── The startup diagnostic ─────────────────────────────────────────────────


def test_the_startup_line_is_emitted(caplog, db_session):
    """The one line that says what the backend actually connected to."""
    caplog.set_level(logging.INFO, logger="finquest")

    with TestClient(app):
        pass

    assert "FinQuest backend starting" in caplog.text


def test_the_startup_line_reports_the_environment_and_backend(caplog, db_session):
    caplog.set_level(logging.INFO, logger="finquest")

    with TestClient(app):
        pass

    line = next(
        record.getMessage()
        for record in caplog.records
        if "FinQuest backend starting" in record.getMessage()
    )
    assert "environment=test" in line
    assert f"db={settings.database_backend}" in line
    assert "mentor=static-fallback" in line, "no key in tests, so no paid path"


def test_the_startup_line_leaks_no_credential(caplog, db_session):
    caplog.set_level(logging.INFO, logger="finquest")

    with TestClient(app):
        pass

    assert settings.database_url not in caplog.text
    assert settings.jwt_secret not in caplog.text


# ── Third-party loggers stay quiet ─────────────────────────────────────────


def test_debug_does_not_switch_on_the_openai_sdk(configure, caplog):
    """The reason this pin exists.

    The OpenAI SDK logs every outbound request at DEBUG, and that body is the
    mentor prompt — the learner's xp, level, streak and recent decisions. Since
    `LOG_LEVEL: debug` is a one-word ConfigMap edit, raising the application's
    verbosity must not raise the SDK's with it.
    """
    configure("debug")

    logging.getLogger("finquest").debug("application debug line")
    logging.getLogger("openai._base_client").debug("Request options: {...prompt...}")

    assert "application debug line" in caplog.text
    assert "prompt" not in caplog.text


@pytest.mark.parametrize("name", THIRD_PARTY_LOGGERS)
def test_third_party_loggers_are_pinned_at_warning(configure, caplog, name):
    configure("debug")

    logging.getLogger(name).debug("noisy debug")
    logging.getLogger(name).info("chatty info")
    logging.getLogger(name).warning("something actually wrong")

    assert "noisy debug" not in caplog.text
    assert "chatty info" not in caplog.text
    assert "something actually wrong" in caplog.text, "real problems must survive"


def test_the_pin_covers_the_vendored_http_stack(configure, caplog):
    """openai ships against httpx2/httpcore2 — the names seen in the pod logs."""
    configure("debug")

    logging.getLogger("httpcore2.connection").debug("connect_tcp.started host=...")
    logging.getLogger("httpx2").info("HTTP Request: POST https://api.openai.com/...")

    assert caplog.text == ""


def test_a_stricter_level_quiets_them_further(configure, caplog):
    """WARNING is a floor, not a fixed level: LOG_LEVEL=error applies to these too."""
    configure("error")

    logging.getLogger("openai").warning("a warning")
    logging.getLogger("openai").error("an error")

    assert "a warning" not in caplog.text
    assert "an error" in caplog.text


def test_the_application_is_never_quieted_by_the_pin(configure, caplog):
    configure("debug")

    logging.getLogger("app.services.mentor").debug("our own module, still verbose")

    assert "our own module, still verbose" in caplog.text
