"""Achievement unlocking: thresholds, idempotency, permanence, isolation."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.achievement import Achievement
from app.models.user import User
from app.services.achievements import CRITERIA, sync_achievements


def _user(db: Session, email: str) -> User:
    user = User(email=email, password_hash="not-used-here")
    db.add(user)
    db.flush()
    return user


def _codes(db: Session, user_id: int) -> set[str]:
    return set(
        db.scalars(select(Achievement.code).where(Achievement.user_id == user_id))
    )


def _sync(db: Session, user_id: int, **metrics) -> list[str]:
    defaults = {"xp": 0, "level": 1, "streak": 0, "decisions": 0}
    defaults.update(metrics)
    return sync_achievements(db, user_id=user_id, **defaults)


# ── Thresholds ─────────────────────────────────────────────────────────────


def test_nothing_is_unlocked_by_a_blank_slate(db_session: Session):
    user = _user(db_session, "blank@example.com")

    assert _sync(db_session, user.id) == []


def test_a_metric_at_its_threshold_unlocks(db_session: Session):
    user = _user(db_session, "threshold@example.com")

    unlocked = _sync(db_session, user.id, xp=100)

    assert "xp_100" in unlocked


def test_a_metric_one_short_of_its_threshold_does_not_unlock(db_session: Session):
    user = _user(db_session, "short@example.com")

    unlocked = _sync(db_session, user.id, xp=99)

    assert "xp_100" not in unlocked


def test_every_criterion_unlocks_at_exactly_its_threshold(db_session: Session):
    """Walks all 14 codes so a typo'd threshold cannot slip through."""
    for index, (code, (metric, threshold)) in enumerate(CRITERIA.items()):
        user = _user(db_session, f"criteria{index}@example.com")

        at = _sync(db_session, user.id, **{metric: threshold})
        db_session.flush()

        assert code in at, f"{code} should unlock at {metric}={threshold}"


def test_passing_a_threshold_also_unlocks_the_lower_tiers(db_session: Session):
    user = _user(db_session, "tiers@example.com")

    unlocked = _sync(db_session, user.id, streak=5)

    assert {"streak_first", "streak_3", "streak_5"} <= set(unlocked)
    assert "streak_10" not in unlocked


def test_metrics_do_not_bleed_into_each_other(db_session: Session):
    """High XP must not unlock a streak badge, and vice versa."""
    user = _user(db_session, "bleed@example.com")

    unlocked = set(_sync(db_session, user.id, xp=2000))

    assert "xp_2000" in unlocked
    assert not {c for c in unlocked if CRITERIA[c][0] != "xp"}


def test_new_codes_are_returned_sorted(db_session: Session):
    user = _user(db_session, "sorted@example.com")

    unlocked = _sync(db_session, user.id, xp=1000, level=10, streak=10, decisions=100)

    assert unlocked == sorted(unlocked)


# ── Idempotency and permanence ─────────────────────────────────────────────


def test_a_second_sync_at_the_same_state_unlocks_nothing_new(db_session: Session):
    user = _user(db_session, "idempotent@example.com")

    first = _sync(db_session, user.id, xp=100)
    db_session.flush()
    second = _sync(db_session, user.id, xp=100)

    assert first == ["xp_100"]
    assert second == []


def test_repeated_syncs_never_duplicate_a_row(db_session: Session):
    user = _user(db_session, "norepeat@example.com")

    for _ in range(5):
        _sync(db_session, user.id, xp=500, level=5, streak=3, decisions=25)
        db_session.flush()

    rows = db_session.scalars(
        select(Achievement).where(Achievement.user_id == user.id)
    ).all()
    assert len(rows) == len({row.code for row in rows})


def test_an_unlock_survives_the_metric_falling_back_below_its_threshold(
    db_session: Session,
):
    """Streaks reset to zero on a wrong answer; the badge is still earned."""
    user = _user(db_session, "permanent@example.com")
    _sync(db_session, user.id, streak=5)
    db_session.flush()

    after_reset = _sync(db_session, user.id, streak=0)
    db_session.flush()

    assert after_reset == []
    assert {"streak_first", "streak_3", "streak_5"} <= _codes(db_session, user.id)


def test_climbing_gradually_unlocks_each_tier_exactly_once(db_session: Session):
    user = _user(db_session, "climb@example.com")

    seen: list[str] = []
    for xp in (100, 500, 1000, 2000):
        seen += _sync(db_session, user.id, xp=xp)
        db_session.flush()

    assert seen == ["xp_100", "xp_500", "xp_1000", "xp_2000"]
    assert len(seen) == len(set(seen))


# ── Isolation ──────────────────────────────────────────────────────────────


def test_one_users_unlocks_do_not_satisfy_another(db_session: Session):
    earner = _user(db_session, "earner@example.com")
    newcomer = _user(db_session, "newcomer@example.com")
    _sync(db_session, earner.id, xp=100)
    db_session.flush()

    unlocked = _sync(db_session, newcomer.id, xp=100)

    assert unlocked == ["xp_100"], "the newcomer earns it for themselves"
    assert _codes(db_session, earner.id) == {"xp_100"}


def test_sync_does_not_commit(db_session: Session):
    """The caller owns the transaction boundary — this only stages inserts."""
    user = _user(db_session, "uncommitted@example.com")

    _sync(db_session, user.id, xp=100)

    assert db_session.new, "rows should still be pending, not flushed and committed"
