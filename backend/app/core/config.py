"""Application configuration.

All values are read from the environment (or a git-ignored ``.env`` for local
dev). Nothing here is hardcoded per-environment — in Kubernetes these come from
a ConfigMap (non-secret) and a Secret (secret). See CLAUDE.md / ROADMAP.md.
"""
from __future__ import annotations

from functools import lru_cache

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
    ai_model: str = "claude-opus-4-8"
    # Comma-separated list of allowed frontend origins (CORS). ConfigMap-style.
    # Default covers the Flutter web dev port (5000) and an nginx prod port.
    cors_origins: str = "http://localhost:5000,http://localhost:8080"

    # ── Secret-style ────────────────────────────────────────────────────
    # Default is a local SQLite file so the backend can boot with zero
    # infrastructure; docker-compose / K8s override this with PostgreSQL.
    database_url: str = "sqlite:///./finquest.db"
    jwt_secret: str = "dev-insecure-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    # ── AI (Faz 3) — backend only, never exposed to the frontend ────────
    anthropic_api_key: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
