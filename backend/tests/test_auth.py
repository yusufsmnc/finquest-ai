"""Registration and login: the contract, the validation, and what must not leak."""

from __future__ import annotations

from conftest import DEFAULT_PASSWORD
from fastapi.testclient import TestClient

from app.schemas.auth import BCRYPT_MAX_PASSWORD_BYTES


def _register(client: TestClient, email: str, password: str = DEFAULT_PASSWORD):
    return client.post("/auth/register", json={"email": email, "password": password})


def test_register_creates_a_user(client: TestClient):
    response = _register(client, "new@example.com")

    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "new@example.com"
    assert isinstance(body["id"], int)
    assert body["created_at"]


def test_register_never_returns_the_password_or_its_hash(client: TestClient):
    response = _register(client, "quiet@example.com")

    assert DEFAULT_PASSWORD not in response.text
    assert "password" not in response.json()
    assert "password_hash" not in response.json()


def test_register_seeds_a_zeroed_progress_row(client: TestClient):
    """A new account starts at 0 XP / level 1 without a separate call."""
    _register(client, "fresh@example.com")
    token = client.post(
        "/auth/login",
        json={"email": "fresh@example.com", "password": DEFAULT_PASSWORD},
    ).json()["access_token"]

    progress = client.get(
        "/me/progress", headers={"Authorization": f"Bearer {token}"}
    ).json()

    assert progress["xp"] == 0
    assert progress["level"] == 1
    assert progress["streak_count"] == 0


def test_duplicate_email_is_rejected(client: TestClient):
    _register(client, "taken@example.com")

    second = _register(client, "taken@example.com")

    assert second.status_code == 409
    assert second.json()["detail"] == "Email already registered"


def test_short_password_is_rejected(client: TestClient):
    response = _register(client, "weak@example.com", password="short7c")

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "password"]


# ── The bcrypt byte limit (Faz 6a) ─────────────────────────────────────────
#
# bcrypt hashes at most 72 *bytes*. Anything longer used to sail through
# validation and raise inside hash_password, so a password the schema accepted
# produced a 500. It is a 422 now — and the check counts bytes, because a
# character count would still let multi-byte input through.


def test_a_password_at_the_byte_limit_is_accepted(client: TestClient):
    at_limit = "p" * BCRYPT_MAX_PASSWORD_BYTES

    assert _register(client, "atlimit@example.com", at_limit).status_code == 201


def test_a_password_one_byte_over_the_limit_is_refused(client: TestClient):
    response = _register(
        client, "overlimit@example.com", "p" * (BCRYPT_MAX_PASSWORD_BYTES + 1)
    )

    assert response.status_code == 422, "must be a validation error, never a 500"
    assert response.json()["detail"][0]["loc"] == ["body", "password"]


def test_a_multibyte_password_is_measured_in_bytes(client: TestClient):
    """30 characters, 120 bytes — a character-based limit would admit this."""
    thirty_emoji = "🔐" * 30
    assert len(thirty_emoji) < BCRYPT_MAX_PASSWORD_BYTES

    response = _register(client, "emoji@example.com", thirty_emoji)

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "password"]


def test_accented_characters_count_double(client: TestClient):
    """Turkish text is 2 bytes per accented character in UTF-8."""
    password = "şifreçöğü" * 6  # 54 characters, 84 bytes

    assert len(password) < BCRYPT_MAX_PASSWORD_BYTES
    assert len(password.encode("utf-8")) > BCRYPT_MAX_PASSWORD_BYTES
    assert _register(client, "turkce@example.com", password).status_code == 422


def test_a_multibyte_password_within_the_limit_works_end_to_end(client: TestClient):
    """The limit must not lock out non-ASCII passwords that do fit."""
    password = "şifreçöğü1"  # 10 characters, 15 bytes
    assert len(password.encode("utf-8")) <= BCRYPT_MAX_PASSWORD_BYTES

    assert _register(client, "gecerli@example.com", password).status_code == 201
    login = client.post(
        "/auth/login", json={"email": "gecerli@example.com", "password": password}
    )

    assert login.status_code == 200, "a valid multi-byte password must round-trip"


def test_login_refuses_an_over_long_password_too(client: TestClient):
    _register(client, "loginlimit@example.com")

    response = client.post(
        "/auth/login",
        json={
            "email": "loginlimit@example.com",
            "password": "p" * (BCRYPT_MAX_PASSWORD_BYTES + 1),
        },
    )

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "password"]


def test_the_byte_limit_does_not_shadow_a_normal_wrong_password(client: TestClient):
    """A password that fits but is wrong still gets 401, not 422."""
    _register(client, "stillwrong@example.com")

    response = client.post(
        "/auth/login",
        json={
            "email": "stillwrong@example.com",
            "password": "p" * BCRYPT_MAX_PASSWORD_BYTES,
        },
    )

    assert response.status_code == 401


def test_malformed_email_is_rejected(client: TestClient):
    response = _register(client, "not-an-email")

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "email"]


def test_login_returns_a_bearer_token(client: TestClient):
    _register(client, "login@example.com")

    response = client.post(
        "/auth/login",
        json={"email": "login@example.com", "password": DEFAULT_PASSWORD},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"].count(".") == 2, "expected a three-part JWT"


def test_login_with_a_wrong_password_is_401(client: TestClient):
    _register(client, "wrongpass@example.com")

    response = client.post(
        "/auth/login",
        json={"email": "wrongpass@example.com", "password": "not-the-password"},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


def test_login_with_an_unknown_email_is_401(client: TestClient):
    response = client.post(
        "/auth/login",
        json={"email": "ghost@example.com", "password": DEFAULT_PASSWORD},
    )

    assert response.status_code == 401


def test_unknown_email_and_wrong_password_are_indistinguishable(client: TestClient):
    """Same status and same body — the response must not confirm an account."""
    _register(client, "known@example.com")

    wrong_password = client.post(
        "/auth/login", json={"email": "known@example.com", "password": "nope-nope"}
    )
    unknown_user = client.post(
        "/auth/login", json={"email": "nobody@example.com", "password": "nope-nope"}
    )

    assert wrong_password.status_code == unknown_user.status_code == 401
    assert wrong_password.json() == unknown_user.json()


def test_two_users_get_different_tokens(client: TestClient, register):
    first = register()["Authorization"]
    second = register()["Authorization"]

    assert first != second
