"""Mentor tests: real-LLM path, graceful fallback, and cost controls.

The OpenAI client is always mocked — these tests never make a network call and
never need a key, so they are safe to run in CI.
"""
from __future__ import annotations

import logging

import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_user
from app.core.config import settings
from app.main import app
from app.schemas.mentor import MentorContext, MentorRequest, RecentDecision
from app.services import mentor
from app.services.mentor_messages import messages_for, total_message_count

FAKE_KEY = "sk-test-not-a-real-key-000000000000"
AI_TEXT = "You handled that trade-off calmly. Keep practising that pause before deciding."


# ── Test doubles ───────────────────────────────────────────────────────────


class _FakeMessage:
    def __init__(self, content: str | None) -> None:
        self.content = content


class _FakeChoice:
    def __init__(self, content: str | None) -> None:
        self.message = _FakeMessage(content)


class _FakeCompletion:
    def __init__(self, content: str | None) -> None:
        self.choices = [_FakeChoice(content)]


class _FakeCompletions:
    def __init__(self, owner: "_FakeOpenAI") -> None:
        self._owner = owner

    def create(self, **kwargs):
        self._owner.calls.append(kwargs)
        if self._owner.error is not None:
            raise self._owner.error
        return _FakeCompletion(self._owner.content)


class _FakeOpenAI:
    """Stands in for ``openai.OpenAI``; records calls, or raises on demand."""

    instances: list["_FakeOpenAI"] = []

    def __init__(self, content: str | None = AI_TEXT, error: Exception | None = None):
        self.content = content
        self.error = error
        self.calls: list[dict] = []
        self.init_kwargs: dict = {}
        self.chat = type("_Chat", (), {"completions": _FakeCompletions(self)})()


def _install_fake_openai(monkeypatch, content=AI_TEXT, error=None) -> _FakeOpenAI:
    """Patch ``openai.OpenAI`` so ``mentor._call_llm`` picks up the fake."""
    import openai

    fake = _FakeOpenAI(content=content, error=error)

    def _factory(**kwargs):
        fake.init_kwargs = kwargs
        return fake

    monkeypatch.setattr(openai, "OpenAI", _factory)
    return fake


@pytest.fixture(autouse=True)
def _isolate_mentor_state(monkeypatch):
    """Every test starts with an empty cache/throttle and a known config."""
    mentor.reset_state()
    monkeypatch.setattr(settings, "openai_api_key", FAKE_KEY)
    monkeypatch.setattr(settings, "ai_model", "gpt-4o-mini")
    monkeypatch.setattr(settings, "mentor_min_interval_seconds", 0.0)
    monkeypatch.setattr(settings, "mentor_cache_ttl_seconds", 300)
    yield
    mentor.reset_state()


def _request(**kwargs) -> MentorRequest:
    defaults = dict(
        context=MentorContext.DECISION_CORRECT,
        xp=120,
        level=2,
        streak=3,
        recent_decisions=[
            RecentDecision(
                scenario_id="emergency-fund",
                result="DECISION_CORRECT",
                category="savings",
            )
        ],
    )
    defaults.update(kwargs)
    return MentorRequest(**defaults)


# ── (a) the LLM returns a message ──────────────────────────────────────────


def test_llm_message_is_returned_and_marked_as_ai(monkeypatch):
    fake = _install_fake_openai(monkeypatch)

    result = mentor.generate(_request(), user_key="u1")

    assert result.message == AI_TEXT
    assert result.source == "ai"
    assert len(fake.calls) == 1


def test_prompt_carries_the_user_context_and_the_guardrail(monkeypatch):
    fake = _install_fake_openai(monkeypatch)

    mentor.generate(_request(level=4, streak=7, xp=900), user_key="u1")

    call = fake.calls[0]
    system, user = call["messages"]
    assert system["role"] == "system"
    # Guardrail must actually be in the system prompt.
    assert "Never give specific investment or financial advice" in system["content"]
    assert "buy, sell, hold" in system["content"]
    # Context is personalised, not generic.
    assert "level: 4" in user["content"]
    assert "streak: 7" in user["content"]
    assert "total xp: 900" in user["content"]
    assert "correct in savings" in user["content"]


def test_cost_controls_are_applied_to_the_call(monkeypatch):
    fake = _install_fake_openai(monkeypatch)

    mentor.generate(_request(), user_key="u1")

    call = fake.calls[0]
    assert call["model"] == "gpt-4o-mini"
    assert call["max_tokens"] == settings.mentor_max_tokens
    assert settings.mentor_max_tokens <= 200, "mentor replies must stay short/cheap"
    # Timeout is set on the client, and retries are off so it is a hard ceiling.
    assert fake.init_kwargs["timeout"] == settings.mentor_timeout_seconds
    assert fake.init_kwargs["max_retries"] == 0


# ── (b) the LLM raises → fallback ──────────────────────────────────────────


@pytest.mark.parametrize(
    "error",
    [
        TimeoutError("timed out"),
        ConnectionError("network unreachable"),
        RuntimeError("rate limit exceeded"),
        ValueError("invalid api key"),
    ],
    ids=["timeout", "network", "rate_limit", "bad_key"],
)
def test_any_llm_failure_falls_back_to_a_static_message(monkeypatch, error):
    _install_fake_openai(monkeypatch, error=error)
    req = _request()

    result = mentor.generate(req, user_key="u1")

    assert result.source == "fallback"
    assert result.message in messages_for(req.context)


def test_empty_llm_response_falls_back(monkeypatch):
    _install_fake_openai(monkeypatch, content="   ")
    req = _request()

    result = mentor.generate(req, user_key="u1")

    assert result.source == "fallback"
    assert result.message in messages_for(req.context)


def test_missing_key_falls_back_without_calling_the_llm(monkeypatch):
    fake = _install_fake_openai(monkeypatch)
    monkeypatch.setattr(settings, "openai_api_key", "")
    req = _request()

    result = mentor.generate(req, user_key="u1")

    assert result.source == "fallback"
    assert result.message in messages_for(req.context)
    assert fake.calls == [], "no key must mean no paid call at all"


def test_fallback_is_context_aware_not_random(monkeypatch):
    """A wrong decision gets a wrong-decision message, deterministically."""
    _install_fake_openai(monkeypatch, error=RuntimeError("boom"))
    req = _request(context=MentorContext.DECISION_WRONG)

    first = mentor.generate(req, user_key="u1")
    mentor.reset_state()
    second = mentor.generate(req, user_key="u1")

    assert first.message in messages_for(MentorContext.DECISION_WRONG)
    assert first.message not in messages_for(MentorContext.DECISION_CORRECT)
    assert first.message == second.message, "selection must be deterministic"


def test_message_index_rotates_the_static_pool(monkeypatch):
    _install_fake_openai(monkeypatch, error=RuntimeError("boom"))
    ctx = MentorContext.DECISION_CORRECT

    seen = set()
    for i in range(len(messages_for(ctx))):
        mentor.reset_state()
        seen.add(mentor.generate(_request(message_index=i), user_key="u1").message)

    assert len(seen) == len(messages_for(ctx)), "index must walk the whole pool"


def test_static_pool_matches_the_frontend_port_exactly():
    """Locks in the port: every message the frontend held is here, per context.

    Note: CLAUDE.md/ROADMAP.md describe this as "80+" messages, but the pool
    the frontend actually shipped is 72. All 72 were ported verbatim; nothing
    was dropped or invented to hit a round number.
    """
    expected_counts = {
        MentorContext.DECISION_CORRECT: 8,
        MentorContext.DECISION_WRONG: 8,
        MentorContext.LEVEL_UP: 5,
        MentorContext.STREAK_MILESTONE: 5,
        MentorContext.ACHIEVEMENT_UNLOCK: 5,
        MentorContext.CATEGORY_BUDGETING: 4,
        MentorContext.CATEGORY_INVESTING: 4,
        MentorContext.CATEGORY_SAVINGS: 4,
        MentorContext.CATEGORY_RISK: 4,
        MentorContext.NEXT_STEP: 5,
        MentorContext.IDLE: 5,
        MentorContext.ONBOARDING: 3,
        MentorContext.NEW_USER: 3,
        MentorContext.FIRST_WIN: 3,
        MentorContext.STREAK_HIGH: 3,
        MentorContext.HIGH_ACCURACY: 3,
    }
    actual = {ctx: len(messages_for(ctx)) for ctx in expected_counts}
    assert actual == expected_counts
    assert total_message_count() == 72
    # Every context in the enum has its own pool — none silently borrows idle.
    for ctx in MentorContext:
        assert ctx in expected_counts


# ── Secret hygiene ─────────────────────────────────────────────────────────


def test_key_never_appears_in_the_response_or_logs(monkeypatch, caplog):
    # An error whose text embeds the key — the worst case for leaking it.
    _install_fake_openai(
        monkeypatch, error=RuntimeError(f"401 unauthorized for key {FAKE_KEY}")
    )

    with caplog.at_level(logging.DEBUG):
        result = mentor.generate(_request(), user_key="u1")

    assert result.source == "fallback"
    assert FAKE_KEY not in result.message
    assert FAKE_KEY not in caplog.text
    assert "***REDACTED***" in caplog.text


def test_partially_masked_key_in_a_provider_error_is_also_redacted(
    monkeypatch, caplog
):
    """OpenAI's 401 body echoes the key masked, e.g. ``sk-inval*****only``.

    That still exposes the head and tail of the real key, so a plain substring
    replace is not enough. Regression test for a leak found against the live API.
    """
    masked = f"{FAKE_KEY[:8]}{'*' * 26}{FAKE_KEY[-4:]}"
    _install_fake_openai(
        monkeypatch,
        error=RuntimeError(
            f"Error code: 401 - {{'message': 'Incorrect API key provided: {masked}.'}}"
        ),
    )

    with caplog.at_level(logging.DEBUG):
        result = mentor.generate(_request(), user_key="u1")

    assert result.source == "fallback"
    assert masked not in caplog.text
    # Neither the head nor the tail of the real key may survive.
    assert FAKE_KEY[:8] not in caplog.text
    assert FAKE_KEY[-4:] not in caplog.text
    assert "***REDACTED***" in caplog.text


# ── Throttle + cache ───────────────────────────────────────────────────────


def test_identical_context_is_served_from_cache(monkeypatch):
    fake = _install_fake_openai(monkeypatch)
    req = _request()

    first = mentor.generate(req, user_key="u1")
    second = mentor.generate(req, user_key="u1")

    assert first.source == "ai"
    assert second.source == "cache"
    assert second.message == AI_TEXT
    assert len(fake.calls) == 1, "the same context must not be billed twice"


def test_rapid_calls_are_throttled_to_a_static_message(monkeypatch):
    monkeypatch.setattr(settings, "mentor_min_interval_seconds", 60.0)
    fake = _install_fake_openai(monkeypatch)

    first = mentor.generate(_request(), user_key="u1")
    # Different context → misses the cache, but the throttle still holds.
    second = mentor.generate(
        _request(context=MentorContext.LEVEL_UP, level=3), user_key="u1"
    )

    assert first.source == "ai"
    assert second.source == "fallback"
    assert len(fake.calls) == 1, "a burst of events must cost exactly one call"


def test_throttle_is_per_user(monkeypatch):
    monkeypatch.setattr(settings, "mentor_min_interval_seconds", 60.0)
    fake = _install_fake_openai(monkeypatch)

    a = mentor.generate(_request(), user_key="u1")
    b = mentor.generate(_request(), user_key="u2")

    assert a.source == "ai"
    assert b.source == "ai", "one user's throttle must not starve another"
    assert len(fake.calls) == 2


def test_cache_is_per_user(monkeypatch):
    _install_fake_openai(monkeypatch)

    mentor.generate(_request(), user_key="u1")
    other = mentor.generate(_request(), user_key="u2")

    assert other.source == "ai", "users must not read each other's cached answers"


# ── Endpoint ───────────────────────────────────────────────────────────────


class _StubUser:
    id = 42


@pytest.fixture
def client():
    app.dependency_overrides[get_current_user] = lambda: _StubUser()
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def test_endpoint_returns_the_llm_message(monkeypatch, client):
    _install_fake_openai(monkeypatch)

    response = client.post(
        "/mentor",
        json={
            "context": "decision_correct",
            "xp": 120,
            "level": 2,
            "streak": 3,
            "recent_decisions": [
                {
                    "scenario_id": "emergency-fund",
                    "result": "DECISION_CORRECT",
                    "category": "savings",
                }
            ],
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["message"] == AI_TEXT
    assert body["source"] == "ai"
    assert body["context"] == "decision_correct"


def test_endpoint_still_returns_200_when_the_llm_is_down(monkeypatch, client):
    _install_fake_openai(monkeypatch, error=RuntimeError("service unavailable"))

    response = client.post("/mentor", json={"context": "decision_wrong"})

    assert response.status_code == 200, "the app must never break on LLM failure"
    body = response.json()
    assert body["source"] == "fallback"
    assert body["message"] in messages_for(MentorContext.DECISION_WRONG)
    # No provider detail, no key, leaks to the client.
    assert FAKE_KEY not in response.text
    assert "service unavailable" not in response.text


def test_endpoint_accepts_an_empty_body(monkeypatch, client):
    """A bare {} must still produce a usable message, never a 422."""
    _install_fake_openai(monkeypatch, error=RuntimeError("down"))

    response = client.post("/mentor", json={})

    assert response.status_code == 200
    assert response.json()["message"]


def test_endpoint_rejects_an_unknown_context(client):
    response = client.post("/mentor", json={"context": "not_a_real_context"})
    assert response.status_code == 422


def test_endpoint_caps_recent_decisions(client):
    """Prompt size is bounded, so a client cannot inflate cost."""
    response = client.post(
        "/mentor",
        json={
            "recent_decisions": [
                {"scenario_id": f"s{i}", "result": "DECISION_CORRECT"}
                for i in range(20)
            ]
        },
    )
    assert response.status_code == 422
