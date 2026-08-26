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


@pytest.mark.xfail(
    raises=ValueError,
    strict=True,
    reason="KNOWN ISSUE - bcrypt>=4 raises above 72 bytes instead of truncating",
)
def test_password_longer_than_bcrypts_72_byte_limit_can_be_hashed():
    """KNOWN ISSUE - a password the API accepts cannot actually be hashed.

    ``RegisterRequest`` allows up to 128 characters, but bcrypt 4.x dropped the
    silent truncation older versions did and raises instead, so anything over
    72 bytes explodes inside ``hash_password``. Left failing on purpose: the
    fix is a product decision (truncate to 72 bytes, pre-hash with SHA-256, or
    lower the schema limit), not a formatting cleanup. ``strict=True`` so this
    marker cannot outlive the bug.
    """
    long_password = "p" * 100

    hashed = hash_password(long_password)

    assert verify_password(long_password, hashed) is True


@pytest.mark.xfail(
    raises=ValueError,
    strict=True,
    reason="KNOWN ISSUE - registering with a 73..128 char password returns 500",
)
def test_registering_with_a_long_password_does_not_500(client: TestClient):
    """KNOWN ISSUE - the same defect, seen from the outside.

    The schema accepts the input, so this is a plain 500 on a valid request
    rather than a 422. See the unit test above.
    """
    response = client.post(
        "/auth/register", json={"email": "long@example.com", "password": "p" * 100}
    )

    assert response.status_code == 201


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
