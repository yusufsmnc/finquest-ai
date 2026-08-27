"""Password hashing and JWT handling, plus the 401 paths of ``get_current_user``."""

from __future__ import annotations

import jwt
import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)
from app.schemas.auth import BCRYPT_MAX_PASSWORD_BYTES

# ── Hashing ────────────────────────────────────────────────────────────────


def test_hash_verify_roundtrip():
    hashed = hash_password("a-reasonable-password")

    assert verify_password("a-reasonable-password", hashed) is True


def test_hash_is_not_the_plaintext():
    hashed = hash_password("a-reasonable-password")

    assert "a-reasonable-password" not in hashed
    assert hashed.startswith("$2b$")


def test_the_same_password_hashes_differently_each_time():
    """Distinct salts — two identical passwords must not share a digest."""
    assert hash_password("same-input") != hash_password("same-input")


def test_wrong_password_does_not_verify():
    assert verify_password("wrong", hash_password("right-password")) is False


def test_verify_against_a_malformed_hash_returns_false_instead_of_raising():
    """A corrupt row must fail the login, not 500 the endpoint."""
    assert verify_password("anything", "not-a-bcrypt-hash") is False


def test_a_password_at_the_bcrypt_limit_hashes_and_verifies():
    at_limit = "p" * BCRYPT_MAX_PASSWORD_BYTES

    assert verify_password(at_limit, hash_password(at_limit)) is True


def test_the_declared_limit_is_the_one_bcrypt_actually_enforces():
    """Ties the schema's constant to the library's real behaviour.

    bcrypt 4.x raises above 72 bytes rather than truncating the way older
    versions did. If someone raises ``BCRYPT_MAX_PASSWORD_BYTES`` to a
    friendlier-looking number, the validation would start admitting passwords
    that blow up inside ``hash_password`` again — this fails first.
    """
    hash_password("p" * BCRYPT_MAX_PASSWORD_BYTES)  # must not raise

    with pytest.raises(ValueError):
        hash_password("p" * (BCRYPT_MAX_PASSWORD_BYTES + 1))


def test_the_limit_is_counted_in_bytes_not_characters():
    """The reason Pydantic's ``max_length`` cannot express this constraint."""
    thirty_emoji = "🔐" * 30

    assert len(thirty_emoji) == 30
    assert len(thirty_emoji.encode("utf-8")) == 120

    with pytest.raises(ValueError):
        hash_password(thirty_emoji)


# ── Tokens ─────────────────────────────────────────────────────────────────


def test_token_roundtrip_returns_the_subject_as_a_string():
    token = create_access_token(7)

    assert decode_access_token(token) == "7"


def test_token_carries_an_expiry():
    token = create_access_token(1)

    claims = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    assert "exp" in claims


def test_expired_token_is_rejected(monkeypatch):
    monkeypatch.setattr(settings, "access_token_expire_minutes", -1)
    expired = create_access_token(1)

    assert decode_access_token(expired) is None


def test_token_signed_with_another_key_is_rejected():
    foreign = jwt.encode(
        {"sub": "1"}, "a-different-secret-long-enough-for-hs256-hmac", algorithm="HS256"
    )

    assert decode_access_token(foreign) is None


def test_tampered_token_is_rejected():
    token = create_access_token(1)
    header, payload, signature = token.split(".")

    assert decode_access_token(f"{header}.{payload}x.{signature}") is None


def test_garbage_is_rejected():
    assert decode_access_token("not-a-token") is None


def test_unsigned_alg_none_token_is_rejected():
    """The classic JWT downgrade attack must not authenticate anyone."""
    forged = jwt.encode({"sub": "1"}, key="", algorithm="none")

    assert decode_access_token(forged) is None


# ── The dependency ─────────────────────────────────────────────────────────


@pytest.mark.parametrize(
    "headers",
    [
        pytest.param({}, id="no_header"),
        pytest.param({"Authorization": "Bearer "}, id="empty_bearer"),
        pytest.param({"Authorization": "Bearer garbage"}, id="garbage_token"),
        pytest.param({"Authorization": "Token abc"}, id="wrong_scheme"),
    ],
)
def test_protected_endpoint_rejects_bad_authorization(client: TestClient, headers):
    assert client.get("/me/progress", headers=headers).status_code == 401


def test_401_advertises_the_expected_scheme(client: TestClient):
    response = client.get("/me/progress", headers={"Authorization": "Bearer nope"})

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_token_for_a_deleted_user_is_rejected(client: TestClient):
    """A validly signed token whose subject no longer exists must not pass."""
    orphan = create_access_token(999_999)

    response = client.get("/me/progress", headers={"Authorization": f"Bearer {orphan}"})

    assert response.status_code == 401


def test_token_with_a_non_numeric_subject_is_rejected(client: TestClient):
    token = create_access_token("not-an-id")

    response = client.get("/me/progress", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 401


def test_expired_token_is_rejected_by_the_endpoint(client: TestClient, monkeypatch):
    monkeypatch.setattr(settings, "access_token_expire_minutes", -1)
    expired = create_access_token(1)

    response = client.get(
        "/me/progress", headers={"Authorization": f"Bearer {expired}"}
    )

    assert response.status_code == 401
