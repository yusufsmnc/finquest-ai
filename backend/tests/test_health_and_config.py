"""Health probe, CORS, and the configuration layer's defaults and validators."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings, settings

# ── /health ────────────────────────────────────────────────────────────────


def test_health_reports_status_environment_and_backend(client: TestClient):
    body = client.get("/health").json()

    assert body["status"] == "ok"
    assert body["environment"] == "test"
    assert body["database"] in {"sqlite", "postgresql"}


def test_health_needs_no_authentication(client: TestClient):
    """Kubernetes probes it without credentials — it must stay open."""
    assert client.get("/health").status_code == 200


def test_health_never_exposes_the_connection_string(client: TestClient):
    body = client.get("/health").json()

    assert "://" not in body["database"], "engine name only, never the DSN"
    assert settings.database_url not in client.get("/health").text


# ── CORS ───────────────────────────────────────────────────────────────────


def test_an_allowed_origin_is_echoed_back(client: TestClient):
    response = client.get("/health", headers={"Origin": "http://localhost:8080"})

    assert response.headers["access-control-allow-origin"] == "http://localhost:8080"


def test_an_unlisted_origin_is_not_allowed(client: TestClient):
    response = client.get("/health", headers={"Origin": "https://evil.example"})

    assert "access-control-allow-origin" not in response.headers


def test_preflight_permits_the_authorization_header(client: TestClient):
    """The Flutter client sends a Bearer token, so this header must pass."""
    response = client.options(
        "/me/progress",
        headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "PATCH",
            "Access-Control-Request-Headers": "authorization",
        },
    )

    assert response.status_code == 200
    assert "authorization" in response.headers["access-control-allow-headers"].lower()


def test_cors_is_never_a_wildcard():
    assert "*" not in settings.cors_origin_list


# ── Settings ───────────────────────────────────────────────────────────────


def _settings(**overrides) -> Settings:
    """A Settings instance built from explicit values only, ignoring ``.env``."""
    return Settings(_env_file=None, **overrides)


def test_an_empty_database_url_falls_back_to_sqlite():
    """K8s injects a real DSN; an unset var must not hand SQLAlchemy an empty string."""
    assert _settings(database_url="   ").database_url == "sqlite:///./finquest.db"


def test_a_blank_jwt_secret_never_signs_tokens():
    assert _settings(jwt_secret="").jwt_secret == "dev-insecure-change-me"


@pytest.mark.parametrize(
    ("url", "expected"),
    [
        ("postgresql+psycopg://u:p@host:5432/db", "postgresql"),
        ("postgresql://u:p@host/db", "postgresql"),
        ("sqlite:///./finquest.db", "sqlite"),
    ],
)
def test_database_backend_strips_the_driver_and_the_credentials(url, expected):
    resolved = _settings(database_url=url)

    assert resolved.database_backend == expected
    assert "p@host" not in resolved.database_backend


def test_cors_origins_are_split_and_trimmed():
    resolved = _settings(cors_origins=" http://a.test , http://b.test ,, ")

    assert resolved.cors_origin_list == ["http://a.test", "http://b.test"]


def test_the_ai_key_defaults_to_empty_rather_than_a_placeholder():
    """An unset key must mean "use the static mentor", not a fake credential."""
    assert _settings().openai_api_key == ""


def test_mentor_cost_controls_have_sane_defaults():
    resolved = _settings()

    assert 0 < resolved.mentor_max_tokens <= 200
    assert 0 < resolved.mentor_timeout_seconds <= 30
    assert resolved.mentor_cache_ttl_seconds > 0
