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
| `examples/secret.example.yaml` | **placeholders only** — the committed template. It sits outside this directory on purpose: `kubectl apply -f k8s/` would otherwise apply it too, and which Secret won would come down to alphabetical filename order |
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

## 1. Deploy

```bash
sh k8s/scripts/gen-secret.sh      # once, or whenever ./.env changes
sh scripts/deploy-local.sh        # or: powershell -File scripts\deploy-local.ps1
```

That is the whole flow. Use the script rather than a bare `docker build` —
**a rebuilt image does not reach the cluster on its own.**

> ### Why a script, and not `docker build` + `rollout restart`
>
> An earlier version of this file claimed Docker Desktop's Kubernetes shares
> the local image store, so no registry and no side-loading were needed. That
> holds only for an image that has not changed. The node runs its **own**
> containerd with its own copy of every image, and `imagePullPolicy:
> IfNotPresent` tells the kubelet the tag is already present — so after a
> rebuild under the same tag the pod comes back running the **previous** build,
> with no error anywhere. It surfaced only because a fix failed to take effect:
> an endpoint kept returning a 500 that had already been corrected in the code.
>
> Three things fix it, and none of them works alone:
>
> 1. **A per-build tag** — `finquest-backend:$(git rev-parse --short HEAD)`, so
>    a tag names exactly one image. Uncommitted work gets a `-dirty.<time>`
>    suffix, because editing a file does not move `HEAD`.
> 2. **An explicit load into the node** — `kind load docker-image`, or
>    `docker save | ctr -n k8s.io images import` for Docker Desktop's node.
> 3. **`imagePullPolicy: Never`** — a missing image then fails visibly with
>    `ErrImageNeverPull` instead of silently falling back to a cached one.
>
> The manifests carry `finquest-backend:UNSET`; the script renders the real tag
> into a temporary copy, so a deploy never leaves the tree modified. Applying
> `k8s/` by hand without substituting a tag is therefore expected to fail —
> loudly, which is the point.

> **`API_BASE_URL` is a build arg for the frontend, not a runtime env var.**
> Flutter web compiles to JavaScript that runs in the *browser*, so it must
> point at a host-reachable URL — never the in-cluster Service name
> `http://backend:8000`, which the browser cannot resolve. The backend's
> LoadBalancer maps to `localhost:8000`, so the compiled URL stays correct.
> Change that URL → rebuild the frontend image.

## 2. What the script does, by hand

Only needed when debugging the deploy itself.

```bash
sh k8s/scripts/gen-secret.sh          # or: powershell -File k8s\scripts\gen-secret.ps1

TAG=$(git rev-parse --short HEAD)
docker build -t finquest-backend:$TAG ./backend
docker save finquest-backend:$TAG |
  docker exec -i desktop-control-plane ctr -n k8s.io images import --all-platforms -

sed "s|finquest-backend:UNSET|finquest-backend:$TAG|" k8s/backend.yaml | kubectl apply -f -
kubectl apply -f k8s/configmap.yaml -f k8s/secret.yaml -f k8s/postgres.yaml
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
