# FinQuest AI — Üç Katmana Yolculuk (Yol Haritası)

> **Claude Code / CLI için not:** Bu dosya bir spec ve yapılacaklar listesidir.
> Bir seferde her şeyi uygulama. **Faz faz ilerle** — örn. "ROADMAP.md'deki Faz 0
> ve Faz 1'i uygula". Her fazın sonunda çıkan sonucu doğrula (test/çalıştır),
> sonra bir sonrakine geç. Kubernetes (Faz 5) en sona bırakılır: önce çalışan
> bir sistem, sonra orkestrasyon.

## Bağlam

Bugün **FinQuest AI** tamamen istemci tarafında çalışan tek katmanlı bir Flutter
uygulaması: backend yok, veritabanı yok, kalıcılık yok (state bellekte), AI mentor
statik mesajlardan ibaret.

**Hedef:** Gerçek AI mentor'lu, verisi kalıcı, Kubernetes üzerinde çalışan; config
ve secret'ları koddan tamamen ayrılmış üç katmanlı bir sistem.

**Stack kararı:** Flutter Web (nginx ile servis) · FastAPI (Python) · PostgreSQL ·
Claude/LLM API · Docker · Kubernetes.

## Hedef mimari

```
Tarayıcı ──HTTP──> Frontend Pod ──REST──> Backend Pod ──SQL──> PostgreSQL Pod
                   (Flutter+nginx)        (FastAPI)            (+ Volume)
                     Katman 1               Katman 2            Katman 3
                                               │
                                               ├──HTTPS──> Claude / LLM API (dış)
                                               │
                              env olarak <─────┤─────> env olarak
                              ConfigMap ────────┘        Secret
                          (ortam ayarları)          (şifre + AI anahtarı)
```

İstek soldan sağa akar. **Kritik kural:** backend'in her ayarı ConfigMap ya da
Secret'tan gelir — hiçbiri image'a veya koda gömülmez. Projenin asıl dersi bu.

## ConfigMap mi, Secret mi?

Kural: **sızarsa zarar veren her şey Secret'a**, ortama göre değişen ama gizli
olmayan her şey ConfigMap'e.

| ConfigMap (gizli değil, ortama göre değişir) | Secret (sızarsa zarar verir) |
|---|---|
| `ENVIRONMENT` (staging/prod) | `DB_USER` |
| `API_BASE_URL` | `DB_PASSWORD` |
| `LOG_LEVEL` | `DATABASE_URL` (tam bağlantı) |
| `AI_MODEL` (model adı) | `JWT_SECRET` |
| `DB_HOST` / `DB_NAME` | `ANTHROPIC_API_KEY` |
| `FEATURE_FLAGS` | |

> ⚠️ Kubernetes Secret varsayılan olarak sadece **base64** ile kodlanır — bu
> şifreleme değildir. Secret dosyalarını git'e commit'leme (Faz 6: Sealed Secrets /
> harici secret yönetimi).

---

## Fazlar

### Faz 0 — Temel kararlar & çalışma ortamı (Hazırlık)
**Hedef:** Repo'yu iki katmanlı çalışacak şekilde düzenle, boş backend'i lokalde ayağa kaldır.

- [ ] Repo'yu `frontend/` ve `backend/` klasörlerine ayır (monorepo)
- [ ] Python 3.12 + sanal ortam (venv)
- [ ] Lokal PostgreSQL'i Docker ile çalıştır
- [ ] `.env` dosyası oluştur ve `.gitignore`'a ekle
- [ ] "Hello world" FastAPI endpoint'i (`/health`)

**Kavramlar:** monorepo, venv, .gitignore, env ayrımı
**Bitti kriteri:** `backend/` çalışıyor, `/health` "ok" dönüyor.

### Faz 1 — Backend + PostgreSQL: kalıcılık
**Hedef:** Kullanıcı/XP/achievement/streak verisini DB'ye kaydeden REST API. FinQuest'in en büyük eksiği burada kapanır.

- [ ] FastAPI + SQLAlchemy + Alembic (migration)
- [ ] Modeller: User, Progress, Achievement, ScenarioHistory
- [ ] CRUD endpoint'leri (aşağıdaki API taslağı)
- [ ] Basit JWT auth (register / login)
- [ ] Bağlantı bilgisini `.env`'den oku

**Kavramlar:** REST, ORM, migration, connection string, JWT
**Bitti kriteri:** `curl` ile kullanıcı oluşturup XP kaydedip geri okuyabiliyorsun.

### Faz 2 — Flutter'ı backend'e bağla
**Hedef:** Riverpod'daki bellek-içi state'i API çağrılarıyla değiştir.

- [ ] Flutter'a `dio`/`http` API katmanı
- [ ] Riverpod provider'larını API'ye bağla
- [ ] Login ekranı + token saklama (secure storage)
- [ ] Loading / hata durumları
- [ ] Backend'de CORS'u frontend origin'ine aç

**Kavramlar:** CORS, async data, token yönetimi, API katmanı
**Bitti kriteri:** Uygulamayı kapatıp açınca ilerleme kayıtlı geliyor.

### Faz 3 — Gerçek AI mentor
**Hedef:** Statik mesajları LLM ile değiştir; mevcut 80+ hazır mesajı **fallback** olarak tut. API anahtarı Secret dersini "gerçek" yapar.

- [ ] Backend'de `POST /mentor` endpoint'i
- [ ] Anthropic (Claude) veya OpenAI SDK entegrasyonu
- [ ] Prompt tasarımı: kullanıcı bağlamı → kişisel öğüt
- [ ] Hata/kota durumunda statik mesajlara fallback
- [ ] API anahtarı yalnızca backend'de, `.env`'de

**Kavramlar:** LLM API, prompt tasarımı, gizli anahtar, graceful fallback, rate limit
**Bitti kriteri:** Mentor bağlama duyarlı gerçek cevap veriyor; anahtar frontend'de görünmüyor.

### Faz 4 — Containerization (Docker)
**Hedef:** Her katmanı image'a al, üçünü `docker-compose` ile birlikte çalıştır.

- [x] Frontend Dockerfile (multi-stage: `flutter build web` → nginx)
- [x] Backend Dockerfile (python-slim)
- [x] `docker-compose.yml`: frontend + backend + postgres
- [x] DB için volume (veri kalıcılığı)
- [x] Değişkenleri `.env` üzerinden compose'a geçir

**Kavramlar:** image, multi-stage build, container network, volume, env injection
**Bitti kriteri:** `docker compose up` ile üç servis birlikte kalkıyor.

### Faz 5 — Kubernetes (asıl proje)
**Hedef:** docker-compose'u K8s'e taşı, tüm config'i ConfigMap/Secret ile koddan ayır.

- [x] Lokal cluster (minikube ya da kind)
- [x] Her katman için Deployment + Service
- [x] ConfigMap (ortam ayarları) + Secret (şifre, AI anahtarı)
- [x] env'leri ConfigMap/Secret'tan pod'a bağla
- [x] ConfigMap değişince pod'un otomatik yenilenmediğini gözlemle → `kubectl rollout restart`

**Kavramlar:** Pod, Deployment, Service, ConfigMap, Secret, rollout
**Bitti kriteri:** Sistem tamamen K8s'te çalışıyor, hiçbir credential koda/manifest'e gömülü değil.

### Faz 6 — Sağlamlaştırma
**Hedef:** Prod'a yakın pratikler. Faz 5 sistemi ayağa kaldırdı; bu faz onu
güvenilir hale getirir. Sıra bağlayıcıdır: 6b koddan bir açığı kapatır, 6c
altyapıyı sağlamlaştırır.

#### 6b — `PATCH /me/progress` kısıtlaması
Otoriter alanlar (`xp`, `level`, `streak_count`, `last_active`) istemciden
yazılamaz; yalnızca decision akışıyla değişir. CLAUDE.md "backend otoriter
state'in sahibi" diyor, bu endpoint bugün onu deliyor.

- [x] Endpoint'in meşru kullanımını tespit et (frontend + başka çağıran var mı)
- [x] Otoriter alanları istemci yazımına kapat
- [x] Frontend'i kırmadığını doğrula

**Bitti:** `test_client_cannot_overwrite_authoritative_progress` xfail olmaktan
çıkıp gerçek bir kısıtlama testi olarak yeşil geçiyor; koddaki `TODO(Faz 6)`
notu kalkmış.

#### 6c1 — Probe'lar
Backend liveness/readiness (`/health`), postgres `pg_isready`, frontend
`/healthz`.

- [ ] Üç katmanda da probe'lar tanımlı
- [ ] Readiness gerçekten trafiği kapıda tutuyor

**Bitti:** Readiness gate'li — backend, Postgres hazır olmadan Service'ten
trafik almıyor.

#### 6c2 — Sealed Secrets
Controller + `kubeseal`. Secret şifreli bir `SealedSecret`'a dönüşür ve git'e
commit'lenebilir hale gelir.

- [ ] Cluster'a sealed-secrets controller'ı kur
- [ ] `secret.yaml` → `sealedsecret.yaml` (kubeseal ile şifrele)
- [ ] Controller'ın SealedSecret'tan Secret ürettiğini doğrula

**Bitti:** Gerçek credential repo'da **şifreli** duruyor; düz `secret.yaml`
git-ignored kalmaya devam ediyor.

#### 6c3 — Ingress *(opsiyonel)*
`ingress-nginx` ile tek giriş noktası; iki LoadBalancer yerine tek host.

- [ ] ingress-nginx controller
- [ ] Ingress kaynağı: `/` → frontend, `/api` → backend
- [ ] Frontend `/api` yoluna göre yeniden build edilir (`API_BASE_URL` build arg)

**Bitti:** Tek adresten hem uygulama hem API çalışıyor; CORS tek origin'e iner.

#### 6c4 — HPA *(opsiyonel)*
`metrics-server` + backend için CPU tabanlı otomatik ölçekleme.

- [ ] metrics-server kurulumu
- [ ] Resource requests/limits (CPU/bellek) — HPA'nın ön koşulu
- [ ] Backend HPA (CPU hedefi)
- [ ] Migration'ı Job/initContainer'a taşı — çok replikada `alembic upgrade head`
      her pod'da koşmamalı

**Bitti:** Backend yük altında replika sayısını artırıyor, migration tek yerden
koşuyor.

**Kavramlar:** health checks, readiness gating, secret encryption, ingress,
autoscaling, GitOps
**Bitti kriteri:** Sistem yeniden başlatmalara ve yüke karşı dayanıklı; hiçbir
credential repo'da düz metin değil.

> Eski listedeki "basit CI" maddesi Faz 5 sonrasında tamamlandı: `backend-tests`,
> `frontend-tests` ve `k8s-validate` lane'leri merge'e gate oluyor.

---

## Veri modeli (başlangıç)

```
users(id, email, password_hash, created_at)
progress(user_id, xp, level, streak_count, last_active)
achievements(id, user_id, code, unlocked_at)
scenario_history(id, user_id, scenario_id, choice, result, created_at)
```

## API endpoint'leri (başlangıç)

```
# kimlik
POST  /auth/register
POST  /auth/login
# ilerleme
GET   /me/progress          # salt okunur (Faz 6b)
GET   /me/achievements
# oyun + mentor
POST  /scenarios/{id}/decision
POST  /mentor
```

---

## En sık batılan yerler

1. **AI anahtarını frontend'e koyma.** Flutter web tarayıcıda çalışır; oradaki her şey görülebilir. Anahtar yalnızca backend'de, Secret olarak.
2. **Secret'ları git'e commit'leme.** base64 şifreleme değildir; gerçek Secret dosyaları `.gitignore`'da kalır.
3. **ConfigMap değişince pod otomatik restart olmaz.** `kubectl rollout restart` gerekir (herkesin ilk seferde şaşırdığı yer).
4. **DB şemasını elle değiştirme.** Alembic migration kullan; yoksa ortamlar ayrışır (config drift).
5. **Her şeyi aynı anda yapma.** Faz sırasını koru. En sık batma sebebi, çalışan bir sistem olmadan Kubernetes'e atlamaktır.
