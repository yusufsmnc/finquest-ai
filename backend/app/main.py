"""FastAPI entrypoint for the FinQuest AI backend."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, mentor, progress, scenarios
from app.core.config import settings

logger = logging.getLogger("finquest")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Announce how the backend is wired up, without leaking any credential.

    Only the engine name and a boolean-ish flag are logged — never the
    connection string, never the API key.
    """
    logger.info(
        "FinQuest backend starting | environment=%s db=%s mentor=%s",
        settings.environment,
        settings.database_backend,
        "llm" if settings.openai_api_key else "static-fallback",
    )
    yield


app = FastAPI(
    lifespan=lifespan,
    title="FinQuest AI Backend",
    version="0.1.0",
    description="REST API + persistence for FinQuest AI (Faz 0–1).",
)

# CORS: only the explicitly listed frontend origins are allowed (never "*"),
# read from env (CORS_ORIGINS). Authorization must be an allowed header so the
# Flutter client can send the Bearer token.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth.router)
app.include_router(progress.router)
app.include_router(scenarios.router)
app.include_router(mentor.router)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Liveness probe. Returns ok + the active environment.

    ``database`` is the engine name only (``postgresql`` / ``sqlite``), so the
    running storage tier is verifiable without exposing the connection string.
    """
    return {
        "status": "ok",
        "environment": settings.environment,
        "database": settings.database_backend,
    }
