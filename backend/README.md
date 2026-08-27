# FinQuest AI — Backend (FastAPI)

REST API + persistence for FinQuest AI. Covers **Faz 0** (health, monorepo split,
venv, env separation) and **Faz 1** (PostgreSQL persistence, models, migrations,
JWT auth, CRUD).

## Stack
FastAPI · SQLAlchemy 2.0 · Alembic · PyJWT · bcrypt · Pydantic v2 · PostgreSQL
(SQLite as a zero-infra local fallback).

## Layout
```
app/
├── main.py          # FastAPI app, /health, CORS, router wiring
├── core/            # config (env-driven), security (JWT + bcrypt)
├── db/              # engine/session, declarative Base, metadata registry
├── models/          # User, Progress, Achievement, ScenarioHistory
├── schemas/         # Pydantic request/response DTOs
├── api/             # routers: auth, me (progress/achievements), scenarios
└── services/        # authoritative gamification rules
alembic/             # migrations (env.py reads DATABASE_URL from env)
```

## Configuration
All config comes from the environment. Copy the template and edit:
```bash
cp .env.example .env
```
- Leak-sensitive values (`DATABASE_URL`, `JWT_SECRET`, `ANTHROPIC_API_KEY`) →
  **Secret** in K8s.
- Environment-varying values (`ENVIRONMENT`, `API_BASE_URL`, `AI_MODEL`, …) →
  **ConfigMap** in K8s.

`.env` is git-ignored. Never commit it.

## Run locally

### 1. Database
**With Docker (target — PostgreSQL):**
```bash
docker compose up -d db          # from repo root
# in backend/.env:
# DATABASE_URL=postgresql+psycopg://finquest:finquest@localhost:5432/finquest
```
**Without Docker (fallback — SQLite):** the default `.env` already uses
`sqlite:///./finquest.db`, so nothing to start.

### 2. Install + migrate + serve
```bash
py -3.14 -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python -m alembic upgrade head
.venv\Scripts\python -m uvicorn app.main:app --reload
```
API docs: http://localhost:8000/docs

## Endpoints
| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | – | liveness probe |
| POST | `/auth/register` | – | create user (seeds zeroed progress) |
| POST | `/auth/login` | – | returns JWT |
| GET | `/me/progress` | ✓ | read authoritative XP/level/streak (read-only: no client write, Faz 6b) |
| GET | `/me/achievements` | ✓ | list unlocked achievements |
| POST | `/scenarios/{id}/decision` | ✓ | apply a decision, persist history, return events |

## Gamification (authoritative — backend owns the numbers)
- correct decision: **+20 XP**, streak +1
- wrong decision: **−10 XP** (floored at 0), streak reset
- level curve: `level = 1 + xp // 100`
- responses emit the immutable frontend event names
  (`DECISION_CORRECT`, `XP_GAINED`, `LEVEL_UP`, `STREAK_UPDATED`, …).

## Migrations (Alembic — never edit schema by hand)
```bash
.venv\Scripts\python -m alembic revision --autogenerate -m "message"
.venv\Scripts\python -m alembic upgrade head
```

## Smoke test
```bash
curl http://localhost:8000/health
# {"status":"ok","environment":"development"}
```
