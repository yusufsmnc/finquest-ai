# CLAUDE.md

# Project: FinQuest AI (Full Three-Tier System)

FinQuest AI is an AI-powered gamified financial literacy simulation app.

This project is being evolved from a **frontend-only Flutter app** into a
**three-tier system**:

1. **Frontend** — Flutter web/mobile (served via nginx)
2. **Backend** — FastAPI (Python) REST API + persistence
3. **Database** — PostgreSQL

Plus a **real AI mentor** (Claude / LLM API, called only from the backend) and
**Kubernetes** deployment with configuration and secrets kept fully separate from
the application code.

> This file used to describe the frontend module in isolation ("backend + AI are
> external"). That is no longer true — we now build those layers ourselves. The
> frontend rules below still hold; they now live under the FRONTEND section, and
> new BACKEND / AI / DEVOPS sections have been added.

---

# 🧭 HOW TO WORK ON THIS PROJECT (READ FIRST)

- The full plan lives in **`ROADMAP.md`**. Follow it.
- **Work phase by phase.** Do NOT build everything at once. Implement one phase
  (e.g. "Faz 0 + Faz 1"), verify it works (run / test / curl), then move on.
- **Order is a dependency chain:** backend + DB first, then wire the frontend,
  then real AI, then Docker, then Kubernetes **last**. Never jump to Kubernetes
  before there is a working system.
- After each phase, confirm the phase's "Bitti kriteri" (done criterion) from
  ROADMAP.md before continuing.

---

# 🗂️ REPOSITORY STRUCTURE

```
finquest-ai/
├── frontend/          # Flutter app (existing lib/ moves here)
├── backend/           # FastAPI service
├── k8s/               # Kubernetes manifests (Deployment, Service, ConfigMap, Secret)
├── docker-compose.yml # local multi-service dev (Faz 4)
├── ROADMAP.md
└── CLAUDE.md
```

Rules:
- monorepo, one repo, clear layer boundaries
- frontend never imports backend code and vice versa; they talk over HTTP/REST

---

# 🧱 TECH STACK

- **Frontend:** Flutter + Dart, Riverpod (NotifierProvider), served by nginx in prod
- **Backend:** FastAPI, SQLAlchemy, Alembic (migrations), JWT auth
- **Database:** PostgreSQL (with a persistent volume)
- **AI:** Claude / LLM API — **called only from the backend**
- **DevOps:** Docker (multi-stage), Kubernetes (minikube/kind for local)

---

# 🔐 CONFIG & SECRETS (NON-NEGOTIABLE)

The whole point of the Kubernetes phase is separating config from code.

- **NEVER hardcode** connection strings, passwords, API keys, or JWT secrets in
  application code, Dockerfiles, or committed manifests.
- **ConfigMap** = non-secret, environment-specific values:
  `ENVIRONMENT`, `API_BASE_URL`, `LOG_LEVEL`, `AI_MODEL`, `DB_HOST`, `DB_NAME`.
- **Secret** = anything that causes harm if leaked:
  `DB_USER`, `DB_PASSWORD`, `DATABASE_URL`, `JWT_SECRET`, `ANTHROPIC_API_KEY`.
- Rule of thumb: **if leaking it causes harm → Secret; if it just varies per
  environment → ConfigMap.**
- The **AI API key lives only in the backend**, injected from a Secret. It must
  **never** reach the frontend (Flutter web is fully inspectable in the browser).
- Local dev uses a `.env` file that is **git-ignored**. Kubernetes `Secret` is
  only base64-encoded (not encryption) — never commit real Secret manifests.

---

# ==================================================
# FRONTEND (Flutter) — existing rules still apply
# ==================================================

# 📡 GLOBAL EVENT CONTRACT (SINGLE SOURCE OF TRUTH)

ALL FRONTEND SYSTEMS MUST USE ONLY THESE EVENTS:

## USER EVENTS
- DECISION_MADE
- DECISION_CORRECT
- DECISION_WRONG

## GAMIFICATION EVENTS
- XP_GAINED
- XP_LOST
- LEVEL_UP
- STREAK_UPDATED
- REWARD_UNLOCKED

Rules:
- no custom events allowed
- event names are IMMUTABLE
- all frontend agents MUST communicate via events only
- UI = pure event renderer

---

# 🔄 FRONTEND FLOW (MANDATORY PIPELINE)

EVERY interaction MUST follow:

User Action →
UI Event →
State Update →
Gamification Engine →
Animation Trigger →
UI Update →
**Sync with backend API** (persist progress)

Rules:
- no step can be skipped
- no direct state mutation
- fully deterministic execution required
- game state is persisted to the backend; the API is the source of truth across sessions

---

# 🎯 PRODUCT EXPERIENCE GOAL

The app must feel like:
- Duolingo → gamified learning loop
- Robinhood → clean fintech UI
- Revolut → modern financial dashboard
- Notion → structured clarity

Core UX principles:
- fast interaction loops
- reward-driven feedback
- emotional engagement
- minimal cognitive load
- instant feedback (<150ms perception)
- clarity over complexity

---

# 🧱 FRONTEND ARCHITECTURE RULES

```
frontend/lib/
├── core/
├── shared/
├── data/          # NEW: API client, DTOs, repositories (talks to backend)
├── features/
│   ├── onboarding/
│   ├── dashboard/
│   ├── scenarios/
│   ├── gamification/
│   ├── ai_mentor/
│   ├── achievements/
│   └── profile/
└── main.dart
```

Rules:
- feature-first architecture
- no cross-feature coupling
- reusable components mandatory
- no monolithic widgets
- all network access goes through the `data/` layer, never directly from widgets

---

# 🧠 STATE MANAGEMENT (RIVERPOD)

Rules:
- feature-level providers only
- UI reacts only to state changes
- no business logic in UI layer
- state changes ONLY from events
- no global mutable state
- remote data is loaded via repositories and exposed through providers
  (handle loading / error states explicitly)

---

# 🎨 DESIGN SYSTEM RULES

Spacing: 4, 8, 12, 16, 24, 32

Typography:
- strict hierarchy required
- max 2 font families

Colors:
- token-based only
- no hardcoded colors

Rules:
- no inconsistent UI patterns
- no ad-hoc styling
- design consistency mandatory

---

# 🧩 CORE UI COMPONENTS

BaseCard · ScenarioCard · XPProgressBar · RiskIndicator · AchievementBadge ·
AnimatedButton · MentorChatBubble · MarketEventCard · LearningProgressWidget ·
LevelIndicator · StreakCounter · RewardToast · XPFloatIndicator

---

# 🎮 GAMIFICATION (UI LAYER ONLY)

Frontend only visualizes: XP progress, level system, streaks, achievements,
challenge progress, risk visualization.

Rules:
- all rewards must be visible
- XP changes must animate
- level-ups must be emphasized
- NO computation in UI (the backend owns authoritative XP/level state)

---

# 📊 SCENARIO SCREEN RULES

Each scenario includes: event display, decision options, risk indicator,
feedback area, AI response (render-only).

UX: fast decision cycles, clear options, strong feedback loops, immediate response feeling.

---

# 📊 DASHBOARD RULES

Must include: XP / Level, portfolio simulation, risk score, active challenges,
achievements, learning progress, streak indicator.

Behavior: dynamic UI, reactive components, reward-driven engagement, "alive system" feel.

---

# 🤖 AI MENTOR UI (RENDER ONLY)

The frontend **only renders** mentor messages returned by the backend.

Displays: feedback messages, guidance, insights, next steps.

Rules:
- no reasoning exposure
- no backend/LLM logic in the frontend
- no API keys in the frontend — ever
- simple supportive tone, non-technical communication
- the real AI generation happens in the BACKEND (see below)

---

# 🎬 ANIMATION RULES (EVENT-DRIVEN)

- XP_GAINED → float + glow + scale
- XP_LOST → shake + fade red
- LEVEL_UP → full screen burst + zoom + confetti
- REWARD_UNLOCKED → reveal animation
- DECISION_WRONG → shake + red flash
- STREAK_UPDATED → pulse animation

Rules: max 2 animations at once · <150ms perception delay · lightweight only ·
performance-first motion design.

---

# ⚡ PERFORMANCE RULES

no unnecessary rebuilds · lazy rendering · smooth scrolling · no blocking UI ops ·
avoid animation stacking · memory-efficient updates.

---

# ==================================================
# BACKEND (FastAPI) — new
# ==================================================

# 🧠 ROLE: BACKEND ENGINEER

Responsible for: REST API, persistence, auth, business/gamification rules that
must be authoritative, and proxying AI calls.

# 🧱 BACKEND STRUCTURE

```
backend/
├── app/
│   ├── main.py          # FastAPI entrypoint
│   ├── core/            # config (reads env), security (JWT)
│   ├── models/          # SQLAlchemy models
│   ├── schemas/         # Pydantic DTOs
│   ├── api/             # routers/endpoints
│   ├── services/        # business logic, mentor service
│   └── db/              # session, migrations (Alembic)
├── requirements.txt
└── Dockerfile
```

# 🗃️ DATA MODEL (start small)

```
users(id, email, password_hash, created_at)
progress(user_id, xp, level, streak_count, last_active)
achievements(id, user_id, code, unlocked_at)
scenario_history(id, user_id, scenario_id, choice, result, created_at)
```

# 🌐 API ENDPOINTS (start)

```
POST  /auth/register
POST  /auth/login
GET   /me/progress
PATCH /me/progress
GET   /me/achievements
POST  /scenarios/{id}/decision
POST  /mentor
GET   /health
```

Rules:
- validate all input with Pydantic
- never change the DB schema by hand → use Alembic migrations (avoids config drift)
- read all config from environment variables (never hardcode)
- enable CORS only for the known frontend origin
- return clear error responses; no stack traces to the client

---

# ==================================================
# AI MENTOR (BACKEND) — new
# ==================================================

The mentor is now a **real LLM call**, made only from the backend.

Rules:
- endpoint: `POST /mentor` — takes user context, returns a supportive message
- integrate Claude (Anthropic) or OpenAI SDK
- prompt: turn the user's context (recent decisions, XP, level, streak) into
  personalized, non-technical guidance
- **graceful fallback:** on error / rate limit / timeout, fall back to the existing
  80+ pre-seeded static mentor messages so the app never breaks
- the API key comes from a Secret (env), lives only here, never in the frontend
- be mindful of cost / rate limits (cache or throttle if needed)

---

# ==================================================
# DEVOPS (Docker + Kubernetes) — new
# ==================================================

# 🐳 DOCKER (Faz 4)

- frontend Dockerfile: multi-stage (`flutter build web` → serve with nginx)
- backend Dockerfile: python-slim
- `docker-compose.yml`: frontend + backend + postgres, postgres with a volume
- pass config via `.env` (git-ignored)

# ☸️ KUBERNETES (Faz 5 — the main project)

- local cluster: minikube or kind
- one Deployment + Service per tier
- ConfigMap for env settings, Secret for credentials + AI key
- inject env into pods from ConfigMap / Secret (never baked into the image)
- remember: **changing a ConfigMap does NOT auto-restart pods** →
  `kubectl rollout restart deployment/<name>`
- goal: the whole system runs on K8s with **zero** credentials in code or manifests

---

# 🚫 STRICT LIMITS (per layer)

**Frontend must NOT:**
- implement backend, AI, or authoritative gamification logic (call the API instead)
- hold API keys or secrets
- create new event types or modify the event contract
- bypass the event pipeline or introduce randomness in rendering

**Everywhere:**
- do NOT hardcode secrets, keys, or connection strings
- do NOT commit `.env` or real Secret manifests
- do NOT skip phases or jump to Kubernetes before a working system exists
- do NOT edit the DB schema outside Alembic migrations

---

# 🚨 AMBIGUITY RULE

If ambiguity exists:
→ follow ROADMAP.md and the current phase
→ for the frontend, fall back to the event contract; never break determinism
→ never invent behavior or bypass the system flow
→ ask before making irreversible or cross-layer architectural decisions

---

# 🧠 FINAL PRINCIPLE

- **Frontend** is a deterministic event-driven behavioral feedback rendering system.
- **Backend** is the source of truth: persistence, auth, authoritative state, and AI.
- **Config and secrets are first-class** — kept out of code, injected at runtime.
