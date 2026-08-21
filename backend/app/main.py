"""FastAPI entrypoint for the FinQuest AI backend."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings

app = FastAPI(
    title="FinQuest AI Backend",
    version="0.1.0",
    description="REST API + persistence for FinQuest AI (Faz 0).",
)

# CORS: only the known frontend origin is allowed (CLAUDE.md).
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    """Liveness probe. Returns ok + the active environment."""
    return {"status": "ok", "environment": settings.environment}