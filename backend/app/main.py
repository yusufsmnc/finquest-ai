"""FastAPI entrypoint for the FinQuest AI backend."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, progress, scenarios
from app.core.config import settings

app = FastAPI(
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


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Liveness probe. Returns ok + the active environment."""
    return {"status": "ok", "environment": settings.environment}