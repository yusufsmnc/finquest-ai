#!/usr/bin/env sh
# Build, load and deploy FinQuest to the local Kubernetes cluster.
#
# This script exists because "build the image and restart the deployment" does
# not work here, and fails *silently*. The node runs its own containerd with
# its own copy of every image; a rebuild under an unchanged tag never reaches
# it, and `imagePullPolicy: IfNotPresent` tells the kubelet the tag is already
# present, so the pod comes back running the previous build. Nothing errors.
#
# The fix is three things together, and none of them works alone:
#   1. tag every build with the commit it came from, so a tag names one image
#   2. load that image into the node explicitly
#   3. `imagePullPolicy: Never`, so a missing image fails loudly instead of
#      falling back to whatever the node happens to have cached
#
# Usage:  sh scripts/deploy-local.sh [--backend-only|--frontend-only]
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_ROOT"

BUILD_BACKEND=1
BUILD_FRONTEND=1
case "${1:-}" in
  --backend-only)  BUILD_FRONTEND=0 ;;
  --frontend-only) BUILD_BACKEND=0 ;;
  "" ) ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

# ── The tag ────────────────────────────────────────────────────────────────
# The commit identifies the source, but an uncommitted edit does not move
# HEAD — and deploying uncommitted work is the normal case while developing.
# A timestamp suffix keeps each dirty build distinct, so the tag never lies
# about which bytes are running.
TAG=$(git rev-parse --short HEAD)
if ! git diff --quiet HEAD -- backend frontend k8s; then
  TAG="${TAG}-dirty.$(date +%H%M%S)"
fi
echo "==> tag: $TAG"

# ── The node ───────────────────────────────────────────────────────────────
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo "==> node: $NODE"

load_image() {
  image="$1"
  if command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -q .; then
    kind load docker-image "$image"
    return
  fi
  # Docker Desktop's Kubernetes node is a container running containerd. Import
  # into the k8s.io namespace, which is the one the kubelet reads.
  tmp=$(mktemp -t finquest-image.XXXXXX)
  docker save "$image" -o "$tmp"
  docker exec -i "$NODE" ctr -n k8s.io images import --all-platforms - < "$tmp"
  rm -f "$tmp"
}

# ── Build + load ───────────────────────────────────────────────────────────
if [ "$BUILD_BACKEND" -eq 1 ]; then
  echo "==> building finquest-backend:$TAG"
  docker build -q -t "finquest-backend:$TAG" ./backend
  echo "==> loading finquest-backend:$TAG into $NODE"
  load_image "finquest-backend:$TAG"
fi

if [ "$BUILD_FRONTEND" -eq 1 ]; then
  echo "==> building finquest-frontend:$TAG"
  # API_BASE_URL is compiled into the JS: it must be reachable from the
  # browser, never an in-cluster Service name.
  docker build -q -t "finquest-frontend:$TAG" \
    --build-arg API_BASE_URL=http://localhost:8000 ./frontend
  echo "==> loading finquest-frontend:$TAG into $NODE"
  load_image "finquest-frontend:$TAG"
fi

# ── Apply ──────────────────────────────────────────────────────────────────
if [ ! -f k8s/secret.yaml ]; then
  echo "k8s/secret.yaml is missing — run: sh k8s/scripts/gen-secret.sh" >&2
  exit 1
fi

# Rendered into a temp directory rather than edited in place, so the manifests
# in git stay declarative and no deploy ever leaves a modified tree behind.
# Only k8s/*.yaml is copied: k8s/examples/ holds the placeholder Secret and
# must never reach a cluster.
# A component that was not rebuilt keeps the tag it is already running. Without
# this, `--backend-only` would point the frontend Deployment at a tag that was
# never built, and `imagePullPolicy: Never` would (correctly, loudly) fail it
# with ErrImageNeverPull.
running_tag() {
  kubectl get "deployment/$1" \
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null \
    | sed 's|.*:||'
}

resolve_tag() {
  name="$1"
  found=$(running_tag "$name")
  if [ -z "$found" ] || [ "$found" = "UNSET" ]; then
    echo "$name is not deployed yet — run a full deploy first" >&2
    exit 1
  fi
  echo "$found"
}

BACKEND_TAG="$TAG"
FRONTEND_TAG="$TAG"
if [ "$BUILD_BACKEND" -eq 0 ]; then
  BACKEND_TAG=$(resolve_tag backend)
  echo "==> keeping backend at its running tag: $BACKEND_TAG"
fi
if [ "$BUILD_FRONTEND" -eq 0 ]; then
  FRONTEND_TAG=$(resolve_tag frontend)
  echo "==> keeping frontend at its running tag: $FRONTEND_TAG"
fi

RENDER=$(mktemp -d -t finquest-manifests.XXXXXX)
trap 'rm -rf "$RENDER"' EXIT
for f in k8s/*.yaml; do
  sed -e "s|finquest-backend:UNSET|finquest-backend:$BACKEND_TAG|" \
      -e "s|finquest-frontend:UNSET|finquest-frontend:$FRONTEND_TAG|" \
      "$f" > "$RENDER/$(basename "$f")"
done

if grep -rq "UNSET" "$RENDER"; then
  echo "an image tag was left unresolved:" >&2
  grep -rn "UNSET" "$RENDER" >&2
  exit 1
fi

echo "==> applying"
kubectl apply -f "$RENDER"

# ── Roll ───────────────────────────────────────────────────────────────────
# Only the deployments whose image actually changed; the tag change alone is
# enough to trigger a new ReplicaSet, so this just waits for it.
# `a && b` under `set -e` exits the script when `a` is false, so these are
# written as plain conditionals rather than one-liners.
echo "==> waiting for rollout"
if [ "$BUILD_BACKEND" -eq 1 ]; then
  kubectl rollout status deployment/backend --timeout=300s
fi
if [ "$BUILD_FRONTEND" -eq 1 ]; then
  kubectl rollout status deployment/frontend --timeout=300s
fi
kubectl rollout status deployment/postgres --timeout=300s

echo
kubectl get pods
echo
echo "==> running images"
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
