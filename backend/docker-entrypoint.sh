#!/bin/sh
# Backend container startup: migrate, then serve.
#
# Order matters — the API must never come up against an out-of-date schema, so
# `alembic upgrade head` runs first and a failure aborts the boot (set -e).
# The DB URL is read from the DATABASE_URL env var by app/core/config.py; it is
# never hardcoded here.
set -e

echo "[entrypoint] running database migrations (alembic upgrade head)..."
alembic upgrade head

echo "[entrypoint] starting uvicorn on 0.0.0.0:8000"
exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --proxy-headers \
  --forwarded-allow-ips '*'
