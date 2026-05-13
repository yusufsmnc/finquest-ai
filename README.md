# FinQuest AI

A gamified financial literacy simulation app built with Flutter. Users face real-world financial scenarios, make decisions, earn XP, and learn from an AI mentor — all in a clean, fast, reward-driven interface.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41.9 / Dart 3.11.5 |
| State Management | Riverpod 2.x (NotifierProvider) |
| Architecture | Feature-first, event-driven |
| Event Contract | Global immutable GameEvent system |
| Target | Web (Edge), Mobile-ready |

---

## Architecture

```
lib/
├── core/
│   ├── events/          # Global GameEvent contract (immutable)
│   └── routing/         # AppRouter
├── shared/
│   └── widgets/         # Reusable components
├── features/
│   ├── onboarding/      # ✅ Implemented
│   ├── dashboard/       # ✅ Implemented
│   ├── scenarios/       # ✅ Implemented
│   ├── gamification/    # ✅ Implemented
│   ├── achievements/    # ✅ Implemented
│   ├── ai_mentor/       # 🔜 Next
│   └── profile/         # 🔜 Planned
└── main.dart
```

Every interaction follows a strict pipeline:

```
User Action → UI Event → State Update → Gamification Engine → Animation Trigger → UI Update
```

---

## Features

### ✅ Onboarding
- 5-step gamified introduction flow
- XP reveal animation on first launch
- Decision-making intro (first taste of the scenario system)
- Level-up screen with animated progression
- Mentor introduction

### ✅ Dashboard
- XP hero card with animated progress bar
- Level indicator + streak counter
- Active challenges section
- Portfolio simulation with sparkline chart
- Learning progress by category
- Achievements showcase
- AI Mentor card (static preview)
- XP float animation on earn
- Reward toast on unlock

### ✅ Scenario Decision System
- Scenario list with category filter (Investing / Savings / Budgeting)
- Risk level indicator (Low / Medium / High) with bar visual
- Financial event card with full scenario description
- Multiple choice decision (A/B options, locks on tap)
- Feedback screen: result banner, XP summary, mentor explanation
- Correct decision bonus (+50 XP)
- Streak tracking with pulse animation
- Reward toast every 3 correct decisions
- AnimatedSwitcher phase transitions (list → decision → feedback)

### ✅ Achievements System
- 14 collectible achievements across 4 categories (Streak / XP / Decisions / Level)
- Rarity system: Common · Rare · Epic · Legendary with distinct color palettes
- 2-column grid with rarity-styled cards (locked/unlocked states, progress bars)
- Achievement detail modal — progress section, reward preview, unlock date
- Category filter bar (animated chips)
- Gradient stats header with per-category breakdown
- Fully event-driven unlock detection (XP_GAINED, STREAK_UPDATED, DECISION_CORRECT, LEVEL_UP)
- Triple-dispatch pipeline: feature notifier → overlay notifier → achievements notifier
- Auto-triggers `AchievementUnlockOverlay` on new unlock via global overlay system
- Progress bars update incrementally on locked achievements
- Navigable from Dashboard via trophy FAB

### ✅ Gamification Overlay System
- **Level Up Modal** — full-screen celebration with 12 confetti dots, fires every 200 XP
- **Streak Feedback Overlay** — scale-bounce animation on 2+ day streaks
- **XP Lost Overlay** — red shake banner slides in from top
- **Achievement Unlock Overlay** — slides in from bottom, gold badge, 2.5s auto-dismiss
- **Gamification Toast Queue** — sequential toast system, auto-advances every 2s
- **Global Overlay Manager** — wraps entire app, overlays appear on any screen
- All overlays are purely event-driven via the GameEvent contract

---

## Gamification System

All game logic flows through a deterministic event contract:

| Event | Trigger | Effect |
|---|---|---|
| `DECISION_MADE` | User taps an option | Records selection, increments total decisions |
| `DECISION_CORRECT` | Correct option chosen | Increments correct count, sets isCorrect |
| `DECISION_WRONG` | Wrong option chosen | Sets isCorrect false |
| `XP_GAINED` | Any decision | Adds XP, shows float indicator, detects level-up |
| `XP_LOST` | Penalty (future) | Shows red shake banner |
| `LEVEL_UP` | Every 200 XP | Full-screen level-up modal with confetti |
| `STREAK_UPDATED` | After each decision | Updates streak, triggers bounce animation |
| `REWARD_UNLOCKED` | Every 3 correct answers | Shows toast in global queue |

---

## Shared Widget Library

| Widget | Description |
|---|---|
| `XPFloatIndicator` | Floats up 40px when XP is earned |
| `RewardToast` | Slides in from bottom on reward unlock |
| `XPProgressBar` | Animated fill bar |
| `RiskIndicator` | 3-bar visual (compact + large variants) |
| `AchievementBadge` | Badge with locked/unlocked state |
| `StreakCounter` | Flame icon + count |
| `LevelIndicator` | Current level display |
| `MentorChatBubble` | AI mentor message bubble |
| `AchievementCard` | Rarity-styled card with locked/unlocked states |
| `AchievementDetailModal` | Bottom sheet with progress, reward preview, unlock date |
| `AchievementsStatsHeader` | Gradient header with completion % and category breakdown |
| `AchievementsFilterBar` | Animated category filter chips |

---

## Running the App

```bash
flutter pub get
flutter run -d edge
```

Requires Flutter 3.x and Chrome/Edge browser for web target.