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
güvenilir hale getirir. Sıra bağlayıcıdır: 6a ve 6b koddaki iki açığı kapatır,
6c altyapıyı sağlamlaştırır.

#### 6a — Uzun parola 500 döndürüyordu
`hash_password`, bcrypt'in 72 byte sınırının üstünde `ValueError` fırlatıyor
(bcrypt 4.x eski sürümlerdeki sessiz kırpmayı kaldırdı). `RegisterRequest` ise
128 karaktere izin veriyordu; arada kalan 73–128 karakterlik bir parola
`POST /auth/register` üzerinde **500** dönüyordu. Şemanın kabul ettiği bir
girdi sunucuyu patlatıyordu — doğrulama hatası olması gereken şey iç hataya
dönüşüyordu.

**Çözüm:** parola doğrulaması bcrypt'in gerçek sınırına, **byte** cinsinden
bağlandı; istek 422 ile reddediliyor. Pydantic'in `max_length`'i karakter
saydığı için yetmezdi: "şifreçöğü" 9 karakter ama 14 byte, emoji 4 byte —
karakter sayan bir sınır bunları geçirir, sonra hash içinde patlarlardı.
(Alternatif olan SHA-256 ön-hash limiti tamamen kaldırırdı ama `security.py`'yi
değiştirip mevcut hash'leri geçersiz kılardı; bu fazda byte limiti yeterli.)

- [x] Doğrulamayı bcrypt sınırıyla byte bazında hizala
- [x] Uzun parola 500 değil 422 dönsün (register **ve** login)
- [x] `test_security.py`'deki iki `strict` xfail'i gerçek teste çevir

**Bitti:** 73+ byte parolayla register/login 422 dönüyor; `hash_password`
hiçbir geçerli girdide fırlatmıyor ve suite'te hiç xfail kalmadı.

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
Backend startup + liveness (`/health`) ve DB'ye duyarlı readiness; postgres
`pg_isready`; frontend `/healthz`.

`/health` yalnızca config'ten cevap veriyor — DB'ye hiç dokunmuyor — bu yüzden
readiness için elverişsiz: Postgres kapalıyken bile 200 döner. Readiness bunun
yerine `exec` ile gerçek bir `SELECT 1` koşar. Liveness kasten `/health`'te
kalır: "süreç çalışıyor mu" sorusunu cevaplamalı, "bağımlılığı ayakta mı"
sorusunu değil — aksi halde bir DB kesintisi tüm replikaları crashloop'a sokar.

- [x] Üç katmanda da probe'lar tanımlı
- [x] Readiness gerçekten trafiği kapıda tutuyor
- [x] initContainer ile Postgres beklenir (deploy'daki tek restart kalkar)

**Bitti:** Readiness gate'li — backend, Postgres hazır olmadan Service'ten
trafik almıyor; tam redeploy sonrası backend `RESTARTS = 0`.

#### 6c5 — Deploy doğruluğu
Kabul testinde çıkan iki **sessiz** tuzak. İkisi de hata vermiyor, yanlış şeyi
çalıştırıyor — bu yüzden 6c2'den önce.

**Image propagation:** node kendi containerd'sini çalıştırıyor; aynı tag'le
yeniden build edilen image node'a hiç ulaşmıyor ve `imagePullPolicy:
IfNotPresent` kubelet'e "bu tag zaten var" dedirtiyor. Sonuç: rebuild sonrası
pod **önceki** kodu çalıştırmaya devam ediyor, hiçbir yerde hata yok. Kabul
testinde düzeltilmiş bir 500'ün hâlâ 500 dönmesiyle yakalandı.

**Placeholder Secret:** `kubectl apply -f k8s/`, dizindeki her `*.yaml`'ı
uyguluyor — `secret.example.yaml` dahil. İkisi de aynı `metadata.name`'i
taşıdığı için hangisinin kazandığını alfabetik dosya sırası belirliyor; şablonun
adı `secret.template.yaml` olsaydı cluster'a `REPLACE_ME` giderdi.

- [x] `scripts/deploy-local.(sh|ps1)`: commit başına tag → node'a load →
      manifest tag'ini render et → apply + rollout
- [x] `imagePullPolicy: Never` — eksik image sessizce eskiye düşmek yerine
      `ErrImageNeverPull` ile görünür şekilde patlasın
- [x] `k8s/README.md`'deki yanlış "no side-loading needed" iddiasını düzelt
- [x] Şablonu apply taramasının dışına al (`k8s/examples/`)
- [x] `validate-manifests.py` apply yolunda placeholder Secret'ı reddetsin

**Bitti:** Backend'de bir kod değişikliği deploy sonrası pod'da gerçekten
çalışıyor (tag + digest + davranışla kanıtlı); temiz bir apply yalnızca gerçek
Secret'ı uyguluyor.

#### 6c6 — Logging yapılandırması
`LOG_LEVEL` Faz 5'ten beri ConfigMap'te, Faz 1'den beri `Settings`'te — ama
hiçbir yerde **okunmuyordu**. Hiçbir handler kurulmadığı için root logger
varsayılan WARNING'de kalıyor, uygulamanın her `logger.info`'su hiçbir yere
gitmiyordu. `main.py`'deki açılış tanı satırı — backend'in hangi ortama, hangi
veritabanına bağlandığını ve mentor'un anahtarı olup olmadığını söyleyen tek
satır — Faz 5 boyunca `kubectl logs`'ta görünmedi. 6c5'te bir deploy kanıtı
`logger.info` ile yazıldığında fark edildi: satır image'ın içindeydi, sadece
sessizdi.

- [x] `configure_logging()`: `LOG_LEVEL`'ı oku, stdout'a handler kur
- [x] Geçersiz bir seviye pod'u düşürmesin, INFO'ya insin
- [x] uvicorn logger'ları aynı handler'ı paylaşsın (tek format, tek satır)
- [x] Açılış tanı satırı gerçekten emit edilsin
- [x] Testler: info/debug/warning davranışı ve açılış satırı
- [x] Üçüncü parti logger'lar (openai, httpx/httpcore ve vendor'lanmış
      httpx2/httpcore2) WARNING'e sabit — `LOG_LEVEL: debug` uygulama
      debug'ını açsa bile OpenAI SDK mentor prompt'unu, yani öğrencinin
      bağlamını (xp, level, streak, son kararlar) log'a dökmesin

**Bitti:** ConfigMap'te `LOG_LEVEL: debug` → `rollout restart` sonrası pod
DEBUG satırları basıyor; `info`'da basmıyor. Açılış satırı `kubectl logs`'ta
görünüyor ve hiçbir credential içermiyor. DEBUG'da üçüncü parti kütüphaneler
susuyor: prompt ve öğrenci bağlamı log'a hiç girmiyor.

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
> `frontend-tests`, `k8s-validate` ve `docker-build` lane'leri merge'e gate oluyor.

#### CI: image build
`docker-build` lane'i: PR'da frontend ve backend image'ları **derleniyor mu**
diye bakar — push yok, registry yok, cluster yok. Diğer lane'lerin göremediği
şey: `backend-tests` kodu checkout'tan doğrudan koşuyor, `frontend-tests`
`flutter test` çalıştırıyor; ikisi de yeşil kalırken bir Dockerfile bozulmuş
olabilir. O hata aksi halde deploy anında çıkar.

- [x] `docker-build.yml`: `backend-image` + `frontend-image` job'ları
- [x] Sadece build (`push: false`, `load: false`), buildx + GHA cache

**Bitti:** Bozuk bir Dockerfile merge'den önce yakalanıyor.

#### CI: lib/ format paritesi
Backend'de `ruff` neyi yapıyorsa frontend'de `dart format` onu yapmalı. Lane
bugüne kadar sadece `test/`'i kontrol ediyordu, `lib/` hiç biçimlenmemişti — 134
dosyanın 118'i biçim dışıydı. Tek seferde toparlanıp kapıya kilit takıldı.

- [x] `dart format lib/` — 118 dosya, mekanik (boşluk + bir BOM + EOF newline'ları)
- [x] Formatın ikiye böldüğü 3 `if` parantezlendi (`curly_braces_in_flow_control_structures`)
- [x] `frontend-tests`: format adımı artık `lib/ test/`

**Bitti:** `dart format --set-exit-if-changed lib/ test/` temiz geçiyor ve CI
biçim kaymasını bir daha birikmeden yakalıyor.

---

### Faz 7 — Manuel testte çıkan UI & veri bağlama düzeltmeleri
**Hedef:** Ekranda görünen sayıların hepsi backend'den gelsin. Faz 1–6 sistemi
kurdu ve doğruladı; bu faz canlı uygulamayı gezerken çıkan tutarsızlıkları
kapatır.

**Bulgu (canlı Profile ekranı):** üstte XP 0 / Decisions 0 yazarken hemen
altındaki XP Progress kartı 60 XP / Level 2 gösteriyor. Aynı ekranda iki farklı
sayı, çünkü bazı widget'lar `progressProvider`'a bağlı değil — sabit ya da
sıfır placeholder render ediyor. Tek bir yanlış sayı, doğru olanlara duyulan
güveni de götürür.

#### 7a — Logout
Frontend-only: JWT stateless olduğu için backend'de bir şey iptal edilmiyor.

- [x] Profile'da logout aksiyonu
- [x] Secure storage'daki token temizlensin
- [x] Provider'lar sıfırlansın (sonraki kullanıcı öncekinin verisini görmesin)
- [x] Login ekranına dönülsün

**Bitti:** Logout sonrası korumalı ekranlara erişilemiyor, tekrar login
gerekiyor.

#### 7b — Profile istatistikleri backend'e bağlansın
Üstteki XP/Decisions, "Total XP Earned" ve Accuracy şu an sabit ya da sıfır.

- [x] Hepsi `progressProvider`'dan okunsun (`GET /me/progress`, +
      `decisions_made` / `decisions_today`)
- [x] Accuracy için backend: `scenario_history`'den doğru karar sayısı ve oran
      türetilip `/me/progress` yanıtına eklensin
- [x] `best_streak` kolonu + Alembic migration (mevcut satırlar `streak_count`
      ile backfill edilir, yoksa "best < current" saçmalığı çıkar)
- [x] `xp_earned_total`: brüt kazanılan XP (`xp` net bakiye, aynı şey değil)
- [x] Frontend accuracy'yi hesaplamasın, render etsin

**Bitti:** Yenilemede tüm sayılar backend'le tutarlı; 60 XP ekranın her yerinde
60.

#### 7c — Görev "completed" durumu kalıcı olsun
Challenge ilerlemesi lokal geçici state'ten geliyor, sayfa yenilenince sıfırlanıyor.

- [ ] İlerleme ve completed durumu her yüklemede backend sayaçlarından
      türetilsin (`decisions_today`, `streak_count`, `decisions_made`)
- [ ] Lokal sayaç tutulmasın

**Bitti:** Görev tamamlanıp sayfa yenilendiğinde hâlâ completed görünüyor.

#### 7d — Learning Progress gerçek veriye bağlansın *(opsiyonel — karar gerekiyor)*
Budgeting / Investing / Savings / Risk yüzdeleri hardcode. İki yol var ve
seçim ürün kararı:

- **(A)** Mevcut veriden türetilebilen bir agregata bağla, ya da widget'ı
  kaldır — yanıltıcı sabit göstermektense hiç gösterme.
- **(B)** `scenario_history`'ye kategori kolonu ekle (Alembic migration) ve
  yüzdeleri gerçekten oradan türet. Daha doğru, ama şema değişikliği ve geriye
  dönük veri sorusu getiriyor.

- [ ] (A) ya da (B) kararı
- [ ] Seçilen yol uygulansın

**Bitti:** Yüzdeler gerçek veriye dayanıyor ya da ekranda yanıltıcı sabit
değer kalmıyor.

**Kavramlar:** tek doğruluk kaynağı, türetilmiş state, oturum yaşam döngüsü
**Bitti kriteri:** Profile ekranındaki hiçbir sayı backend'dekiyle çelişmiyor;
ekranda kaynağı olmayan sabit değer yok.

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
