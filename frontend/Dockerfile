# ── FinQuest AI frontend (Faz 4) ───────────────────────────────────────────
# Multi-stage: stage 1 compiles the Flutter web bundle, stage 2 serves the
# static output with nginx. The Flutter SDK (~1.5 GB) stays in stage 1 and
# never reaches the runtime image.
#
# NOTE ON CONFIG: Flutter web compiles to JavaScript that runs in the user's
# browser, so anything passed here is PUBLIC. Only API_BASE_URL — a
# ConfigMap-style, non-secret value — is baked in. No API key, no JWT secret,
# ever (CLAUDE.md). The AI key lives only in the backend.

# ── Stage 1: build ─────────────────────────────────────────────────────────
ARG FLUTTER_VERSION=stable
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

WORKDIR /app

# Dependencies first so this layer caches across code-only changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# The URL the BROWSER uses to reach the backend. It must be reachable from the
# host, NOT a compose service name: the JS runs outside the container network,
# so `http://backend:8000` would not resolve. Default matches docker-compose's
# published backend port.
ARG API_BASE_URL=http://localhost:8000
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Stage 2: serve ─────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# SPA config: unknown paths fall back to index.html so deep links work.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
