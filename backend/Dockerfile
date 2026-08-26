# ── FinQuest AI backend (Faz 4) ────────────────────────────────────────────
# python-slim base, pinned to a stable minor so builds are reproducible.
#
# NOTHING environment-specific is baked in here: no DATABASE_URL, no
# JWT_SECRET, no OPENAI_API_KEY. Every one of those arrives at *runtime* as an
# env var (docker-compose `.env` today, a Kubernetes ConfigMap/Secret in Faz 5).
# `.env` is excluded from the build context by .dockerignore, so it can never
# be copied in by accident.
FROM python:3.12-slim

# - PYTHONDONTWRITEBYTECODE: no .pyc clutter in the image
# - PYTHONUNBUFFERED: logs reach `docker logs` immediately
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Requirements first: this layer is cached and only rebuilt when deps change.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Application code + migrations.
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
COPY docker-entrypoint.sh ./docker-entrypoint.sh

# Normalise line endings (the repo is edited on Windows; a CRLF shebang would
# make the container fail with "no such file or directory") and make it run.
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh \
 && chmod +x /app/docker-entrypoint.sh

# Run as a non-root user: a container process should never need root.
RUN useradd --create-home --uid 10001 appuser \
 && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Startup: apply migrations, then serve. Never `create_all()` — Alembic is the
# only thing allowed to touch the schema (CLAUDE.md).
ENTRYPOINT ["/app/docker-entrypoint.sh"]
