"""Tests for group CRUD + device lifecycle."""

from __future__ import annotations

from app.services import ip_rate_limiter


async def test_create_group_and_join(client):
    # Create group → get share_token + device_token
    r = await client.post("/groups", json={"name": "Famille", "device_label": "Tel Alice"})
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
    r = await client.post("/groups", json={"name": "g", "device_label": "creator"})
    alice_token = r.json()["device"]["token"]
    share = r.json()["group"]["share_token"]

    r = await client.post("/groups/join", json={"share_token": share, "device_label": "joiner"})
    bob_device_id = r.json()["device"]["id"]
    bob_token = r.json()["device"]["token"]

    # Alice revokes Bob
    r = await client.post(
        f"/groups/me/devices/{bob_device_id}/revoke",
        headers={"Authorization": f"Bearer {alice_token}"},
    )
    assert r.status_code == 200

    # Bob's token no longer works
    r = await client.get("/groups/me", headers={"Authorization": f"Bearer {bob_token}"})
    assert r.status_code == 401


async def test_list_devices_shows_the_active_members_of_the_callers_group(client):
    r = await client.post("/groups", json={"name": "g", "device_label": "alice"})
    alice = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    alice_id = r.json()["device"]["id"]
    share = r.json()["group"]["share_token"]
    r = await client.post("/groups/join", json={"share_token": share, "device_label": "bob"})
    bob_id = r.json()["device"]["id"]
    r = await client.post("/groups/join", json={"share_token": share, "device_label": "carol"})
    carol_id = r.json()["device"]["id"]
    # A device of another group must not show up.
    await client.post("/groups", json={"name": "other", "device_label": "stranger"})

    r = await client.get("/groups/me/devices", headers=alice)
    assert r.status_code == 200, r.text
    devices = r.json()["devices"]
    assert [d["label"] for d in devices] == ["alice", "bob", "carol"]
    assert [d["id"] for d in devices] == [alice_id, bob_id, carol_id]
    assert set(devices[0]) == {"id", "label", "joined_at", "last_seen_at", "is_owner", "dormant"}
    assert [d["is_owner"] for d in devices] == [True, False, False]
    assert [d["dormant"] for d in devices] == [False, False, False]

    # A revoked device drops out of the list.
    await client.post(f"/groups/me/devices/{bob_id}/revoke", headers=alice)
    r = await client.get("/groups/me/devices", headers=alice)
    assert [d["id"] for d in r.json()["devices"]] == [alice_id, carol_id]


async def test_list_devices_needs_a_device_token(client):
    assert (await client.get("/groups/me/devices")).status_code == 401


async def test_revoking_another_device_rotates_the_share_token(client):
    """Bob learnt the share token when he joined: a revoke alone let him straight back in."""
    r = await client.post("/groups", json={"name": "g", "device_label": "alice"})
    alice = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    old_share = r.json()["group"]["share_token"]
    r = await client.post("/groups/join", json={"share_token": old_share, "device_label": "bob"})
    bob_device_id = r.json()["device"]["id"]

    r = await client.post(f"/groups/me/devices/{bob_device_id}/revoke", headers=alice)
    assert r.status_code == 200
    new_share = r.json()["share_token"]
    assert new_share != old_share

    rejoin = await client.post(
        "/groups/join", json={"share_token": old_share, "device_label": "bob again"}
    )
    assert rejoin.status_code == 404

    # Idempotent: a second revoke returns the current token and mints no other.
    again = await client.post(f"/groups/me/devices/{bob_device_id}/revoke", headers=alice)
    assert again.status_code == 200
    assert again.json()["share_token"] == new_share


async def test_revoking_itself_is_leaving_and_keeps_the_share_token(client):
    """GroupProvider.leave revokes its own device; the members who stay keep their link."""
    r = await client.post("/groups", json={"name": "g", "device_label": "alice"})
    share = r.json()["group"]["share_token"]
    r = await client.post("/groups/join", json={"share_token": share, "device_label": "bob"})
    bob = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    bob_device_id = r.json()["device"]["id"]

    r = await client.post(f"/groups/me/devices/{bob_device_id}/revoke", headers=bob)
    assert r.status_code == 204
    assert r.content == b""

    assert (await client.get("/groups/me", headers=bob)).status_code == 401
    carol = await client.post("/groups/join", json={"share_token": share, "device_label": "carol"})
    assert carol.status_code == 201


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
    r = await client.post("/groups/join", json={"share_token": old_share, "device_label": "late"})
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


async def test_budget_is_capped_by_the_operator(client, monkeypatch):
    """The budget is spent on the operator's key: a member must not raise it at will."""
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "default_budget_cents", 100)
    r = await client.post("/groups", json={"name": "g", "device_label": "d"})
    headers = {"Authorization": f"Bearer {r.json()['device']['token']}"}

    # Unset MAX_BUDGET_CENTS: the default budget is the ceiling.
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 101}, headers=headers
    )
    assert r.status_code == 422
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 100}, headers=headers
    )
    assert r.status_code == 200
    assert r.json()["monthly_budget_cents"] == 100
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 20}, headers=headers
    )
    assert r.status_code == 200

    monkeypatch.setattr(get_settings(), "max_budget_cents", 500)
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 500}, headers=headers
    )
    assert r.status_code == 200
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 501}, headers=headers
    )
    assert r.status_code == 422
    # A refused request changes nothing else either.
    assert (await client.get("/groups/me", headers=headers)).json()["monthly_budget_cents"] == 500


async def test_get_me_does_not_leak_the_share_token(client):
    """Any member device can re-share a group whose token is echoed on a plain read."""
    created = await client.post("/groups", json={"name": "Famille", "device_label": "d"})
    token = created.json()["device"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    me = await client.get("/groups/me", headers=headers)
    assert me.status_code == 200
    assert "share_token" not in me.json()

    settings = await client.patch(
        "/groups/me/settings", json={"comment_style": "humorous"}, headers=headers
    )
    assert settings.status_code == 200
    assert "share_token" not in settings.json()


async def test_share_token_is_returned_where_a_link_is_asked_for(client):
    """Create, join and rotate are the three moments the caller wants a share link."""
    created = await client.post("/groups", json={"name": "Famille", "device_label": "d"})
    share_token = created.json()["group"]["share_token"]
    token = created.json()["device"]["token"]

    joined = await client.post(
        "/groups/join", json={"share_token": share_token, "device_label": "d2"}
    )
    assert joined.json()["group"]["share_token"] == share_token

    rotated = await client.post(
        "/groups/me/rotate-share-token", headers={"Authorization": f"Bearer {token}"}
    )
    assert rotated.status_code == 200
    assert rotated.json()["share_token"] != share_token


async def test_group_creation_is_rate_limited(client):
    from app.config import get_settings

    limit = get_settings().group_rl_per_minute
    for _ in range(limit):
        r = await client.post("/groups", json={"name": "g", "device_label": "d"})
        assert r.status_code == 201, r.text

    blocked = await client.post("/groups", json={"name": "g", "device_label": "d"})
    assert blocked.status_code == 429
    assert int(blocked.headers["Retry-After"]) >= 1


async def test_join_is_rate_limited_so_share_tokens_cannot_be_ground(client):
    """A 201 and a 404 tell a valid share_token from an invalid one — cap the guessing."""
    import uuid

    from app.config import get_settings
    from app.services import ip_rate_limiter

    limit = get_settings().group_rl_per_minute
    for _ in range(limit):
        r = await client.post(
            "/groups/join", json={"share_token": str(uuid.uuid4()), "device_label": "d"}
        )
        assert r.status_code == 404

    blocked = await client.post(
        "/groups/join", json={"share_token": str(uuid.uuid4()), "device_label": "d"}
    )
    assert blocked.status_code == 429

    # The LLM quota lives in its own bucket and must be untouched by the above.
    assert ip_rate_limiter.check_ip_rate_limit("testclient").allowed


def test_an_empty_budget_ceiling_is_unset(monkeypatch):
    """docker-compose.prod.yml passes MAX_BUDGET_CENTS as "" when the operator sets none."""
    from app.config import Settings

    monkeypatch.setenv("MAX_BUDGET_CENTS", "")
    monkeypatch.setenv("DEFAULT_BUDGET_CENTS", "250")
    assert Settings().effective_max_budget_cents == 250


# ── Ownership ────────────────────────────────────────────────────────────────


async def _group_of_three(client):
    """alice creates, bob and carol join. Returns (headers, device ids, share token)."""
    r = await client.post("/groups", json={"name": "g", "device_label": "alice"})
    share = r.json()["group"]["share_token"]
    heads = {"alice": {"Authorization": f"Bearer {r.json()['device']['token']}"}}
    ids = {"alice": r.json()["device"]["id"]}
    for name in ("bob", "carol"):
        r = await client.post("/groups/join", json={"share_token": share, "device_label": name})
        heads[name] = {"Authorization": f"Bearer {r.json()['device']['token']}"}
        ids[name] = r.json()["device"]["id"]
    return heads, ids, share


async def test_the_creator_owns_the_group(client):
    heads, ids, _ = await _group_of_three(client)
    for name in ("alice", "bob"):
        r = await client.get("/groups/me", headers=heads[name])
        assert r.json()["owner_device_id"] == ids["alice"]


async def test_a_member_that_is_not_the_owner_cannot_revoke_or_rotate(client):
    heads, ids, share = await _group_of_three(client)

    r = await client.post(f"/groups/me/devices/{ids['carol']}/revoke", headers=heads["bob"])
    assert r.status_code == 403
    r = await client.post(f"/groups/me/devices/{ids['alice']}/revoke", headers=heads["bob"])
    assert r.status_code == 403
    r = await client.post("/groups/me/rotate-share-token", headers=heads["bob"])
    assert r.status_code == 403
    r = await client.put("/groups/me/owner", json={"device_id": ids["bob"]}, headers=heads["bob"])
    assert r.status_code == 403

    # Nothing changed: carol is still in, the invite still works, alice still owns.
    ip_rate_limiter.reset()  # four group calls from one address pass the per-minute limit
    assert (await client.get("/groups/me", headers=heads["carol"])).status_code == 200
    r = await client.post("/groups/join", json={"share_token": share, "device_label": "dan"})
    assert r.status_code == 201
    r = await client.get("/groups/me", headers=heads["bob"])
    assert r.json()["owner_device_id"] == ids["alice"]


async def test_only_the_owner_sets_the_budget(client):
    """The budget is spent on the operator's key: a member that is not the owner gets a 403."""
    heads, _, _ = await _group_of_three(client)
    before = (await client.get("/groups/me", headers=heads["alice"])).json()

    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 20}, headers=heads["bob"]
    )
    assert r.status_code == 403
    # Even over the cap, the answer is the 403: the cap is none of a member's business.
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 9_999}, headers=heads["bob"]
    )
    assert r.status_code == 403
    # A refused request changes nothing, not even the fields that are open to a member.
    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "humorous", "monthly_budget_cents": 20},
        headers=heads["bob"],
    )
    assert r.status_code == 403
    after = (await client.get("/groups/me", headers=heads["alice"])).json()
    assert after["monthly_budget_cents"] == before["monthly_budget_cents"]
    assert after["comment_style"] == before["comment_style"]

    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 20}, headers=heads["alice"]
    )
    assert r.status_code == 200
    assert r.json()["monthly_budget_cents"] == 20


async def test_a_member_that_is_not_the_owner_sets_style_and_language(client):
    heads, _, _ = await _group_of_three(client)
    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "humorous", "comment_language": "en"},
        headers=heads["bob"],
    )
    assert r.status_code == 200
    assert r.json()["comment_style"] == "humorous"
    assert r.json()["comment_language"] == "en"
    # An explicit null budget is no budget change: still open to a member.
    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "analytical", "monthly_budget_cents": None},
        headers=heads["carol"],
    )
    assert r.status_code == 200


async def test_the_budget_follows_the_owner_role(client):
    heads, ids, _ = await _group_of_three(client)
    r = await client.put("/groups/me/owner", json={"device_id": ids["bob"]}, headers=heads["alice"])
    assert r.status_code == 200
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 20}, headers=heads["alice"]
    )
    assert r.status_code == 403
    r = await client.patch(
        "/groups/me/settings", json={"monthly_budget_cents": 20}, headers=heads["bob"]
    )
    assert r.status_code == 200


async def test_a_member_that_is_not_the_owner_can_still_leave(client):
    heads, ids, _ = await _group_of_three(client)
    r = await client.post(f"/groups/me/devices/{ids['bob']}/revoke", headers=heads["bob"])
    assert r.status_code == 204
    r = await client.get("/groups/me", headers=heads["alice"])
    assert r.json()["owner_device_id"] == ids["alice"]


async def test_the_owner_hands_the_group_over(client):
    heads, ids, _ = await _group_of_three(client)

    r = await client.put("/groups/me/owner", json={"device_id": ids["bob"]}, headers=heads["alice"])
    assert r.status_code == 200, r.text
    assert r.json()["owner_device_id"] == ids["bob"]
    assert "share_token" not in r.json()

    # The former owner has lost the role, the new one has it.
    r = await client.post("/groups/me/rotate-share-token", headers=heads["alice"])
    assert r.status_code == 403
    r = await client.post(f"/groups/me/devices/{ids['alice']}/revoke", headers=heads["bob"])
    assert r.status_code == 200
    r = await client.get("/groups/me/devices", headers=heads["bob"])
    assert [(d["id"], d["is_owner"]) for d in r.json()["devices"]] == [
        (ids["bob"], True),
        (ids["carol"], False),
    ]


async def test_ownership_goes_only_to_a_live_device_of_the_group(client):
    heads, ids, _ = await _group_of_three(client)
    ip_rate_limiter.reset()  # four group calls from one address pass the per-minute limit
    r = await client.post("/groups", json={"name": "other", "device_label": "stranger"})
    stranger = r.json()["device"]["id"]
    await client.post(f"/groups/me/devices/{ids['carol']}/revoke", headers=heads["alice"])

    for target in (stranger, ids["carol"], "00000000-0000-0000-0000-000000000000"):
        r = await client.put("/groups/me/owner", json={"device_id": target}, headers=heads["alice"])
        assert r.status_code == 404, target

    # Naming itself is a no-op.
    r = await client.put(
        "/groups/me/owner", json={"device_id": ids["alice"]}, headers=heads["alice"]
    )
    assert r.status_code == 200
    assert r.json()["owner_device_id"] == ids["alice"]


async def test_an_owner_that_leaves_hands_the_group_to_the_earliest_member(client):
    heads, ids, _ = await _group_of_three(client)
    r = await client.post(f"/groups/me/devices/{ids['alice']}/revoke", headers=heads["alice"])
    assert r.status_code == 204

    r = await client.get("/groups/me", headers=heads["carol"])
    assert r.json()["owner_device_id"] == ids["bob"]
    r = await client.post("/groups/me/rotate-share-token", headers=heads["bob"])
    assert r.status_code == 200


async def test_the_last_device_leaving_leaves_no_owner(client, session):
    import uuid

    from app.models import Group

    r = await client.post("/groups", json={"name": "solo", "device_label": "alone"})
    group_id = uuid.UUID(r.json()["group"]["id"])
    me = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    r = await client.post(f"/groups/me/devices/{r.json()['device']['id']}/revoke", headers=me)
    assert r.status_code == 204
    group = await session.get(Group, group_id)
    assert group is not None and group.owner_device_id is None


# ── A dormant owner ──────────────────────────────────────────────────────────


async def _go_quiet(session, device_id: str, *, days: int = 40) -> None:
    """Backdate a device's last_seen_at: what an uninstalled app looks like on the server."""
    import uuid
    from datetime import UTC, datetime, timedelta

    from app.models import Device

    device = await session.get(Device, uuid.UUID(device_id))
    assert device is not None
    device.last_seen_at = datetime.now(UTC) - timedelta(days=days)
    await session.commit()


async def test_the_device_list_says_which_devices_have_gone_quiet(client, session):
    heads, ids, _ = await _group_of_three(client)
    await _go_quiet(session, ids["alice"])

    r = await client.get("/groups/me/devices", headers=heads["bob"])
    assert r.status_code == 200, r.text
    assert [(d["label"], d["dormant"]) for d in r.json()["devices"]] == [
        ("alice", True),
        ("bob", False),
        ("carol", False),
    ]


async def test_a_member_claims_the_group_from_a_dormant_owner(client, session):
    """The owner uninstalled: no request is ever sent, so only a claim gets the group back."""
    heads, ids, _ = await _group_of_three(client)
    await _go_quiet(session, ids["alice"])

    r = await client.post("/groups/me/owner/claim", headers=heads["bob"])
    assert r.status_code == 200, r.text
    assert r.json()["owner_device_id"] == ids["bob"]
    assert "share_token" not in r.json()

    # The point of the claim: the share token the dormant owner left behind can be rotated.
    r = await client.post("/groups/me/rotate-share-token", headers=heads["bob"])
    assert r.status_code == 200
    # And the role really moved: carol still has none.
    r = await client.post("/groups/me/rotate-share-token", headers=heads["carol"])
    assert r.status_code == 403


async def test_a_member_cannot_claim_the_group_from_an_owner_that_is_about(client):
    heads, ids, _ = await _group_of_three(client)

    r = await client.post("/groups/me/owner/claim", headers=heads["bob"])
    assert r.status_code == 409, r.text
    r = await client.get("/groups/me", headers=heads["bob"])
    assert r.json()["owner_device_id"] == ids["alice"]

    # Claiming what one already owns is a no-op, not a 409: the owner is not refused itself.
    r = await client.post("/groups/me/owner/claim", headers=heads["alice"])
    assert r.status_code == 200  # claiming what one owns is a no-op
    assert r.json()["owner_device_id"] == ids["alice"]


async def test_a_claim_needs_a_device_token(client):
    assert (await client.post("/groups/me/owner/claim")).status_code == 401


async def test_a_dormant_owner_that_comes_back_closes_the_window(client, session):
    heads, ids, _ = await _group_of_three(client)
    await _go_quiet(session, ids["alice"])

    # Any authenticated request refreshes last_seen_at (app/auth.py).
    assert (await client.get("/groups/me", headers=heads["alice"])).status_code == 200
    r = await client.post("/groups/me/owner/claim", headers=heads["bob"])
    assert r.status_code == 409, r.text


async def test_a_group_with_one_live_device_owns_itself(client):
    """Alice leaves alone, leaving no owner; the next device to join is the only one there."""
    r = await client.post("/groups", json={"name": "solo", "device_label": "alice"})
    share = r.json()["group"]["share_token"]
    alice = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    assert (
        await client.post(f"/groups/me/devices/{r.json()['device']['id']}/revoke", headers=alice)
    ).status_code == 204

    r = await client.post("/groups/join", json={"share_token": share, "device_label": "bob"})
    assert r.status_code == 201
    bob_id = r.json()["device"]["id"]
    bob = {"Authorization": f"Bearer {r.json()['device']['token']}"}

    r = await client.get("/groups/me", headers=bob)
    assert r.json()["owner_device_id"] == bob_id
    r = await client.get("/groups/me/devices", headers=bob)
    assert [(d["id"], d["is_owner"]) for d in r.json()["devices"]] == [(bob_id, True)]
    assert (await client.post("/groups/me/rotate-share-token", headers=bob)).status_code == 200


def _utc(iso: str):
    from datetime import UTC, datetime

    parsed = datetime.fromisoformat(iso.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=UTC)


async def test_a_new_groups_usage_resets_at_the_next_month_start(client):
    from datetime import UTC, datetime

    from app.models.group import next_month_start

    r = await client.post("/groups", json={"name": "neuf", "device_label": "tel"})
    me = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    r = await client.get("/groups/me/usage", headers=me)
    assert r.status_code == 200, r.text
    body = r.json()
    now = datetime.now(UTC)
    assert _utc(body["resets_at"]) > now
    assert _utc(body["resets_at"]) == next_month_start(now)
    assert body["current_month_used_cents"] == 0


async def test_a_passed_reset_shows_nothing_spent_until_the_next_month_start(client, session):
    import uuid
    from datetime import UTC, datetime, timedelta

    from app.models import Group
    from app.models.group import next_month_start

    r = await client.post("/groups", json={"name": "ancien", "device_label": "tel"})
    group_id = uuid.UUID(r.json()["group"]["id"])
    me = {"Authorization": f"Bearer {r.json()['device']['token']}"}
    group = await session.get(Group, group_id)
    assert group is not None
    group.current_month_used_cents = 42
    group.budget_resets_at = datetime.now(UTC) - timedelta(days=3)
    await session.commit()

    r = await client.get("/groups/me/usage", headers=me)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["current_month_used_cents"] == 0
    assert _utc(body["resets_at"]) == next_month_start(datetime.now(UTC))
    r = await client.get("/groups/me", headers=me)
    assert r.json()["current_month_used_cents"] == 0


def test_current_period_rolls_over_only_once_the_reset_has_passed():
    from datetime import UTC, datetime

    from app.models import Group
    from app.services.budget import current_period

    now = datetime(2026, 12, 15, 9, 30, tzinfo=UTC)
    group = Group(name="g", current_month_used_cents=7)
    group.budget_resets_at = datetime(2027, 1, 1, tzinfo=UTC)
    assert current_period(group, now) == (7, datetime(2027, 1, 1, tzinfo=UTC))
    group.budget_resets_at = datetime(2026, 12, 1)  # naive, as SQLite hands it back
    assert current_period(group, now) == (0, datetime(2027, 1, 1, tzinfo=UTC))
