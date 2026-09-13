"""Tests for the single-use WebSocket handshake tickets."""

from __future__ import annotations

import uuid

from app.services import ws_ticket


def test_issue_then_consume_returns_the_device_and_group():
    device_id, group_id = uuid.uuid4(), uuid.uuid4()
    ticket = ws_ticket.issue(device_id, group_id)

    assert ws_ticket.consume(ticket) == (device_id, group_id)


def test_ticket_is_single_use():
    ticket = ws_ticket.issue(uuid.uuid4(), uuid.uuid4())

    assert ws_ticket.consume(ticket) is not None
    assert ws_ticket.consume(ticket) is None


def test_unknown_and_empty_tickets_are_refused():
    assert ws_ticket.consume("") is None
    assert ws_ticket.consume("not-a-ticket") is None


def test_expired_ticket_is_refused(monkeypatch):
    """A ticket past its TTL must not be redeemable, even though it exists."""
    clock = [1000.0]
    monkeypatch.setattr(ws_ticket.time, "monotonic", lambda: clock[0])

    ticket = ws_ticket.issue(uuid.uuid4(), uuid.uuid4())
    clock[0] += ws_ticket.TICKET_TTL_SECONDS + 1

    assert ws_ticket.consume(ticket) is None


def test_tickets_are_distinct_and_unguessable():
    group_id = uuid.uuid4()
    tickets = {ws_ticket.issue(uuid.uuid4(), group_id) for _ in range(50)}

    assert len(tickets) == 50
    assert all(len(t) >= 32 for t in tickets)


async def test_ws_ticket_endpoint_requires_a_device(client):
    r = await client.post("/sync/ws-ticket")
    assert r.status_code == 401


async def test_ws_ticket_endpoint_returns_a_redeemable_ticket(client):
    created = await client.post("/groups", json={"name": "g", "device_label": "d"})
    token = created.json()["device"]["token"]

    r = await client.post("/sync/ws-ticket", headers={"Authorization": f"Bearer {token}"})

    assert r.status_code == 200
    body = r.json()
    assert body["expires_in"] == ws_ticket.TICKET_TTL_SECONDS
    assert ws_ticket.consume(body["ticket"]) is not None
