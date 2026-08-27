from __future__ import annotations

from datetime import datetime
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, EmailStr, Field

#: bcrypt hashes at most 72 **bytes** of input. Versions before 4.0 truncated
#: silently; 4.x raises instead, so anything longer used to reach
#: ``hash_password`` and turn a validation problem into a 500.
BCRYPT_MAX_PASSWORD_BYTES = 72


def _within_bcrypt_limit(value: str) -> str:
    """Reject passwords bcrypt cannot hash.

    The limit is in bytes, not characters, so Pydantic's ``max_length`` cannot
    express it: "şifreşifre..." or a string of emoji reaches 72 bytes long
    before it reaches 72 characters. Counting characters would let those
    through and they would fail deep in the hashing call instead.
    """
    encoded = len(value.encode("utf-8"))
    if encoded > BCRYPT_MAX_PASSWORD_BYTES:
        raise ValueError(
            f"password must be at most {BCRYPT_MAX_PASSWORD_BYTES} bytes when "
            f"UTF-8 encoded (this one is {encoded}); note that accented and "
            "emoji characters take more than one byte each"
        )
    return value


#: Every field that ends up in bcrypt, on the way in and on the way back.
#: Login is validated too: not because a longer password could ever match a
#: stored hash, but so an over-long input gets the same clear 422 in both
#: places rather than a silent 401 that looks like a wrong password.
BcryptPassword = Annotated[str, AfterValidator(_within_bcrypt_limit)]


class RegisterRequest(BaseModel):
    email: EmailStr
    # min_length counts characters, which is the right unit for a usability
    # floor; the ceiling is the byte limit above, so no max_length here.
    password: Annotated[BcryptPassword, Field(min_length=8)]


class LoginRequest(BaseModel):
    email: EmailStr
    password: BcryptPassword


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    created_at: datetime
