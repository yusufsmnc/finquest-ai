# FinQuest AI

A gamified financial-literacy simulation: users work through realistic money
scenarios, earn XP and streaks, and get coaching from a real LLM mentor — built
as a three-tier system (Flutter web · FastAPI · PostgreSQL) that runs on
Kubernetes with every setting and credential injected at runtime rather than
baked into the code.

[![backend-tests](https://github.com/yusufsmnc/finquest-ai/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/yusufsmnc/finquest-ai/actions/workflows/backend-tests.yml)
[![frontend-tests](https://github.com/yusufsmnc/finquest-ai/actions/workflows/frontend-tests.yml/badge.svg)](https://github.com/yusufsmnc/finquest-ai/actions/workflows/frontend-tests.yml)
[![k8s-validate](https://github.com/yusufsmnc/finquest-ai/actions/workflows/k8s-validate.yml/badge.svg)](https://github.com/yusufsmnc/finquest-ai/actions/workflows/k8s-validate.yml)

---

## What it does

**Gamification, owned by the backend.** A correct decision is +20 XP, a wrong
one −10 (floored at zero), and a level is every 100 XP. Streaks extend on a
correct answer and reset on a wrong one. Fourteen achievements unlock across
four metrics — streak, cumulative XP, decisions made, level reached — and once
earned they are permanent. None of this is computed in the UI: the frontend
posts a decision to `POST /scenarios/{id}/decision` and renders the events the
server returns.

**A real AI mentor, with a floor under it.** `POST /mentor` turns the user's
context into a short, non-technical message through the OpenAI API, under a
guardrail that forbids specific investment advice. On any error, timeout or
rate limit it falls back to 72 pre-written messages chosen deterministically
per context, so the app never breaks and never blocks on the network. Identical
context inside the cache window is not billed twice, and a burst of events
costs one call.

**Progress that survives.** Users, progress, achievements and scenario history
live in PostgreSQL behind Alembic migrations, on a persistent volume in the
cluster. Close the app, delete the database pod — the XP is still there.

---

## Architecture

```
                        ┌───────────────────────────┐
  Browser ──:8080─────► │ frontend (Flutter + nginx)│
     │                  └───────────────────────────┘
     │                     static assets only,
     │                     no config, no secrets
     │
     └────:8000───────► ┌───────────────────────────┐ ──SQL──► ┌────────────┐
        REST, from the  │ backend (FastAPI)         │          │ PostgreSQL │
        browser itself  └───────────────────────────┘          │  (+ PVC)   │
                            │            │                     └────────────┘
                            │            └──HTTPS──► OpenAI API
                            │
                  ┌─────────┴─────────┐
                  │                   │
              ConfigMap            Secret
        (environment settings)  (credentials + AI key)
```

The browser talks to both tiers directly: the compiled Flutter bundle runs on
the user's machine, so it cannot resolve an in-cluster Service name. The AI key
exists only in the backend — a Flutter web build is fully readable by anyone
who opens developer tools.

---

## Stack

| Tier | Technology |
|---|---|
| Frontend | Flutter 3.41.9 · Riverpod · served by nginx |
| Backend | FastAPI · SQLAlchemy 2 · Alembic · JWT · Python 3.12 |
| Database | PostgreSQL 16 |
| AI | OpenAI Chat Completions (`gpt-4o-mini` by default), backend-only |
| DevOps | Docker (multi-stage) · Kubernetes · GitHub Actions |

```
finquest-ai/
├── frontend/           Flutter web app (feature-first, event-driven)
├── backend/            FastAPI service, Alembic migrations, tests
├── k8s/                manifests, examples/, gen-secret + validate scripts
├── scripts/            deploy-local.sh / deploy-local.ps1
├── .github/workflows/  three CI lanes
├── docker-compose.yml  local multi-service dev
├── ROADMAP.md          the phase plan this was built against
└── CLAUDE.md           architecture rules and layer boundaries
```

`ROADMAP.md` records the phases and their done criteria; `CLAUDE.md` holds the
non-negotiable rules — the event contract, the layer boundaries, and the
config/secret policy below.

---

## Running it

### Prerequisites

Docker Desktop with Kubernetes enabled (Settings → Kubernetes → *Enable
Kubernetes*), and `kubectl` on your PATH.

```bash
kubectl get nodes        # the node must report Ready
```

### Local development — Docker Compose

```bash
cp .env.example .env     # then fill in POSTGRES_PASSWORD, JWT_SECRET, OPENAI_API_KEY
docker compose up --build
```

Frontend on <http://localhost:8080>, API on <http://localhost:8000>, interactive
docs at <http://localhost:8000/docs>. `.env` is git-ignored. `OPENAI_API_KEY`
may be left empty — the mentor then serves its static messages and everything
else works normally.

To run the Flutter app directly against that API, without rebuilding its image:

```bash
cd frontend
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8000
```

Port 5000 is already in the backend's default `CORS_ORIGINS`.

### Kubernetes

```bash
sh k8s/scripts/gen-secret.sh      # builds k8s/secret.yaml from ./.env
sh scripts/deploy-local.sh        # or: powershell -File scripts/deploy-local.ps1
```

Then open <http://localhost:8080>. Compose and the cluster both bind 8000 and
8080, so run one at a time.

**Why a deploy script rather than `docker build` + `kubectl apply`.** The node
runs its own containerd with its own copy of every image, so a rebuild under an
unchanged tag never reaches it and the pod silently comes back running the
previous build. The script tags each build from the commit it came from, loads
that image into the node explicitly, and renders the tag into a temporary copy
of the manifests; `imagePullPolicy: Never` then turns a missing image into a
visible failure instead of a stale success. `k8s/README.md` has the long
version.

### The API

| Method | Path | Auth | |
|---|---|:--:|---|
| `POST` | `/auth/register` | – | create an account |
| `POST` | `/auth/login` | – | returns a JWT |
| `GET` | `/me/progress` | ✓ | XP, level, streak, decision counts |
| `GET` | `/me/achievements` | ✓ | unlocked achievements |
| `POST` | `/scenarios/{id}/decision` | ✓ | apply a decision, persist it, return events |
| `POST` | `/mentor` | ✓ | a mentor message for the user's context |
| `GET` | `/health` | – | liveness probe |

There is deliberately no write endpoint for progress: authoritative state moves
only through the decision endpoint.

---

## Configuration and secrets

The point of the Kubernetes phase, and the rule the codebase is arranged
around: **if leaking it causes harm it is a Secret; if it merely varies per
environment it is a ConfigMap.** Nothing environment-specific is baked into an
image, and no credential exists in the repository.

| | |
|---|---|
| **ConfigMap** `finquest-config` | `ENVIRONMENT`, `LOG_LEVEL`, `AI_MODEL`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `CORS_ORIGINS`, `API_BASE_URL` |
| **Secret** `finquest-secrets` | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `JWT_SECRET`, `OPENAI_API_KEY` |

`DATABASE_URL` is composed in `k8s/backend.yaml` from the secret half and the
non-secret half, so the password exists in exactly one place.

Three consequences worth stating plainly:

- **A Kubernetes Secret is base64-encoded, not encrypted.** Anyone who can run
  `kubectl get secret finquest-secrets -o yaml` can decode every value.
  `k8s/secret.yaml` is therefore git-ignored and generated from `./.env`. The
  committed `k8s/examples/secret.example.yaml` holds placeholders only, and
  lives outside `k8s/` so that `kubectl apply -f k8s/` cannot apply it by
  accident.
- **The AI key reaches the backend and nowhere else.** The frontend receives no
  Secret at all — its bundle is public by construction.
- **Config is injected once, at container start.** Editing a ConfigMap restarts
  nothing; `kubectl rollout restart deployment/backend` is what applies it.
  `LOG_LEVEL` is the easiest way to see this: set it to `debug` and the pod
  keeps logging at `info` until it is restarted.

---

## Tests and CI

Three lanes, each gating its own part of the tree.

| Lane | Triggers on | What it runs |
|---|---|---|
| `backend-tests` | `backend/**` | ruff format + lint, `alembic upgrade head` against a PostgreSQL service container, then 188 tests |
| `frontend-tests` | `frontend/**` | `dart format --set-exit-if-changed`, `flutter analyze`, 34 tests |
| `k8s-validate` | `k8s/**` | secret hygiene, `kubeconform -strict` against Kubernetes 1.36, and a structural pass over the manifests |

The backend suite runs against real PostgreSQL rather than SQLite, and each
test is wrapped in a transaction that is rolled back afterwards — so the
migration itself is exercised on every run and no test can see another's rows.
`k8s-validate` also checks what a schema cannot: that every `configMapKeyRef`
and `secretKeyRef` resolves, that every Service selector matches a pod
template, and that no placeholder Secret has crept into the apply path.

```bash
cd backend && pytest                            # 188 passed
cd frontend && flutter test                     # 34 passed
pip install pyyaml                              # the validator's only dependency
python k8s/scripts/validate-manifests.py
```

---

## Known limits

- **Secrets are not encrypted at rest in git.** `k8s/secret.yaml` stays local
  and is regenerated from `.env`, so a fresh clone cannot deploy without that
  file. Sealed Secrets would let an encrypted Secret live in the repository;
  it is planned, not done.
- **One entry point per tier.** Frontend and backend each publish their own
  LoadBalancer rather than sitting behind a single Ingress, which is why
  `CORS_ORIGINS` has to name the frontend's origin explicitly.
- **Single replica, no autoscaling.** The backend runs one pod. Scaling out
  needs an HPA, resource requests, and the Alembic migration moved out of the
  pod entrypoint into a Job so it does not run once per replica.
- **Local cluster only.** Everything here is verified against Docker Desktop's
  Kubernetes; there is no cloud deployment or image registry in this
  repository.

See `ROADMAP.md` for what comes next and why it is ordered that way.
