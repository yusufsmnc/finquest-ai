# Component Library — FinQuest AI

Bu dosya `ui-ux-pro-max` skill tarafından referans alınır.  
UI-Agent, Flutter ekranlarını tasarlarken **hangi component kullanılacağını buradan seçer**.

---

# 🧠 0. CORE RULE

Yeni widget yazmadan önce:

1. Flutter Material 3 componentleri kontrol edilir  
2. shared/widgets içinde reusable component aranır  
3. %80 durumda custom widget yazılmaz  

---

# 🎮 1. BASE FLUTTER COMPONENTS

---

## BUTTON

### Varyantlar
- primary
- secondary
- ghost
- destructive

### States
- default
- pressed
- disabled
- loading

### Interaction Rules
- haptic feedback zorunlu
- XP trigger tetikleyebilir
- loading state UI bloklamamalı

### Accessibility
- semantic label zorunlu
- loading → `Semantics(loading: true)`

### Kullanım
- decision actions (BUY / SELL / HOLD)
- scenario selection
- quiz interactions

---

## CARD (CORE BLOCK)

### Structure
- Header → title + risk level
- Body → scenario / data
- Footer → actions + XP feedback

### Variants
- scenario_card
- dashboard_card
- reward_card

### Usage
- scenario display
- portfolio summary
- AI feedback UI

---

## INPUT

### Structure
- Label
- Field
- Helper text
- Error state

### States
- typing
- validating
- error
- success

### Usage
- AI mentor chat
- profile settings
- feedback forms

---

## DIALOG / BOTTOM SHEET

### Usage
- XP gain popup
- AI feedback reveal
- level up screen

### Rules
- dismiss on outside tap
- back button support
- lightweight content only

---

## NAVIGATION BAR

### Tabs
- Dashboard
- Scenarios
- AI Mentor
- Profile

### Rules
- active state indicator
- semantic labels required
- bottom navigation only (mobile-first)

---

# 🎯 2. FINQUEST DOMAIN COMPONENTS

---

## SCENARIO CARD (CORE GAME UNIT)

### Structure
- Market Event Title
- Risk Indicator (low / medium / high)
- Scenario Description
- Decision Buttons
- XP Preview

### States
- active
- completed
- locked

### Animation Intent (NOT implementation)
- entry transition (smooth slide)
- XP feedback pulse on decision

---

## DASHBOARD LAYOUT

### Structure
- TopBar (XP + Level)
- Portfolio Summary Card
- AI Insight Card
- Active Scenario List

### Layout Rule
- vertical scroll
- mobile-first stacking

---

## XP REWARD CARD

### Content
- XP gained value
- progress bar
- level change indicator

### Trigger Events
- correct decision
- streak reward

---

## AI INSIGHT CARD

### Content
- feedback text
- reasoning
- suggestion

### UI Style
- subtle highlight
- non-intrusive design
- readability first

---

# 📊 3. STATE SYSTEM (MANDATORY FOR ALL COMPONENTS)

Her component şu state’leri desteklemek zorunda:

- loading (skeleton UI)
- empty (no data state)
- error (failure state)
- success (normal state)
- active (interaction state)

---

# 📱 4. RESPONSIVE SYSTEM

| Breakpoint | Behavior |
|------------|----------|
| <600       | mobile (default) |
| 600–1024   | tablet adaptation |
| >1024      | optional web layout |

---

# 🎮 5. GAMIFICATION UI RULES

- XP hiçbir zaman sessiz verilmez
- her action → feedback üretir
- level up → animasyon zorunlu
- risk bilgisi her zaman görünür
- reward = immediate feedback loop

---

# ⚙️ 6. DESIGN PRINCIPLES

- Mobile-first design
- Minimal cognitive load
- Fast decision UX (≤3 sec comprehension)
- Feedback-driven interaction system

---

# ♿ 7. ACCESSIBILITY RULES

- min tap target: 48px
- contrast ≥ 4.5:1
- semantic grouping zorunlu
- icon-only critical actions yasak

---

# 🧠 8. CORE PHILOSOPHY

UI is not static layout.

UI is a:

> real-time decision + feedback interaction system