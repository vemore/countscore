"""Tests for group CRUD + device lifecycle."""
from __future__ import annotations


async def test_create_group_and_join(client):
    # Create group → get share_token + device_token
    r = await client.post(
        "/groups", json={"name": "Famille", "device_label": "Tel Alice"}
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["group"]["name"] == "Famille"
    assert body["group"]["comment_style"] == "narrative"
    share_token = body["group"]["share_token"]
    alice_token = body["device"]["token"]
    assert alice_token  # raw token returned

    # Bob joins
    r = await client.post(
        "/groups/join", json={"share_token": share_token, "device_label": "Tel Bob"}
    )
    assert r.status_code == 201
    bob = r.json()
    assert bob["group"]["id"] == body["group"]["id"]
    bob_token = bob["device"]["token"]
    assert bob_token != alice_token

    # Alice can hit /groups/me
    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {alice_token}"})
    assert r.status_code == 200
    assert r.json()["name"] == "Famille"

    # Without token → 401
    r = await client.get("/groups/me")
    assert r.status_code == 401

    # Bad token → 401
    r = await client.get("/groups/me", headers={"Authorization": "Bearer not-a-token"})
    assert r.status_code == 401


async def test_join_with_bad_token(client):
    r = await client.post(
        "/groups/join",
        json={"share_token": "00000000-0000-0000-0000-000000000000", "device_label": "Tel"},
    )
    assert r.status_code == 404


async def test_revoke_device(client):
    r = await client.post(
        "/groups", json={"name": "g", "device_label": "creator"}
    )
    alice_token = r.json()["device"]["token"]
    share = r.json()["group"]["share_token"]

    r = await client.post(
        "/groups/join", json={"share_token": share, "device_label": "joiner"}
    )
    bob_device_id = r.json()["device"]["id"]
    bob_token = r.json()["device"]["token"]

    # Alice revokes Bob
    r = await client.post(
        f"/groups/me/devices/{bob_device_id}/revoke",
        headers={"Authorization": f"Bearer {alice_token}"},
    )
    assert r.status_code == 204

    # Bob's token no longer works
    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {bob_token}"})
    assert r.status_code == 401


async def test_rotate_share_token(client):
    r = await client.post("/groups", json={"name": "g", "device_label": "d"})
    alice_token = r.json()["device"]["token"]
    old_share = r.json()["group"]["share_token"]

    r = await client.post(
        "/groups/me/rotate-share-token",
        headers={"Authorization": f"Bearer {alice_token}"},
    )
    assert r.status_code == 200
    new_share = r.json()["share_token"]
    assert new_share != old_share

    # Old share is no longer valid
    r = await client.post(
        "/groups/join", json={"share_token": old_share, "device_label": "late"}
    )
    assert r.status_code == 404


async def test_update_settings(client):
    r = await client.post("/groups", json={"name": "g", "device_label": "d"})
    token = r.json()["device"]["token"]

    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "humorous", "comment_language": "en"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["comment_style"] == "humorous"
    assert body["comment_language"] == "en"

    # Bad style rejected
    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "rude"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 422
