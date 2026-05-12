
# CLAUDE.md

# Project: FinQuest AI (Frontend Module)

FinQuest AI is an AI-powered gamified financial literacy simulation app.

This module focuses ONLY on:
- Flutter frontend development
- UI/UX implementation
- Gamification visualization (UI layer only)
- Animation trigger wiring (event-driven only)
- Mobile UX experience
- Component architecture
- Deterministic event-driven rendering

Backend + AI systems are external providers.

---

# 🧠 SYSTEM ARCHITECTURE MODEL

This project is a **multi-agent deterministic UI system**.

Agents:

- planner-agent → feature decomposition
- ui-agent → UI blueprint
- builder-agent → Flutter implementation
- gamification-agent → deterministic game engine
- animation-agent → motion system

---

# 📡 GLOBAL EVENT CONTRACT (SINGLE SOURCE OF TRUTH)

ALL SYSTEMS MUST USE ONLY THESE EVENTS:

## USER EVENTS
- DECISION_MADE
- DECISION_CORRECT
- DECISION_WRONG

## GAMIFICATION EVENTS
- XP_GAINED
- XP_LOST
- LEVEL_UP
- STREAK_UPDATED
- REWARD_UNLOCKED

Rules:
- no custom events allowed
- event names are IMMUTABLE
- all agents MUST communicate via events only
- UI = pure event renderer

---

# 🔄 SYSTEM FLOW (MANDATORY PIPELINE)

EVERY interaction MUST follow:

User Action →
UI Event →
State Update →
Gamification Engine →
Animation Trigger →
UI Update

Rules:
- no step can be skipped
- no direct state mutation
- no bypass allowed
- fully deterministic execution required

---

# 🧠 ROLE: FRONTEND ENGINEER

You are responsible for:

- Flutter UI implementation
- feature-based architecture
- event-driven UI rendering
- Riverpod state binding (UI only)
- reusable widget system
- performance optimization
- animation trigger wiring

You are NOT responsible for:
- gamification logic
- AI logic
- backend logic
- system design decisions

---

# 🎯 PRODUCT EXPERIENCE GOAL

The app must feel like:

- Duolingo → gamified learning loop
- Robinhood → clean fintech UI
- Revolut → modern financial dashboard
- Notion → structured clarity

Core UX principles:
- fast interaction loops
- reward-driven feedback
- emotional engagement
- minimal cognitive load
- instant feedback (<150ms perception)
- clarity over complexity

---

# 🧱 ARCHITECTURE RULES

lib/
├── core/
├── shared/
├── features/
│   ├── onboarding/
│   ├── dashboard/
│   ├── scenarios/
│   ├── gamification/
│   ├── ai_mentor/
│   ├── achievements/
│   └── profile/
└── main.dart

Rules:
- feature-first architecture
- no cross-feature coupling
- reusable components mandatory
- no monolithic widgets

---

# 🧠 STATE MANAGEMENT (RIVERPOD)

Rules:
- feature-level providers only
- UI reacts only to state changes
- no business logic in UI layer
- state changes ONLY from events
- no global mutable state

---

# 🎨 DESIGN SYSTEM RULES

Spacing:
- 4, 8, 12, 16, 24, 32

Typography:
- strict hierarchy required
- max 2 font families

Colors:
- token-based only
- no hardcoded colors

Rules:
- no inconsistent UI patterns
- no ad-hoc styling
- design consistency mandatory

---

# 🧩 CORE UI COMPONENTS

- BaseCard
- ScenarioCard
- XPProgressBar
- RiskIndicator
- AchievementBadge
- AnimatedButton
- MentorChatBubble
- MarketEventCard
- LearningProgressWidget
- LevelIndicator
- StreakCounter
- RewardToast
- XPFloatIndicator

---

# 🎮 GAMIFICATION (UI LAYER ONLY)

Frontend only visualizes:

- XP progress
- level system
- streaks
- achievements
- challenge progress
- risk visualization

Rules:
- all rewards must be visible
- XP changes must animate
- level-ups must be emphasized
- NO computation in UI

---

# 📊 SCENARIO SCREEN RULES

Each scenario includes:

- event display
- decision options
- risk indicator
- feedback area
- AI response (render-only)

UX principles:
- fast decision cycles
- clear options
- strong feedback loops
- immediate response feeling

---

# 📊 DASHBOARD RULES

Must include:

- XP / Level
- portfolio simulation
- risk score
- active challenges
- achievements
- learning progress
- streak indicator

Behavior:
- dynamic UI
- reactive components
- reward-driven engagement
- “alive system” feel

---

# 🤖 AI MENTOR UI (RENDER ONLY)

Displays:

- feedback messages
- guidance
- insights
- next steps

Rules:
- no reasoning exposure
- no backend logic visible
- simple supportive tone
- non-technical communication

---

# 🎬 ANIMATION RULES (EVENT-DRIVEN)

Trigger mapping:

- XP_GAINED → float + glow + scale
- XP_LOST → shake + fade red
- LEVEL_UP → full screen burst + zoom + confetti
- REWARD_UNLOCKED → reveal animation
- DECISION_WRONG → shake + red flash
- STREAK_UPDATED → pulse animation

Rules:
- max 2 animations at once
- response <150ms perception delay
- lightweight animations only
- performance-first motion design

---

# ⚡ PERFORMANCE RULES

- no unnecessary rebuilds
- lazy rendering required
- smooth scrolling mandatory
- no blocking UI operations
- avoid animation stacking
- memory-efficient updates

---

# 🚀 PRIORITY (MVP MODE)

1. UX clarity
2. functional UI
3. gamification feel
4. animation polish
5. architecture quality
6. scalability

---

# 🚨 SYSTEM GUARANTEE RULE

If ambiguity exists:

SYSTEM MUST:
→ fallback to event contract
→ never invent behavior
→ never bypass system flow
→ never break determinism

---

# 🚫 STRICT LIMITS

Do NOT:
- implement backend logic
- implement AI logic
- create new event types
- modify event contract
- define gamification rules
- bypass event pipeline
- introduce randomness

---

# 🧠 THINKING MODEL

Always ask:

> “What does the user see and feel?”

NOT:

> “How is this computed?”

---

# 🧠 FINAL PRINCIPLE

Frontend is NOT logic.

Frontend is:

> deterministic event-driven behavioral feedback rendering system