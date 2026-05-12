name: gamification-skill

---

# 🎯 PURPOSE

This file is a PURE SPECIFICATION CONTRACT.

It defines ONLY:
- system rules
- constraints
- allowed events
- behavioral definitions

It contains ZERO formulas.
It contains ZERO computation logic.
It contains ZERO execution details.

---

# 🧠 CORE PRINCIPLE

This is the "WHAT layer".

Execution happens elsewhere.

---

# ⚙️ SYSTEM DEFINITIONS

## XP SYSTEM (CONCEPTUAL)

XP represents user progress signal.

It is influenced by:
- decision correctness
- risk level
- streak state
- difficulty level

---

## LEVEL SYSTEM (CONCEPTUAL)

Level represents user mastery state.

Rules:
- level is monotonic (never decreases)
- level is derived from XP (logic external)
- level-up is a system event

---

## STREAK SYSTEM

A streak represents consecutive correct decisions.

Rules:
- increases on correct decisions
- resets on incorrect decisions
- affects reward intensity

---

## RISK MODEL

Risk levels:

- low
- medium
- high

Definition:
Risk modifies reward importance (not calculation).

---

## REWARD SYSTEM

Reward types:

- XP reward
- badge unlock
- level-up event
- achievement unlock

Rules:
- rewards must always be visible
- no hidden rewards
- cooldowns are enforced externally

---

## PENALTY SYSTEM

Rules:
- only applied on incorrect decisions
- level never decreases
- XP floor ≥ 0

---

## EVENT CONTRACT

Allowed events only:

- DECISION_MADE
- XP_GRANTED
- XP_LOST
- LEVEL_UP
- STREAK_UPDATED
- REWARD_UNLOCKED

No custom events allowed.

---

## SYSTEM CONSTRAINTS

- no randomness allowed
- no hidden logic
- no silent progression changes
- no negative progression
- all updates must be observable

---

# 🧠 FINAL PRINCIPLE

This file defines rules only.

It does NOT compute anything.