"""``POST /scenarios/{id}/decision`` end to end, against a real database."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.scenario_history import ScenarioHistory


def _decide(
    client: TestClient, auth, *, correct: bool, scenario: str = "emergency-fund"
):
    return client.post(
        f"/scenarios/{scenario}/decision",
        json={"choice": "build-a-buffer", "correct": correct},
        headers=auth,
    )


# ── The response ───────────────────────────────────────────────────────────


def test_a_correct_decision_awards_xp_and_returns_the_new_progress(
    client: TestClient, auth
):
    body = _decide(client, auth, correct=True).json()

    assert body["result"] == "DECISION_CORRECT"
    assert body["xp_delta"] == 20
    assert body["progress"]["xp"] == 20
    assert body["progress"]["streak_count"] == 1
    assert body["progress"]["decisions_made"] == 1


def test_a_wrong_decision_deducts_xp_and_breaks_the_streak(client: TestClient, auth):
    for _ in range(3):
        _decide(client, auth, correct=True)

    body = _decide(client, auth, correct=False).json()

    assert body["result"] == "DECISION_WRONG"
    assert body["xp_delta"] == -10
    assert body["progress"]["xp"] == 50
    assert body["progress"]["streak_count"] == 0


def test_the_event_burst_matches_the_frontend_contract(client: TestClient, auth):
    body = _decide(client, auth, correct=True).json()

    assert body["events"][:4] == [
        "DECISION_MADE",
        "DECISION_CORRECT",
        "XP_GAINED",
        "STREAK_UPDATED",
    ]


def test_an_unlock_appends_reward_unlocked(client: TestClient, auth):
    """The first correct answer trips ``streak_first``."""
    body = _decide(client, auth, correct=True).json()

    assert body["new_achievements"] == ["streak_first"]
    assert body["events"][-1] == "REWARD_UNLOCKED"


def test_no_unlock_means_no_reward_event(client: TestClient, auth):
    _decide(client, auth, correct=True)  # takes streak_first

    body = _decide(client, auth, correct=False).json()

    assert body["new_achievements"] == []
    assert "REWARD_UNLOCKED" not in body["events"]


def test_crossing_a_level_boundary_reports_level_up(client: TestClient, auth):
    for _ in range(4):
        _decide(client, auth, correct=True)  # 80 XP, still level 1

    body = _decide(client, auth, correct=True).json()  # 100 XP

    assert body["progress"]["level"] == 2
    assert "LEVEL_UP" in body["events"]


def test_xp_is_clamped_at_zero_and_the_delta_reports_the_real_loss(
    client: TestClient, auth
):
    """The frontend animates this delta — it must not exceed what was lost."""
    _decide(client, auth, correct=True)  # 20 XP
    _decide(client, auth, correct=False)  # 10 XP

    body = _decide(client, auth, correct=False).json()  # would be -10, only 10 left

    assert body["progress"]["xp"] == 0
    assert body["xp_delta"] == -10

    floored = _decide(client, auth, correct=False).json()

    assert floored["progress"]["xp"] == 0
    assert floored["xp_delta"] == 0, "nothing was lost, so nothing may be animated"


# ── Persistence ────────────────────────────────────────────────────────────


def test_the_decision_is_written_to_scenario_history(
    client: TestClient, auth, db_session: Session
):
    _decide(client, auth, correct=True, scenario="rainy-day")

    row = db_session.scalars(select(ScenarioHistory)).one()
    assert row.scenario_id == "rainy-day"
    assert row.choice == "build-a-buffer"
    assert row.result == "DECISION_CORRECT"
    assert row.xp_delta == 20


def test_history_records_the_clamped_delta_too(
    client: TestClient, auth, db_session: Session
):
    _decide(client, auth, correct=False)

    row = db_session.scalars(select(ScenarioHistory)).one()
    assert row.xp_delta == 0


def test_decision_counters_accumulate(client: TestClient, auth):
    for _ in range(3):
        body = _decide(client, auth, correct=True).json()

    assert body["progress"]["decisions_made"] == 3
    assert body["progress"]["decisions_today"] == 3


def test_progress_survives_a_later_request(client: TestClient, auth):
    _decide(client, auth, correct=True)

    assert client.get("/me/progress", headers=auth).json()["xp"] == 20


def test_decisions_25_unlocks_after_the_twenty_fifth(client: TestClient, auth):
    """Exercises the decision-count criterion through the real counter."""
    unlocked: list[str] = []
    for _ in range(25):
        unlocked += _decide(client, auth, correct=True).json()["new_achievements"]

    assert "decisions_5" in unlocked
    assert "decisions_25" in unlocked


# ── Isolation and validation ───────────────────────────────────────────────


def test_one_users_decisions_do_not_move_another(client: TestClient, register):
    active, bystander = register(), register()

    for _ in range(3):
        _decide(client, active, correct=True)

    body = client.get("/me/progress", headers=bystander).json()
    assert body["xp"] == 0
    assert body["decisions_made"] == 0


def test_decision_requires_authentication(client: TestClient):
    response = client.post(
        "/scenarios/x/decision", json={"choice": "a", "correct": True}
    )

    assert response.status_code == 401


@pytest.mark.parametrize(
    "payload",
    [
        pytest.param({"choice": "a"}, id="missing_correct"),
        pytest.param({"correct": True}, id="missing_choice"),
        pytest.param({"choice": "a", "correct": "maybe"}, id="non_boolean_correct"),
    ],
)
def test_decision_validates_its_body(client: TestClient, auth, payload):
    response = client.post("/scenarios/x/decision", json=payload, headers=auth)

    assert response.status_code == 422


# ── Derived profile statistics (Faz 7b) ────────────────────────────────────
#
# The Profile screen renders these; it does not recompute them. That is the
# whole point — a reload must not be able to disagree with the server about how
# many decisions were made or how many were right.


def test_accuracy_over_a_mixed_run(client: TestClient, auth):
    """Three right out of four."""
    for _ in range(3):
        _decide(client, auth, correct=True)
    _decide(client, auth, correct=False)

    body = client.get("/me/progress", headers=auth).json()

    assert body["decisions_made"] == 4
    assert body["correct_decisions"] == 3
    assert body["accuracy"] == pytest.approx(0.75)


def test_accuracy_is_zero_before_any_decision(client: TestClient, auth):
    body = client.get("/me/progress", headers=auth).json()

    assert body["decisions_made"] == 0
    assert body["correct_decisions"] == 0
    assert body["accuracy"] == 0.0, "no division by zero, no NaN"


def test_accuracy_is_one_when_nothing_was_missed(client: TestClient, auth):
    for _ in range(3):
        _decide(client, auth, correct=True)

    assert client.get("/me/progress", headers=auth).json()["accuracy"] == 1.0


def test_accuracy_is_zero_when_everything_was_missed(client: TestClient, auth):
    for _ in range(2):
        _decide(client, auth, correct=False)

    body = client.get("/me/progress", headers=auth).json()

    assert body["decisions_made"] == 2
    assert body["correct_decisions"] == 0
    assert body["accuracy"] == 0.0


def test_xp_earned_total_counts_gross_not_net(client: TestClient, auth):
    """Wrong answers deduct from `xp`; they do not un-earn what was earned."""
    for _ in range(3):
        _decide(client, auth, correct=True)  # +60
    _decide(client, auth, correct=False)  # -10

    body = client.get("/me/progress", headers=auth).json()

    assert body["xp"] == 50, "the net balance"
    assert body["xp_earned_total"] == 60, "the gross, which is what was earned"


def test_xp_earned_total_ignores_a_clamped_loss(client: TestClient, auth):
    """A wrong answer at zero XP costs nothing, so it adds nothing either."""
    _decide(client, auth, correct=False)

    body = client.get("/me/progress", headers=auth).json()

    assert body["xp"] == 0
    assert body["xp_earned_total"] == 0


def test_best_streak_follows_the_current_streak_up(client: TestClient, auth):
    for _ in range(3):
        _decide(client, auth, correct=True)

    body = client.get("/me/progress", headers=auth).json()

    assert body["streak_count"] == 3
    assert body["best_streak"] == 3


def test_best_streak_survives_the_current_streak_resetting(client: TestClient, auth):
    """The point of storing it: a wrong answer must not erase the record."""
    for _ in range(4):
        _decide(client, auth, correct=True)
    _decide(client, auth, correct=False)

    body = client.get("/me/progress", headers=auth).json()

    assert body["streak_count"] == 0
    assert body["best_streak"] == 4


def test_best_streak_only_moves_when_the_record_is_beaten(client: TestClient, auth):
    for _ in range(5):
        _decide(client, auth, correct=True)
    _decide(client, auth, correct=False)
    for _ in range(2):
        _decide(client, auth, correct=True)

    body = client.get("/me/progress", headers=auth).json()

    assert body["streak_count"] == 2
    assert body["best_streak"] == 5, "a shorter run must not lower the record"


def test_best_streak_is_never_below_the_current_streak(client: TestClient, auth):
    for _ in range(6):
        _decide(client, auth, correct=True)

    body = client.get("/me/progress", headers=auth).json()

    assert body["best_streak"] >= body["streak_count"]


def test_the_derived_statistics_are_per_user(client: TestClient, register):
    active, bystander = register(), register()
    for _ in range(3):
        _decide(client, active, correct=True)
    _decide(client, active, correct=False)

    body = client.get("/me/progress", headers=bystander).json()

    assert body["correct_decisions"] == 0
    assert body["accuracy"] == 0.0
    assert body["xp_earned_total"] == 0
    assert body["best_streak"] == 0
