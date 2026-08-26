# Faz 5 — FinQuest AI on Kubernetes

The three-tier system running on a local cluster with **zero credentials in the
code, the images, or any committed manifest**. Kubernetes is the vehicle;
config/secret separation is the lesson.

```
Browser ──:8080──> frontend Pod ──REST──> backend Pod ──SQL──> postgres Pod
        ──:8000────────────────────────────┘  (FastAPI)        (+ PVC)
        (LoadBalancer)                          │
                                                ├── ConfigMap finquest-config  (non-secret)
                                                └── Secret    finquest-secrets (credentials + AI key)
```

| File | What it is |
|---|---|
| `configmap.yaml` | non-secret env: `ENVIRONMENT`, `LOG_LEVEL`, `AI_MODEL`, `DB_HOST/PORT/NAME`, `CORS_ORIGINS` |
| `secret.example.yaml` | **placeholders only** — the committed template |
| `secret.yaml` | the real values. **git-ignored**, generated from `./.env` |
| `postgres.yaml` | PVC + ClusterIP Service + Deployment |
| `backend.yaml` | LoadBalancer Service (8000) + Deployment |
| `frontend.yaml` | LoadBalancer Service (8080) + Deployment |
| `scripts/gen-secret.*` | build `secret.yaml` from the git-ignored `./.env` |

## Prerequisites

Docker Desktop with Kubernetes enabled (Settings → Kubernetes → *Enable
Kubernetes* → Apply & Restart), then:

```bash
kubectl get nodes        # docker-desktop must be Ready
```

Docker Desktop's Kubernetes shares the local image store, so **no registry and
no image side-loading are needed** — a locally built tag is directly usable.

## 1. Build the images

```bash
docker build -t finquest-backend:local ./backend
docker build -t finquest-frontend:local --build-arg API_BASE_URL=http://localhost:8000 ./frontend
```

> **`API_BASE_URL` is a build arg for the frontend, not a runtime env var.**
> Flutter web compiles to JavaScript that runs in the *browser*, so it must
> point at a host-reachable URL — never the in-cluster Service name
> `http://backend:8000`, which the browser cannot resolve. The backend's
> LoadBalancer maps to `localhost:8000`, so the compiled URL stays correct.
> Change that URL → rebuild the frontend image.

Both Deployments set `imagePullPolicy: IfNotPresent`. Without it the kubelet
would try to pull `finquest-backend:local` from Docker Hub → `ImagePullBackOff`.

## 2. Config first, then secret, then workloads

```bash
sh k8s/scripts/gen-secret.sh          # or: powershell -File k8s\scripts\gen-secret.ps1

kubectl apply -f k8s/configmap.yaml -f k8s/secret.yaml -f k8s/postgres.yaml \
              -f k8s/backend.yaml -f k8s/frontend.yaml
kubectl get pods,svc
```

Order matters: a pod whose `envFrom` names a missing Secret never starts — it
sits in `CreateContainerConfigError`.

## 3. Where each value comes from

Nothing environment-specific is baked into an image. At runtime:

- **ConfigMap → backend**: `ENVIRONMENT`, `LOG_LEVEL`, `AI_MODEL`,
  `CORS_ORIGINS`, `DB_HOST`, `DB_PORT`, `DB_NAME`
- **ConfigMap → postgres**: `POSTGRES_DB` (from `DB_NAME`)
- **Secret → backend**: `JWT_SECRET`, `OPENAI_API_KEY`, `POSTGRES_USER`,
  `POSTGRES_PASSWORD`
- **Secret → postgres**: `POSTGRES_USER`, `POSTGRES_PASSWORD`
- **Composed in `backend.yaml`**, from both halves:
  `DATABASE_URL = postgresql+psycopg://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)`

The password therefore exists in exactly one place — the Secret — and appears in
no committed file.

> `$(VAR)` expansion only sees names declared in the container's own `env:`
> list. Values arriving via `envFrom` are **not** expandable, which is why
> `POSTGRES_USER`, `POSTGRES_PASSWORD` and `DB_*` are also declared explicitly.

The frontend receives **no** config and **no** Secret: its bundle is public.

## 4. The ConfigMap lesson

Changing a ConfigMap does **not** restart the pods consuming it as env vars —
env is injected once, at container start.

```bash
# 1. edit a visible value, e.g. LOG_LEVEL: "debug"
kubectl apply -f k8s/configmap.yaml
kubectl get configmap finquest-config -o jsonpath='{.data.LOG_LEVEL}'   # -> debug

# 2. the running pod still has the OLD value:
kubectl exec deploy/backend -- printenv LOG_LEVEL                       # -> info

# 3. this is what applies it:
kubectl rollout restart deployment/backend
kubectl rollout status  deployment/backend
kubectl exec deploy/backend -- printenv LOG_LEVEL                       # -> debug
```

Same for the Secret after regenerating it.

## 5. Verify

```bash
kubectl get pods                       # all Running
curl http://localhost:8000/health      # {"status":"ok",...}
```

Open <http://localhost:8080>, register, earn XP. Then prove the volume:

```bash
kubectl delete pod -l app.kubernetes.io/name=postgres
kubectl get pods -w                    # rescheduled, PVC re-attached
```

Reload the app — the progress is still there.

## Secret hygiene

- A Kubernetes Secret is **base64-encoded, not encrypted**. Anyone who can run
  `kubectl get secret finquest-secrets -o yaml` can decode every value.
- `.gitignore` blocks `k8s/**/*secret*.yaml` and re-allows only
  `*secret*.example.yaml`. Verify any time with
  `git check-ignore -v k8s/secret.yaml`.
- `OPENAI_API_KEY` is injected into the **backend only** — never the frontend.
- Sealed Secrets / external secret management is Faz 6.

## Teardown

```bash
kubectl delete -f k8s/frontend.yaml -f k8s/backend.yaml -f k8s/postgres.yaml \
               -f k8s/secret.yaml -f k8s/configmap.yaml
```

Deleting `postgres.yaml` deletes the PVC and therefore the database contents.
