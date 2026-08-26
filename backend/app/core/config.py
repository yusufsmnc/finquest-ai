"""Application configuration.

All values are read from the environment (or a git-ignored ``.env`` for local
dev). Nothing here is hardcoded per-environment — in Kubernetes these come from
a ConfigMap (non-secret) and a Secret (secret). See CLAUDE.md / ROADMAP.md.
"""
from __future__ import annotations

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── ConfigMap-style (non-secret) ────────────────────────────────────
    environment: str = "development"
    log_level: str = "info"
    api_base_url: str = "http://localhost:8000"
    # Chat model for the mentor. ConfigMap-style: it only varies per
    # environment, leaking it causes no harm. Kept deliberately small/cheap.
    ai_model: str = "gpt-4o-mini"
    # Comma-separated list of allowed frontend origins (CORS). ConfigMap-style.
    # Default covers the Flutter web dev port (5000) and an nginx prod port.
    cors_origins: str = "http://localhost:5000,http://localhost:8080"

    # ── Mentor cost controls (ConfigMap-style) ──────────────────────────
    # Small ceiling: the mentor answers in 2-3 sentences, nothing longer.
    mentor_max_tokens: int = 120
    # Hard wall-clock limit on the LLM call; on expiry we fall back.
    mentor_timeout_seconds: float = 8.0
    # Identical context within this window reuses the previous answer
    # instead of paying for another call.
    mentor_cache_ttl_seconds: int = 300
    # Floor on the gap between two LLM calls for the same user, regardless
    # of context. Anything faster is served from the static messages.
    mentor_min_interval_seconds: float = 3.0

    # ── Secret-style ────────────────────────────────────────────────────
    # Default is a local SQLite file so the backend can boot with zero
    # infrastructure; docker-compose / K8s override this with PostgreSQL.
    database_url: str = "sqlite:///./finquest.db"
    jwt_secret: str = "dev-insecure-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    # ── AI (Faz 3) — backend only, never exposed to the frontend ────────
    # Read from the environment only. Empty is a valid state: the mentor
    # falls back to its static messages instead of failing.
    # NEVER log this, never include it in an error response.
    openai_api_key: str = ""

    @field_validator("database_url", mode="before")
    @classmethod
    def _default_database_url(cls, value: object) -> object:
        """An empty ``DATABASE_URL`` means "no database configured".

        Treat it as unset so the SQLite fallback applies, rather than handing
        SQLAlchemy an empty string. docker-compose / K8s always supply a real
        PostgreSQL URL, so this only ever affects local host runs.
        """
        if value is None or (isinstance(value, str) and not value.strip()):
            return "sqlite:///./finquest.db"
        return value

    @field_validator("jwt_secret", mode="before")
    @classmethod
    def _require_jwt_secret(cls, value: object) -> object:
        """Never sign tokens with a blank key."""
        if value is None or (isinstance(value, str) and not value.strip()):
            return "dev-insecure-change-me"
        return value

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def database_backend(self) -> str:
        """Engine name only (``postgresql`` / ``sqlite``).

        Safe to log — the credentials in ``database_url`` are not.
        """
        return self.database_url.split(":", 1)[0].split("+", 1)[0]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
