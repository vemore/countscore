"""Device tokens name their device: one row fetched, one argon2 verify, a cap on failures.

Backend security review 2026-09-13, HIGH: the previous opaque token ran a verify against
every device row for any bearer string, which made junk tokens a CPU denial of service.
"""

from __future__ import annotations

import uuid

import pytest

from app import auth


async def _create(client, name="g"):
    r = await client.post("/groups", json={"name": name, "device_label": "d"})
    assert r.status_code == 201, r.text
    return r.json()


@pytest.fixture
def verify_calls(monkeypatch):
    calls: list[str] = []
    real = auth.verify_token

    def counting(raw: str, hashed: str) -> bool:
        calls.append(raw)
        return real(raw, hashed)

    monkeypatch.setattr(auth, "verify_token", counting)
    return calls


async def test_the_token_names_its_device(client):
    body = await _create(client)
    device_hex, _, secret = body["device"]["token"].partition(".")

    assert uuid.UUID(hex=device_hex) == uuid.UUID(body["device"]["id"])
    assert len(secret) == 32


async def test_a_request_runs_one_verify_however_many_devices_exist(client, verify_calls):
    bodies = [await _create(client, f"g{i}") for i in range(3)]  # rate limit is 3/min
    token = bodies[-1]["device"]["token"]

    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {token}"})

    assert r.status_code == 200
    assert len(verify_calls) == 1


@pytest.mark.parametrize(
    "bearer",
    ["not-a-token", "0" * 32, f"{'z' * 32}.secret", f"{uuid.uuid4().hex}.", "."],
)
async def test_malformed_tokens_are_refused_without_hashing(client, verify_calls, bearer):
    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {bearer}"})

    assert r.status_code == 401
    assert verify_calls == []


async def test_an_unknown_device_is_refused_without_hashing(client, verify_calls):
    bearer = f"{uuid.uuid4().hex}.{'0' * 32}"
    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {bearer}"})

    assert r.status_code == 401
    assert verify_calls == []


async def test_a_wrong_secret_for_a_real_device_is_refused(client):
    body = await _create(client)
    device_hex = body["device"]["token"].partition(".")[0]

    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {device_hex}.{'0' * 32}"})

    assert r.status_code == 401


async def test_repeated_failures_from_one_address_get_a_429_before_any_hashing(
    client, monkeypatch, verify_calls
):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "auth_fail_rl_per_minute", 3)
    body = await _create(client)
    device_hex = body["device"]["token"].partition(".")[0]
    wrong = {"Authorization": f"Bearer {device_hex}.{'0' * 32}"}

    codes = [(await client.get("/groups/me", headers=wrong)).status_code for _ in range(5)]

    assert codes == [401, 401, 401, 429, 429]
    assert len(verify_calls) == 3


async def test_a_valid_token_is_not_counted_as_a_failure(client, monkeypatch):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "auth_fail_rl_per_minute", 1)
    body = await _create(client)
    headers = {"Authorization": f"Bearer {body['device']['token']}"}

    codes = [(await client.get("/groups/me", headers=headers)).status_code for _ in range(3)]

    assert codes == [200, 200, 200]
