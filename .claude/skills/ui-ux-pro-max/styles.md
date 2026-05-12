# UI Styles System — FinQuest AI

Bu dosya `ui-ux-pro-max` skill tarafından kullanılır.  
UI-Agent, her ekran için **UI stil kararını buradan seçer**.

---

# 🧠 CORE RULE

## UI STYLE = BEHAVIOR DESIGN SYSTEM

UI stili sadece görünüm değildir.

UI stili aynı zamanda:

- kullanıcı dikkat yönetimi
- karar hız optimizasyonu
- gamification hissi üretimi
- bilgi yoğunluğu kontrolü

---

# 📊 FINQUEST UI STYLE CATALOG

---

## 1. FINTECH CLEAN (DEFAULT)

### Özellikler
- Material 3 tabanlı
- düz ve net kart yapısı
- soft shadow
- minimal noise
- net hierarchy

### Kullanım
- dashboard
- portfolio
- scenario screens

### UX Hedefi
- hızlı karar verme
- düşük cognitive load
- güven hissi

---

## 2. GAMIFIED BENTO SYSTEM

### Özellikler
- grid tabanlı kart layout
- farklı boyutlarda UI blokları
- XP + risk + scenario aynı ekranda

### Kullanım
- dashboard
- home screen

### UX Hedefi
- oyun hissi
- yüksek engagement
- yapılandırılmış bilgi yoğunluğu

---

## 3. AI INSIGHT GLASS UI

### Özellikler
- blur (BackdropFilter)
- semi-transparent cards
- glow accents
- layered UI

### Kullanım
- AI mentor
- feedback screens

### UX Hedefi
- AI / intelligence hissi
- premium SaaS görünümü

---

## 4. SCENARIO DECISION MODE

### Özellikler
- distraction-free layout
- tek odak senaryo
- 2–3 decision button
- risk indicator always visible

### Kullanım
- scenario interaction screens

### UX Hedefi
- karar kalitesini maksimize etmek
- dikkat dağınıklığını sıfırlamak

---

## 5. GAMIFICATION NEON MODE

### Özellikler
- glow effects
- animated borders
- XP burst UI
- vibrant accent colors

### Kullanım
- reward screens
- level up
- achievements

### UX Hedefi
- dopamine feedback loop
- yüksek motivasyon

---

## 6. EDUCATION MODE

### Özellikler
- sade layout
- geniş spacing
- düşük görsel karmaşa
- açıklayıcı UI

### Kullanım
- onboarding
- tutorial screens

### UX Hedefi
- öğrenme kolaylığı
- düşük bilişsel yük

---

# ⚙️ IMPLEMENTATION NOTES (FLUTTER)

## Glass UI
- BackdropFilter + ImageFilter.blur

## Bento Layout
- GridView + custom spans

## Neon Effects
- BoxShadow + animated glow

## Clean UI
- Material 3 + ColorScheme

---

# 🎮 GAMIFICATION STYLE RULES

- XP her zaman animasyonla gösterilir
- reward = full screen feedback
- loss = subtle shake + fade
- level up = transition animation
- risk = her zaman visible indicator

---

# 🚫 STRICT RULES

- aşırı shadow kullanımı yasak
- aşırı blur yasak
- readability düşüren efektler yasak
- stil, UX context olmadan seçilemez

---

# 🧠 FINAL PRINCIPLE

Style is not visual design.

Style = user attention + decision behavior system.