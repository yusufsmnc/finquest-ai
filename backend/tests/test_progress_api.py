"""``/me/progress`` and ``/me/achievements``.

Read the ``KNOWN ISSUE`` test at the bottom before the rest: ``PATCH`` accepts
whatever the client sends for xp / level / streak. The tests in the middle of
this file describe how that write behaves *today* so a change is visible in the
diff — they are not an endorsement of it. Narrowing the endpoint is Faz 6, and
the gap is recorded as a strict xfail rather than quietly passing.
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


# ── PATCH: how the write behaves today ─────────────────────────────────────


def test_patch_requires_authentication(client: TestClient):
    assert client.patch("/me/progress", json={"xp": 10}).status_code == 401


def test_patch_xp_recomputes_the_level(client: TestClient, auth):
    """XP and level are kept consistent rather than drifting apart."""
    body = client.patch("/me/progress", json={"xp": 250}, headers=auth).json()

    assert body["xp"] == 250
    assert body["level"] == 3


def test_an_explicit_level_overrides_the_recomputed_one(client: TestClient, auth):
    body = client.patch(
        "/me/progress", json={"xp": 250, "level": 9}, headers=auth
    ).json()

    assert body["xp"] == 250
    assert body["level"] == 9


def test_patch_streak_count(client: TestClient, auth):
    assert (
        client.patch("/me/progress", json={"streak_count": 6}, headers=auth).json()[
            "streak_count"
        ]
        == 6
    )


def test_patch_is_partial_and_leaves_other_fields_alone(client: TestClient, auth):
    client.patch("/me/progress", json={"xp": 250, "streak_count": 4}, headers=auth)

    body = client.patch("/me/progress", json={"streak_count": 7}, headers=auth).json()

    assert body["xp"] == 250, "xp must survive a streak-only update"
    assert body["level"] == 3
    assert body["streak_count"] == 7


def test_an_empty_patch_changes_nothing(client: TestClient, auth):
    before = client.patch("/me/progress", json={"xp": 120}, headers=auth).json()

    after = client.patch("/me/progress", json={}, headers=auth).json()

    assert after == before


def test_patch_persists_across_requests(client: TestClient, auth):
    client.patch("/me/progress", json={"xp": 340}, headers=auth)

    assert client.get("/me/progress", headers=auth).json()["xp"] == 340


@pytest.mark.parametrize(
    "payload",
    [
        pytest.param({"xp": -1}, id="negative_xp"),
        pytest.param({"level": 0}, id="level_below_one"),
        pytest.param({"streak_count": -3}, id="negative_streak"),
        pytest.param({"xp": "lots"}, id="non_numeric_xp"),
    ],
)
def test_patch_rejects_out_of_range_values(client: TestClient, auth, payload):
    assert client.patch("/me/progress", json=payload, headers=auth).status_code == 422


def test_patch_does_not_touch_another_user(client: TestClient, register):
    mine, theirs = register(), register()

    client.patch("/me/progress", json={"xp": 500}, headers=mine)

    assert client.get("/me/progress", headers=theirs).json()["xp"] == 0


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


# ── KNOWN ISSUE ────────────────────────────────────────────────────────────


@pytest.mark.xfail(
    strict=True,
    reason=(
        "KNOWN ISSUE - Faz 6: restrict client-writable authoritative fields. "
        "PATCH /me/progress trusts the client's xp/level/streak verbatim."
    ),
)
def test_client_cannot_overwrite_authoritative_progress(client: TestClient, auth):
    """KNOWN ISSUE - a client can award itself any amount of XP.

    CLAUDE.md puts authoritative gamification state in the backend precisely so
    the frontend cannot compute it. This endpoint hands that back: a plain PATCH
    sets XP, level and streak to whatever was posted, with no reconciliation
    against what the user actually earned.

    Asserting the behaviour we want, marked ``strict`` so the day the endpoint
    is narrowed this test starts passing and forces the marker to be removed.
    See the TODO(Faz 6) note in ``app/api/progress.py``.
    """
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

    assert forged.status_code in (403, 422), "the server should refuse this write"
    assert client.get("/me/progress", headers=auth).json()["xp"] == 20
