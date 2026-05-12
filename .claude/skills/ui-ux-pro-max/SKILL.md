# UI/UX Pro Max (FinQuest AI - Decision Engine v2)

## NE ZAMAN TETİKLENİR
- UI/UX tasarımı istendiğinde
- Screen / layout / component design gerektiğinde
- Design system kararı gerektiğinde

---

# 📦 0. INPUT CONTRACT (ZORUNLU)

UI Agent sadece şu input ile çalışır:

INPUT:
- Feature Request (Planner output)
- Screen Type
- Gamification Intent (read-only)
- Existing Components (optional)
- UX Pro Max Ruleset (this document)

---

# 📤 1. OUTPUT CONTRACT (ZORUNLU)

UI Agent HER ZAMAN şu formatta çıktı üretir:

## UX DECISION SUMMARY
- Screen Type:
- Decision Pressure:
- Gamification Level:
- Emotional Tone:
- Cognitive Load:

---

## DESIGN SYSTEM SELECTION
- Style:
- Color Palette:
- Typography:
- Component Set:

---

## COMPONENT TREE
- Layout structure
- Component hierarchy

---

## STATE MODEL
- loading
- empty
- error
- success
- active

---

## INTERACTION FLOW
- step-by-step user journey

---

# 🧠 2. UX DECISION CONTEXT LAYER (ZORUNLU)

Her UI üretimi öncesi analiz:

- Screen Type  
  (Dashboard / Scenario / Reward / Onboarding / AI Insight / Profile)

- Decision Pressure  
  (Low / Medium / High)

- Gamification Intensity  
  (Low / Medium / High)

- Emotional Tone  
  (Calm / Focused / Urgent / Rewarding / Educational)

- Cognitive Load  
  (Low / Medium / High)

📌 KURAL:
Bu analiz olmadan UI üretilemez.

---

# 🧠 3. CONTEXT ANALYSIS

- Kullanıcı ne yapmak istiyor?
- Bu ekranın amacı ne?
- Kullanıcı hangi karar anında?

---

# 🎨 4. STYLE SELECTION (DETERMINISTIC)

styles.md mapping:

- Scenario → Scenario Decision Mode
- Dashboard → Fintech Clean / Bento Grid
- Reward → Gamification Neon Mode
- AI Insight → Glass UI

📌 KURAL:
- Stil seçimleri sadece context + rule ile yapılır
- Random seçim YOK

---

# 🎯 5. COLOR SYSTEM RULES

palettes.md:

- Risk → Red / Green contrast
- AI → Violet / Cyan
- Reward → Neon Green / Purple

📌 KURAL:
Color = behavioral signal

---

# 🔤 6. TYPOGRAPHY RULES

fonts.md:

- Fintech → Inter + JetBrains Mono
- AI → Space Grotesk + Inter
- Gamification → Poppins

📌 KURAL:
Max 2 font

---

# 🧩 7. COMPONENT RULES

components.md:

- ScenarioCard
- XPProgressBar
- RiskIndicator
- AIInsightCard

📌 RULE:
- %80 reuse
- %20 custom allowed

---

# ⚖️ 8. DECISION PRIORITY SYSTEM

1. UX CLARITY (highest)
2. Decision Speed
3. Gamification Feedback
4. Visual Consistency
5. Reusability

📌 Conflict varsa üstteki kazanır

---

# 🔁 9. DETERMINISM RULE

Same input = same output

If multiple valid options exist:
- Default style always preferred
- Context override must be explicit

---

# 📐 10. LAYOUT RULES

- Mobile-first
- Single decision focus per screen
- Max 1 primary interaction zone
- No cognitive overload

---

# 📊 11. UI STATES

Her component:

- loading
- empty
- error
- success
- active

---

# 🎮 12. GAMIFICATION UI RULES

- XP always visible feedback
- Level up always animated
- Reward = immediate feedback
- Risk always visible

---

# ⚙️ 13. RESPONSIVE RULES

| Device | Behavior |
|--------|----------|
| <600   | mobile   |
| 600–1024 | tablet |
| >1024  | optional web |

---

# ♿ 14. ACCESSIBILITY RULES

- min tap target: 48px
- contrast ≥ 4.5:1
- semantic grouping required
- icon-only critical actions forbidden

---

# 🚫 15. STRICT RULES

- NO backend logic
- NO gamification logic
- NO animation implementation
- NO design system override
- NO random decisions

---

# 🧠 16. CORE PHILOSOPHY

UI is not design.

UI is a decision shaping system.

Every screen must support:

decision → feedback → reward loop