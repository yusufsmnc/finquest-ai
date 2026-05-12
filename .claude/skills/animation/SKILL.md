name: animation-skill

---

# 🎯 PURPOSE

Defines all motion, transition, and feedback behavior rules for FinQuest AI.

Used by Animation Agent ONLY.

Does NOT define:
- UI layout
- gamification rules
- business logic

---

# 🧠 CORE PRINCIPLE

Animation = feedback communication system

Every animation must:
- confirm action
- reinforce outcome
- reduce cognitive delay

---

# ⚙️ MOTION SYSTEM RULES

## 1. FEEDBACK TYPES

Every user action maps to:

### A) SUCCESS FEEDBACK
- smooth scale-up
- green glow pulse
- quick easing (200–400ms)

---

### B) ERROR FEEDBACK
- subtle shake
- red fade flash
- short duration (150–250ms)

---

### C) NEUTRAL FEEDBACK
- soft transition
- no aggressive motion

---

## 2. GAMIFICATION ANIMATIONS

### XP GAIN
- particle burst (subtle)
- upward float animation
- glow pulse

---

### LEVEL UP
- full screen expansion animation
- slow fade-in overlay
- celebratory motion burst

---

### STREAK UPDATE
- incremental counter animation
- pulse effect on number

---

## 3. TRANSITION RULES

Screen transitions:

- Scenario → Decision → Feedback
- Must feel continuous, not page-based

Rules:
- no hard cuts
- always use directional motion (slide/fade)

---

## 4. MOTION TIMING SYSTEM

| Type | Duration |
|------|--------|
| micro feedback | 100–200ms |
| interaction feedback | 200–400ms |
| screen transition | 300–600ms |
| reward animation | 600–1200ms |

---

## 5. EASING RULES

- Default: ease-out
- Feedback: sharp ease-out
- Rewards: elastic / spring
- Transitions: smooth cubic-bezier

---

## 6. PERFORMANCE RULES

- No blocking animations
- No layout rebuild-heavy animations
- Prefer implicit animations
- Avoid overuse of blur effects

---

## 7. ACCESSIBILITY RULES

- Respect reduced motion settings
- Always provide non-animation fallback
- Never rely on animation alone for meaning

---

# 🚫 FORBIDDEN RULES

- No gamification logic inside animations
- No UI redesign decisions
- No backend assumptions
- No heavy particle systems by default

---

# 🧠 FINAL PRINCIPLE

Animation is not decoration.

Animation is **real-time feedback language for user decisions**.