# Color System — FinQuest AI

Bu dosya `ui-ux-pro-max` skill tarafından kullanılır.  
UI-Agent, tüm ekranlarda **renk kararlarını buradan alır**.

---

# 🧠 CORE RULE

## RENK = DAVRANIŞ SİNYALİ

FinQuest AI’de renkler sadece görsel değil, aynı zamanda:

- bilgi hiyerarşisi
- gamification feedback
- risk algısı
- AI sinyali
- kullanıcı karar yönlendirme

---

# 🎯 1. CORE FINTECH PALETTES

---

## FINTECH DARK (DEFAULT SYSTEM)

### Colors
- bg: #0B0F1A
- surface: #111827
- primary: #3B82F6
- secondary: #6366F1
- text: #E5E7EB
- muted: #9CA3AF

### Kullanım
- dashboard
- scenario screens
- portfolio

### Neden
- güven hissi
- finansal stabilite
- düşük bilişsel yük

---

## GAMIFICATION NEON (REWARD SYSTEM)

### Colors
- bg: #050505
- primary: #22C55E
- accent: #A855F7
- warning: #F59E0B
- danger: #EF4444

### Kullanım
- XP gain
- level up
- reward screens

### Neden
- yüksek enerji
- ödül hissi
- dopamine feedback loop

---

## AI INSIGHT THEME

### Colors
- bg: #0F172A
- primary: #8B5CF6
- secondary: #06B6D4
- text: #F8FAFC
- muted: #94A3B8

### Kullanım
- AI mentor
- insight cards
- analysis screens

### Neden
- AI / intelligence hissi
- modern SaaS görünüm

---

## RISK / MARKET THEME

### Colors
- bg: #0A0A0A
- gain: #16A34A
- loss: #DC2626
- neutral: #64748B
- warning: #F97316

### Kullanım
- scenario decision UI
- market movements
- trading simulation

### Neden
- net risk ayrımı
- hızlı karar verme

---

## EDUCATION / ONBOARDING

### Colors
- bg: #F8FAFC
- primary: #2563EB
- secondary: #0EA5E9
- text: #0F172A
- muted: #64748B

### Kullanım
- onboarding
- tutorial
- learning screens

### Neden
- düşük bilişsel yük
- maksimum okunabilirlik

---

# 📊 ACCESSIBILITY RULES

- minimum contrast: 4.5:1
- color tek başına bilgi taşıyamaz (icon + text zorunlu)
- error state sadece kırmızıya bağlı olamaz
- XP feedback sadece renk ile verilmez (animation + haptic gerekir)

---

# 🎮 GAMIFICATION COLOR RULES

- XP gain → green pulse + glow
- level up → purple burst animation
- loss → red shake + fade
- AI insight → violet glow
- neutral info → calm blue tone

---

# ⚙️ FLUTTER IMPLEMENTATION RULE

UI-Agent her zaman `ColorScheme` üretirken:

- hardcoded random color ❌
- palette dışı renk ❌
- consistency dışı theme ❌

### Example (Flutter)

```dart id="theme_dark_finquest"
final ColorScheme darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF3B82F6),
  secondary: Color(0xFF6366F1),
  background: Color(0xFF0B0F1A),
  surface: Color(0xFF111827),
  error: Color(0xFFEF4444),
  onPrimary: Colors.white,
  onBackground: Color(0xFFE5E7EB),
  onSurface: Color(0xFFE5E7EB),
  onError: Colors.white,
);