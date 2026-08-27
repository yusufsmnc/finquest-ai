"""``/me/progress`` and ``/me/achievements`` — both read-only.

``PATCH /me/progress`` used to accept whatever a client sent for xp, level and
streak_count. It was removed in Faz 6b (nothing called it; the Flutter client
only reads this path), so the tests below assert the endpoint is *closed* rather
than describing how its write behaved. Progress moves through
``POST /scenarios/{id}/decision`` and nowhere else.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

# ── GET ────────────────────────────────────────────────────────────────────


def test_progress_starts_zeroed(client: TestClient, auth):
    body = client.get("/me/progress", headers=auth).json()

    assert body == {
        "xp": 0,
        "level": 1,
        "streak_count": 0,
        "last_active": body["last_active"],
        "decisions_made": 0,
        "decisions_today": 0,
    }


def test_progress_requires_authentication(client: TestClient):
    assert client.get("/me/progress").status_code == 401


def test_users_see_only_their_own_progress(client: TestClient, register):
    busy, idle = register(), register()
    client.post(
        "/scenarios/budget/decision",
        json={"choice": "save", "correct": True},
        headers=busy,
    )

    assert client.get("/me/progress", headers=busy).json()["xp"] == 20
    assert client.get("/me/progress", headers=idle).json()["xp"] == 0


# ── PATCH is closed (Faz 6b) ───────────────────────────────────────────────


def test_patch_is_not_allowed(client: TestClient, auth):
    """The path answers GET only, so a write is rejected at the routing layer."""
    response = client.patch("/me/progress", json={"xp": 9999}, headers=auth)

    assert response.status_code == 405


def test_put_is_not_allowed(client: TestClient, auth):
    assert (
        client.put("/me/progress", json={"xp": 9999}, headers=auth).status_code == 405
    )


@pytest.mark.parametrize(
    "payload",
    [
        pytest.param({"xp": 9999}, id="xp"),
        pytest.param({"level": 99}, id="level"),
        pytest.param({"streak_count": 365}, id="streak_count"),
        pytest.param({"last_active": "2030-01-01T00:00:00Z"}, id="last_active"),
        pytest.param({"xp": 9999, "level": 99, "streak_count": 365}, id="all_at_once"),
    ],
)
def test_no_authoritative_field_can_be_written_by_a_client(
    client: TestClient, auth, payload
):
    before = client.get("/me/progress", headers=auth).json()

    forged = client.patch("/me/progress", json=payload, headers=auth)

    assert forged.status_code == 405
    assert client.get("/me/progress", headers=auth).json() == before


def test_a_forged_write_cannot_move_earned_progress(client: TestClient, auth):
    """The scenario in the old KNOWN ISSUE test, now asserting the fix."""
    client.post(
        "/scenarios/budget/decision",
        json={"choice": "save", "correct": True},
        headers=auth,
    )

    forged = client.patch(
        "/me/progress",
        json={"xp": 999_999, "level": 99, "streak_count": 365},
        headers=auth,
    )

    assert forged.status_code == 405
    after = client.get("/me/progress", headers=auth).json()
    assert after["xp"] == 20, "the decision's 20 XP, not the 999999 that was posted"
    assert after["level"] == 1
    assert after["streak_count"] == 1


def test_progress_moves_only_through_the_decision_flow(client: TestClient, auth):
    """Two correct decisions are worth 40 XP; no request can shortcut that."""
    for _ in range(2):
        client.post(
            "/scenarios/budget/decision",
            json={"choice": "save", "correct": True},
            headers=auth,
        )
    client.patch("/me/progress", json={"xp": 5000}, headers=auth)

    assert client.get("/me/progress", headers=auth).json()["xp"] == 40


def test_the_api_no_longer_advertises_a_write(client: TestClient):
    """Guards against the route being reintroduced by accident."""
    paths = client.get("/openapi.json").json()["paths"]

    assert set(paths["/me/progress"]) == {"get"}


def test_a_rejected_write_is_not_an_authentication_oracle(client: TestClient):
    """405 comes from routing, before auth — the same answer with or without a
    token. That is correct here: it leaks nothing, because the method does not
    exist for any caller."""
    without_token = client.patch("/me/progress", json={"xp": 1})

    assert without_token.status_code == 405


# ── Achievements ───────────────────────────────────────────────────────────


def test_achievements_start_empty(client: TestClient, auth):
    assert client.get("/me/achievements", headers=auth).json() == []


def test_achievements_requires_authentication(client: TestClient):
    assert client.get("/me/achievements").status_code == 401


def test_earned_achievements_are_listed_with_their_unlock_time(
    client: TestClient, auth
):
    client.post(
        "/scenarios/budget/decision",
        json={"choice": "save", "correct": True},
        headers=auth,
    )

    body = client.get("/me/achievements", headers=auth).json()

    assert [row["code"] for row in body] == ["streak_first"]
    assert body[0]["unlocked_at"]


def test_achievements_are_per_user(client: TestClient, register):
    earner, newcomer = register(), register()
    client.post(
        "/scenarios/budget/decision",
        json={"choice": "save", "correct": True},
        headers=earner,
    )

    assert client.get("/me/achievements", headers=newcomer).json() == []
