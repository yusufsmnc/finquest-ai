"""The authoritative XP / level / streak rules, in isolation from HTTP and the DB."""

from __future__ import annotations

import pytest

from app.models.progress import Progress
from app.services.gamification import (
    XP_CORRECT,
    XP_PER_LEVEL,
    XP_WRONG,
    apply_decision,
    level_for_xp,
)


def _progress(xp: int = 0, level: int = 1, streak: int = 0) -> Progress:
    """A detached model instance — these rules never touch the session."""
    return Progress(xp=xp, level=level, streak_count=streak)


# ── The level curve ────────────────────────────────────────────────────────


@pytest.mark.parametrize(
    ("xp", "expected"),
    [
        (0, 1),
        (1, 1),
        (99, 1),
        (100, 2),  # boundary: the first level-up lands exactly on 100
        (101, 2),
        (199, 2),
        (200, 3),
        (1000, 11),
        (-50, 1),  # never below level 1, whatever the input
    ],
)
def test_level_for_xp(xp: int, expected: int):
    assert level_for_xp(xp) == expected


def test_level_curve_is_one_level_per_hundred_xp():
    assert level_for_xp(XP_PER_LEVEL) == level_for_xp(0) + 1


# ── XP thresholds ──────────────────────────────────────────────────────────


def test_a_correct_decision_awards_the_fixed_reward():
    progress = _progress(xp=40)

    outcome = apply_decision(progress, correct=True)

    assert progress.xp == 40 + XP_CORRECT
    assert outcome.xp_delta == XP_CORRECT
    assert outcome.result == "DECISION_CORRECT"


def test_a_wrong_decision_deducts_the_fixed_penalty():
    progress = _progress(xp=40)

    outcome = apply_decision(progress, correct=False)

    assert progress.xp == 40 + XP_WRONG
    assert outcome.xp_delta == XP_WRONG
    assert outcome.result == "DECISION_WRONG"


def test_xp_never_goes_below_zero():
    progress = _progress(xp=5)

    apply_decision(progress, correct=False)

    assert progress.xp == 0


def test_the_reported_delta_is_the_change_actually_applied():
    """At 5 XP a wrong answer costs 5, not the nominal 10.

    The frontend derives its XP_LOST amount from this delta when it has no
    previous snapshot to diff against, so a nominal -10 would animate XP the
    user never had.
    """
    progress = _progress(xp=5)

    outcome = apply_decision(progress, correct=False)

    assert progress.xp == 0
    assert outcome.xp_delta == -5


def test_a_wrong_decision_at_zero_xp_reports_no_change():
    progress = _progress(xp=0)

    outcome = apply_decision(progress, correct=False)

    assert progress.xp == 0
    assert outcome.xp_delta == 0


# ── Streak ─────────────────────────────────────────────────────────────────


def test_a_correct_decision_extends_the_streak():
    progress = _progress(streak=4)

    apply_decision(progress, correct=True)

    assert progress.streak_count == 5


def test_a_wrong_decision_resets_the_streak_to_zero():
    progress = _progress(streak=9)

    apply_decision(progress, correct=False)

    assert progress.streak_count == 0


# ── Events ─────────────────────────────────────────────────────────────────


def test_correct_decision_emits_the_contract_events_in_order():
    outcome = apply_decision(_progress(), correct=True)

    assert outcome.events == [
        "DECISION_MADE",
        "DECISION_CORRECT",
        "XP_GAINED",
        "STREAK_UPDATED",
    ]


def test_wrong_decision_emits_the_contract_events_in_order():
    outcome = apply_decision(_progress(xp=50), correct=False)

    assert outcome.events == [
        "DECISION_MADE",
        "DECISION_WRONG",
        "XP_LOST",
        "STREAK_UPDATED",
    ]


def test_crossing_a_level_boundary_emits_level_up():
    progress = _progress(xp=90, level=1)

    outcome = apply_decision(progress, correct=True)

    assert progress.level == 2
    assert "LEVEL_UP" in outcome.events


def test_staying_inside_a_level_does_not_emit_level_up():
    progress = _progress(xp=10, level=1)

    outcome = apply_decision(progress, correct=True)

    assert progress.level == 1
    assert "LEVEL_UP" not in outcome.events


def test_losing_a_level_updates_it_without_emitting_level_up():
    """Dropping below the boundary lowers the level, but LEVEL_UP is for gains."""
    progress = _progress(xp=100, level=2)

    outcome = apply_decision(progress, correct=False)

    assert progress.xp == 90
    assert progress.level == 1
    assert "LEVEL_UP" not in outcome.events


def test_every_emitted_event_belongs_to_the_frontend_contract():
    """No invented event names — the contract in CLAUDE.md is immutable."""
    contract = {
        "DECISION_MADE",
        "DECISION_CORRECT",
        "DECISION_WRONG",
        "XP_GAINED",
        "XP_LOST",
        "LEVEL_UP",
        "STREAK_UPDATED",
        "REWARD_UNLOCKED",
    }

    for correct in (True, False):
        for xp in (0, 5, 90, 100, 999):
            outcome = apply_decision(_progress(xp=xp, level=level_for_xp(xp)), correct)
            assert set(outcome.events) <= contract


def test_last_active_is_stamped():
    progress = _progress()
    assert progress.last_active is None

    apply_decision(progress, correct=True)

    assert progress.last_active is not None
