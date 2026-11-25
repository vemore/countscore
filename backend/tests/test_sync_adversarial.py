"""/sync against stale, replayed and hostile input — one test per case.

Every test asserts the answer **and** that nothing else changed: no row written for a
rejected delta, no ``server_seq`` consumed, nothing new in any group's pull. ``_world``
snapshots every synced table, ``change_log`` and each group's ``last_server_seq``, so
"nothing else changed" is one equality.

SQLite fixtures, ``pg_notify`` stubbed. The cases only Postgres can show (a NUL byte, a
lone surrogate, two device rows of one install pushing at the same instant) are at the end
of ``test_sync_ws_integration.py``. Wip entry:
``wip/done/2026-11-25-sync-server-adversarial-api-tests.md``.
"""

from __future__ import annotations

import json
import uuid
from typing import Any
from unittest.mock import AsyncMock

import pytest
from sqlalchemy import select


@pytest.fixture(autouse=True)
def _stub_notify(monkeypatch):
    from app.routes import sync as sync_route

    monkeypatch.setattr(sync_route, "notify_new_seq", AsyncMock(return_value=None))


# --- Helpers -----------------------------------------------------------------------


async def _group(client, name="g"):
    r = await client.post("/groups", json={"name": name, "device_label": "d"})
    assert r.status_code == 201, r.text
    body = r.json()
    return body, {"Authorization": f"Bearer {body['device']['token']}"}


async def _push(client, headers, *deltas):
    # Encoded here rather than by httpx, which refuses NaN: a client can still send it.
    r = await client.post(
        "/sync/push",
        content=json.dumps({"deltas": list(deltas)}, allow_nan=True),
        headers={**headers, "Content-Type": "application/json"},
    )
    assert r.status_code == 200, r.text
    return r.json()


async def _pull(client, headers, since_seq=0):
    r = await client.get(f"/sync/pull?since_seq={since_seq}", headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def _delta(entity_type, entity_uuid, lamport, op="upsert", **payload):
    return {
        "entity_type": entity_type,
        "entity_uuid": str(entity_uuid),
        "op": op,
        "payload": payload,
        "client_lamport": lamport,
    }


def _statuses(body):
    return [(r["status"], r["reason"]) for r in body["results"]]


async def _world(session_factory) -> dict[str, Any]:
    """Every synced row, the whole log and each group's sequence, comparable by ``==``.

    Devices are left out: ``last_seen_at`` moves on every authenticated request.
    """
    from app.models import (
        ChangeLog,
        Game,
        GameAnalysis,
        GamePlayer,
        GameType,
        Group,
        Player,
        Round,
        Score,
    )

    world: dict[str, Any] = {}
    async with session_factory() as s:
        for cls in (
            Group,
            Player,
            GameType,
            Game,
            GamePlayer,
            Round,
            Score,
            GameAnalysis,
            ChangeLog,
        ):
            rows = (await s.execute(select(cls))).scalars().all()
            world[cls.__tablename__] = sorted(repr(sorted(r.model_dump().items())) for r in rows)
    return world


async def _get(session_factory, cls, entity_uuid):
    async with session_factory() as s:
        return await s.get(cls, uuid.UUID(str(entity_uuid)))


async def _seed(client, headers) -> dict[str, uuid.UUID]:
    """One live row of every entity type in the caller's group, at lamports 1 to 7."""
    ids = {
        k: uuid.uuid4()
        for k in ("game_type", "player", "game", "game_player", "round", "score", "analysis")
    }
    body = await _push(
        client,
        headers,
        _delta(
            "game_type", ids["game_type"], 1, name="Tarot", icon_code_point=1, card_color_value=1
        ),
        _delta("player", ids["player"], 2, name="Alice"),
        _delta("game", ids["game"], 3, name="G", game_type_id=str(ids["game_type"])),
        _delta(
            "game_player",
            ids["game_player"],
            4,
            game_id=str(ids["game"]),
            player_id=str(ids["player"]),
            order_index=0,
        ),
        _delta("round", ids["round"], 5, game_id=str(ids["game"]), round_number=1),
        _delta(
            "score",
            ids["score"],
            6,
            round_id=str(ids["round"]),
            player_id=str(ids["player"]),
            value=10,
        ),
        _delta("game_analysis", ids["analysis"], 7, game_id=str(ids["game"]), content="Well"),
    )
    assert {r["status"] for r in body["results"]} == {"applied"}, body
    return ids


async def _two_groups(client):
    """Groups A and B, each seeded; what each one's pull holds before the test acts."""
    a_body, a = await _group(client, "A")
    b_body, b = await _group(client, "B")
    a_ids = await _seed(client, a)
    b_ids = await _seed(client, b)
    return a_body, a, a_ids, b_body, b, b_ids


async def _free_parents(client, headers) -> dict[str, str]:
    """Seeded parents with a free slot under them: a game with no round and no analysis,
    and a round of the seeded game with no score. Payload placeholders → uuids."""
    ids = await _seed(client, headers)
    game, rnd = uuid.uuid4(), uuid.uuid4()
    body = await _push(
        client,
        headers,
        _delta("game", game, 8, name="Free"),
        _delta("round", rnd, 9, game_id=str(ids["game"]), round_number=2),
    )
    assert {r["status"] for r in body["results"]} == {"applied"}, body
    return {"GAME": str(game), "ROUND": str(rnd), "PLAYER": str(ids["player"])}


def _resolve(payload: dict, refs: dict[str, str]) -> dict:
    return {k: refs.get(v, v) if isinstance(v, str) else v for k, v in payload.items()}


def _uuids(pull) -> set[str]:
    return {d["entity_uuid"] for d in pull["deltas"]}


# --- Cross-group -------------------------------------------------------------------

# entity type → the payload A would send for it, built from A's own ids, so that the only
# thing wrong with the delta is the uuid it names.
_OWN_PAYLOADS = {
    "player": lambda ids: {"name": "Mallory"},
    "game_type": lambda ids: {"name": "Stolen", "icon_code_point": 2, "card_color_value": 2},
    "game": lambda ids: {"name": "Stolen", "game_type_id": str(ids["game_type"])},
    "round": lambda ids: {"game_id": str(ids["game"]), "round_number": 9},
    "score": lambda ids: {
        "round_id": str(ids["round"]),
        "player_id": str(ids["player"]),
        "value": 99,
    },
    "game_analysis": lambda ids: {"game_id": str(ids["game"]), "content": "Stolen"},
}
_ID_KEY = {"game_analysis": "analysis"}


@pytest.mark.parametrize("op", ["upsert", "delete"])
@pytest.mark.parametrize("entity_type", list(_OWN_PAYLOADS))
async def test_a_token_of_a_pushing_an_uuid_of_b_is_not_in_group(
    client, session_factory, entity_type, op
):
    _a_body, a, a_ids, _b_body, b, b_ids = await _two_groups(client)
    b_pull = await _pull(client, b)
    before = await _world(session_factory)

    target = b_ids[_ID_KEY.get(entity_type, entity_type)]
    payload = _OWN_PAYLOADS[entity_type](a_ids) if op == "upsert" else {}
    body = await _push(client, a, _delta(entity_type, target, 100, op=op, **payload))

    assert _statuses(body) == [("rejected", "not in group")]
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before
    assert await _pull(client, b) == b_pull
    assert str(target) not in _uuids(await _pull(client, a))


@pytest.mark.parametrize(
    ("entity_type", "parent_key", "payload"),
    [
        ("game", "game_type", lambda own, other: {"name": "G", "game_type_id": other}),
        ("round", "game", lambda own, other: {"game_id": other, "round_number": 2}),
        (
            "score",
            "round",
            lambda own, other: {"round_id": other, "player_id": own["player"], "value": 1},
        ),
        (
            "score",
            "player",
            lambda own, other: {"round_id": own["round"], "player_id": other, "value": 1},
        ),
        ("game_analysis", "game", lambda own, other: {"game_id": other, "content": "x"}),
    ],
)
async def test_a_payload_whose_parent_is_in_b_is_parent_missing(
    client, session_factory, entity_type, parent_key, payload
):
    _a_body, a, a_ids, _b_body, _b, b_ids = await _two_groups(client)
    own = {k: str(v) for k, v in a_ids.items()}
    if entity_type == "score":
        # A fresh round of A's game, so the score's own slot is free and only the
        # parent named in B can be what is wrong with it.
        fresh_round = uuid.uuid4()
        await _push(
            client, a, _delta("round", fresh_round, 50, game_id=own["game"], round_number=2)
        )
        own["round"] = str(fresh_round)
    before = await _world(session_factory)

    entity = uuid.uuid4()
    body = await _push(
        client, a, _delta(entity_type, entity, 100, **payload(own, str(b_ids[parent_key])))
    )

    assert _statuses(body) == [("rejected", "parent_missing")]
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before


@pytest.mark.parametrize(
    ("in_b", "reason"), [("game", "game not in group"), ("player", "player not in group")]
)
async def test_a_game_player_naming_a_game_or_player_of_b_is_refused(
    client, session_factory, in_b, reason
):
    _a_body, a, a_ids, _b_body, _b, b_ids = await _two_groups(client)
    names = {"game": a_ids["game"], "player": a_ids["player"], in_b: b_ids[in_b]}
    before = await _world(session_factory)

    body = await _push(
        client,
        a,
        _delta(
            "game_player",
            uuid.uuid4(),
            100,
            game_id=str(names["game"]),
            player_id=str(names["player"]),
            order_index=1,
        ),
    )

    assert _statuses(body) == [("rejected", reason)]
    assert await _world(session_factory) == before


async def test_a_pull_of_a_never_returns_a_delta_of_b(client):
    a_body, a, a_ids, b_body, b, b_ids = await _two_groups(client)
    # B moves on after A's last pull: B's later sequence numbers must not show up either.
    await _push(client, b, _delta("game", b_ids["game"], 100, name="Renamed in B"))

    a_pull = await _pull(client, a)
    b_pull = await _pull(client, b)

    assert _uuids(a_pull) == {str(v) for v in a_ids.values()}
    assert _uuids(b_pull) == {str(v) for v in b_ids.values()}
    assert {d["origin_device_id"] for d in a_pull["deltas"]} == {a_body["device"]["id"]}
    assert [d["server_seq"] for d in a_pull["deltas"]] == list(range(1, 8))
    assert [d["server_seq"] for d in b_pull["deltas"]] == list(range(1, 9))
    # A cursor past A's own end, at a seq only B has reached, finds nothing.
    assert (await _pull(client, a, since_seq=7))["deltas"] == []
    assert b_body["device"]["id"] not in {d["origin_device_id"] for d in a_pull["deltas"]}


async def test_a_device_revoked_in_a_leaves_the_same_installs_device_in_b_working(
    client, session_factory
):
    a_body, a, _a_ids, _b_body, b, b_ids = await _two_groups(client)
    r = await client.post(f"/groups/me/devices/{a_body['device']['id']}/revoke", headers=a)
    assert r.status_code == 204, r.text
    before = await _world(session_factory)

    refused = await client.post(
        "/sync/push",
        json={"deltas": [_delta("game", uuid.uuid4(), 100, name="After leaving")]},
        headers=a,
    )
    assert refused.status_code == 401
    assert (await client.get("/sync/pull", headers=a)).status_code == 401
    assert (await client.post("/sync/ws-ticket", headers=a)).status_code == 401
    assert await _world(session_factory) == before

    body = await _push(client, b, _delta("game", b_ids["game"], 100, name="Still in B"))
    assert _statuses(body) == [("applied", None)]
    assert body["server_seq_max"] == 8
    assert (await _pull(client, b, since_seq=7))["deltas"][0]["payload"]["name"] == "Still in B"
    assert (await client.post("/sync/ws-ticket", headers=b)).status_code == 200


async def test_two_device_rows_of_one_install_use_the_same_lamports_without_colliding(
    client, session_factory
):
    """Dedup is keyed by device, and an install holds one device row per group: the
    same lamports in A and B are two different writes. Concurrently, on Postgres:
    ``test_two_device_rows_of_one_install_push_to_two_groups_at_once``."""
    _a_body, a = await _group(client, "A")
    _b_body, b = await _group(client, "B")
    a_games = [uuid.uuid4() for _ in range(3)]
    b_games = [uuid.uuid4() for _ in range(3)]

    a_res = await _push(
        client, a, *(_delta("game", g, i + 1, name="A") for i, g in enumerate(a_games))
    )
    b_res = await _push(
        client, b, *(_delta("game", g, i + 1, name="B") for i, g in enumerate(b_games))
    )

    assert _statuses(a_res) == _statuses(b_res) == [("applied", None)] * 3
    assert [r["server_seq"] for r in a_res["results"]] == [1, 2, 3]
    assert [r["server_seq"] for r in b_res["results"]] == [1, 2, 3]
    assert _uuids(await _pull(client, a)) == {str(g) for g in a_games}
    assert _uuids(await _pull(client, b)) == {str(g) for g in b_games}


# --- Replay: a restored backup --------------------------------------------------


async def test_a_reused_lamport_with_another_payload_is_rejected_lamport_reused(
    client, session_factory
):
    """A restore re-stamps lamports already used. This was answered ``duplicate`` until
    2026-11-25: the device was told an edit it never made had been kept, and its new
    payload was lost (the test that pinned it is in this file's history)."""
    from app.models import Game

    _body, headers = await _group(client)
    game, other = uuid.uuid4(), uuid.uuid4()
    await _push(client, headers, _delta("game", game, 7, name="Before the backup"))
    before = await _world(session_factory)

    replay = await _push(
        client,
        headers,
        _delta("game", game, 7, name="After the restore"),  # another payload
        _delta("game", other, 7, name="Before the backup"),  # another entity
        _delta("game", game, 7, op="delete"),  # another op
    )

    assert _statuses(replay) == [("rejected", "lamport_reused")] * 3
    assert [r["server_seq"] for r in replay["results"]] == [None] * 3
    assert replay["server_seq_max"] == 0
    assert (await _get(session_factory, Game, game)).name == "Before the backup"
    assert await _get(session_factory, Game, other) is None
    assert await _world(session_factory) == before


async def test_a_network_retry_of_the_logged_delta_is_still_a_duplicate(client, session_factory):
    _body, headers = await _group(client)
    game, player = uuid.uuid4(), uuid.uuid4()
    first = await _push(
        client,
        headers,
        _delta("game", game, 1, name="G", ended_at="2026-11-25T10:00:00.000Z"),
        _delta("player", player, 2, name="Zoé", name_normalized="zoé"),
        _delta("game", game, 3, op="delete"),
    )
    before = await _world(session_factory)

    retry = await _push(
        client,
        headers,
        # Keys the server does not know are not logged, so they do not make it another delta.
        _delta("game", game, 1, name="G", ended_at="2026-11-25T10:00:00.000Z", extra=1),
        _delta("player", player, 2, name="Zoé", name_normalized="zoé"),
        _delta("game", game, 3, op="delete"),
    )

    assert _statuses(retry) == [("duplicate", None)] * 3
    assert [r["server_seq"] for r in retry["results"]] == [1, 2, 3]
    assert retry["server_seq_max"] == 3
    assert await _world(session_factory) == before
    assert first["server_seq_max"] == 3


async def test_a_retry_that_spans_a_deploy_is_still_a_duplicate(client, session_factory):
    """The log holds what the server of the day logged. A retry answered by a newer one
    is compared with that payload re-canonicalised, on the keys it holds: an older
    server's player row (its client ``name_normalized`` as sent) and a column it did not
    know yet (``max_rounds``, a row logged before v22) are still the same delta."""
    from app.models import ChangeLog, Group

    body, headers = await _group(client)
    group_id, device_id = uuid.UUID(body["group"]["id"]), uuid.UUID(body["device"]["id"])
    player, game_type = uuid.uuid4(), uuid.uuid4()
    type_payload = {"name": "Chouineurs", "icon_code_point": 1, "card_color_value": 1}
    async with session_factory() as s:
        # As an older server logged them: the client's contradicting name_normalized kept,
        # and no max_rounds key at all.
        s.add(
            ChangeLog(
                group_id=group_id,
                origin_device_id=device_id,
                entity_type="player",
                entity_uuid=player,
                op="upsert",
                payload={"name": "Bob", "name_normalized": "zzz"},
                client_lamport=1,
                server_seq=1,
            )
        )
        s.add(
            ChangeLog(
                group_id=group_id,
                origin_device_id=device_id,
                entity_type="game_type",
                entity_uuid=game_type,
                op="upsert",
                payload=type_payload,
                client_lamport=2,
                server_seq=2,
            )
        )
        (await s.get(Group, group_id)).last_server_seq = 2
        await s.commit()
    before = await _world(session_factory)

    retry = await _push(
        client,
        headers,
        _delta("player", player, 1, name="Bob", name_normalized="zzz"),
        _delta("game_type", game_type, 2, **type_payload, max_rounds=None),
    )
    other = await _push(
        client,
        headers,
        _delta("game_type", game_type, 2, **{**type_payload, "name": "Other"}, max_rounds=None),
    )

    assert _statuses(retry) == [("duplicate", None)] * 2
    assert [r["server_seq"] for r in retry["results"]] == [1, 2]
    assert _statuses(other) == [("rejected", "lamport_reused")]
    assert await _world(session_factory) == before


async def test_a_lower_lamport_than_stored_is_merged_lww_and_changes_no_row(
    client, session_factory
):
    """The loser is logged — that is what makes its retry a ``duplicate`` — but the row
    keeps the winner, and pulling devices discard it by the same order."""
    from app.models import ChangeLog, Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(client, headers, _delta("game", game, 10, name="Winner"))
    row_before = (await _get(session_factory, Game, game)).model_dump()

    body = await _push(client, headers, _delta("game", game, 5, name="Late loser"))

    assert _statuses(body) == [("merged_lww", None)]
    assert body["server_seq_max"] == 2
    assert (await _get(session_factory, Game, game)).model_dump() == row_before
    async with session_factory() as s:
        log = (await s.execute(select(ChangeLog).order_by(ChangeLog.server_seq))).scalars().all()
    assert [(e.client_lamport, e.server_seq) for e in log] == [(10, 1), (5, 2)]


async def test_an_upsert_on_a_tombstone_is_merged_lww_and_resurrects_nothing(
    client, session_factory
):
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("game", game, 2, op="delete"),
    )
    deleted = (await _get(session_factory, Game, game)).model_dump()

    body = await _push(client, headers, _delta("game", game, 1000, name="Back from the dead"))

    assert _statuses(body) == [("merged_lww", None)]
    assert (await _get(session_factory, Game, game)).model_dump() == deleted
    assert deleted["deleted_at"] is not None


async def test_a_delete_of_an_unknown_uuid_creates_nothing_and_blocks_a_later_upsert(
    client, session_factory
):
    from app.models import Game

    _body, headers = await _group(client)
    ghost = uuid.uuid4()

    body = await _push(client, headers, _delta("game", ghost, 1, op="delete"))
    assert _statuses(body) == [("applied", None)]
    assert await _get(session_factory, Game, ghost) is None
    [logged] = (await _pull(client, headers))["deltas"]
    assert (logged["op"], logged["payload"]) == ("delete", {})

    later = await _push(client, headers, _delta("game", ghost, 2, name="Never"))
    assert _statuses(later) == [("merged_lww", None)]
    assert await _get(session_factory, Game, ghost) is None


async def test_delete_then_upsert_in_one_batch_leaves_the_row_deleted(client, session_factory):
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(client, headers, _delta("game", game, 1, name="G"))

    body = await _push(
        client,
        headers,
        _delta("game", game, 2, op="delete"),
        _delta("game", game, 3, name="Edited after the delete"),
    )

    assert _statuses(body) == [("applied", None), ("merged_lww", None)]
    stored = await _get(session_factory, Game, game)
    assert (stored.name, stored.deleted_at is not None) == ("G", True)


# --- Renames -------------------------------------------------------------------------


@pytest.mark.parametrize("taken", ["Bob", "bob", "  BOB  "])
async def test_a_player_renamed_onto_a_name_held_in_the_group_is_name_taken(
    client, session_factory, taken
):
    _body, headers = await _group(client)
    alice, bob = uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("player", alice, 1, name="Alice", name_normalized="alice"),
        _delta("player", bob, 2, name="Bob", name_normalized="bob"),
    )
    before = await _world(session_factory)

    body = await _push(
        client, headers, _delta("player", alice, 3, name=taken, name_normalized=taken.lower())
    )

    assert _statuses(body) == [("rejected", "name_taken")]
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before


@pytest.mark.parametrize(
    "payload",
    [
        {"name": "Bob"},  # a rename that leaves the old name_normalized behind
        {"name": "Bob", "name_normalized": "not-bob"},  # one that disagrees with the name
    ],
)
async def test_a_stale_or_contradicting_name_normalized_is_derived_by_the_server(
    client, session_factory, payload
):
    """The unique rule compares ``name_normalized``. Taken from the client as is, a
    payload that left it stale or contradicted the name put two live "Bob" in one group."""
    from app.models import Player

    _body, headers = await _group(client)
    alice, bob = uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("player", alice, 1, name="Alice", name_normalized="alice"),
        _delta("player", bob, 2, name="Bob", name_normalized="zzz-not-bob"),
    )
    assert (await _get(session_factory, Player, bob)).name_normalized == "bob"
    before = await _world(session_factory)

    body = await _push(client, headers, _delta("player", alice, 3, **payload))

    assert _statuses(body) == [("rejected", "name_taken")]
    assert await _world(session_factory) == before


# name → normalizeName (lib/services/sync/sync_ids.dart) on the Dart VM: code by code, so
# no final sigma, and "İ" to one "i". Python's lower() gives "σοφος" and "i̇" instead.
_TURKISH_32 = "İ" + "a" * 31


@pytest.mark.parametrize(
    ("held", "pushed", "status"),
    [
        # Greek capitals and a final sigma: two players to the app, so two here.
        (("ΣΟΦΟΣ", "σοφοσ"), ("Σοφος", "σοφος"), ("applied", None)),
        (("Σοφος", "σοφος"), ("ΣΟΦΟΣ", "σοφοσ"), ("applied", None)),
        # The same name to the app is the same name here.
        (("ΣΟΦΟΣ", "σοφοσ"), ("Σοφοσ", "σοφοσ"), ("rejected", "name_taken")),
        # A Turkish dotted capital in a name of 32: 32 once lowered, as the app counts.
        (("Bob", "bob"), (_TURKISH_32, "i" + "a" * 31), ("applied", None)),
        (("Iaaa", "iaaa"), ("İaaa", "iaaa"), ("rejected", "name_taken")),
        # The PWA lowers through JavaScript, which keeps the dot: the same name too.
        (("İaaa", "i̇aaa"), ("Iaaa", "iaaa"), ("applied", None)),
    ],
)
async def test_name_normalized_agrees_with_the_app_on_greek_and_turkish(
    client, session_factory, held, pushed, status
):
    """The server keeps the app's own lowercasing when it is one of ``name``, so names a
    device holds apart are not ``name_taken`` here, and names it merges are."""
    from app.models import Player

    _body, headers = await _group(client)
    first, second = uuid.uuid4(), uuid.uuid4()
    setup = await _push(
        client, headers, _delta("player", first, 1, name=held[0], name_normalized=held[1])
    )
    assert _statuses(setup) == [("applied", None)]
    before = await _world(session_factory)

    body = await _push(
        client, headers, _delta("player", second, 2, name=pushed[0], name_normalized=pushed[1])
    )

    assert _statuses(body) == [status]
    if status[0] == "applied":
        assert (await _get(session_factory, Player, second)).name_normalized == pushed[1]
    else:
        assert await _world(session_factory) == before


@pytest.mark.parametrize(
    ("name", "derived"),
    [("ΣΟΦΟΣ", "σοφοσ"), ("Σοφος", "σοφος"), (_TURKISH_32, "i" + "a" * 31), (" Zoé ", "zoé")],
)
async def test_a_derived_name_normalized_is_the_dart_vms(client, session_factory, name, derived):
    """Derived only when the payload sends none (or a contradicting one): as the Android
    app would have computed it, and never longer than the name."""
    from app.models import Player

    _body, headers = await _group(client)
    player = uuid.uuid4()
    body = await _push(client, headers, _delta("player", player, 1, name=name))
    assert _statuses(body) == [("applied", None)]
    assert (await _get(session_factory, Player, player)).name_normalized == derived


async def test_a_byte_order_mark_never_reaches_name_normalized(client, session_factory):
    """Dart's trim drops a BOM and Python's strip does not; the app trims the name before
    sending it, and the player-name allow-list refuses a BOM left in one, so the two trim
    sets never meet a stored name. As the app sends a name typed with a leading BOM:"""
    from app.models import Player

    _body, headers = await _group(client)
    player = uuid.uuid4()
    body = await _push(
        client, headers, _delta("player", player, 1, name="Zoé", name_normalized="zoé")
    )
    assert _statuses(body) == [("applied", None)]
    assert (await _get(session_factory, Player, player)).name_normalized == "zoé"
    before = await _world(session_factory)

    raw = await _push(
        client,
        headers,
        _delta("player", uuid.uuid4(), 2, name="﻿Zoé", name_normalized="zoé"),
    )
    assert _statuses(raw) == [("rejected", "name contains disallowed characters")]
    assert await _world(session_factory) == before


async def test_a_name_free_in_a_and_taken_in_b_is_applied_in_a_only(client, session_factory):
    from app.models import Player

    _a_body, a, a_ids, _b_body, b, b_ids = await _two_groups(client)
    await _push(client, b, _delta("player", uuid.uuid4(), 100, name="Charlie"))
    b_pull = await _pull(client, b)

    in_a = await _push(client, a, _delta("player", a_ids["player"], 100, name="Charlie"))
    assert _statuses(in_a) == [("applied", None)]
    assert (await _get(session_factory, Player, a_ids["player"])).name == "Charlie"
    assert await _pull(client, b) == b_pull

    before = await _world(session_factory)
    in_b = await _push(client, b, _delta("player", b_ids["player"], 101, name="Charlie"))
    assert _statuses(in_b) == [("rejected", "name_taken")]
    assert await _world(session_factory) == before


async def test_a_player_renamed_then_deleted_frees_both_names(client, session_factory):
    from app.models import Player

    _body, headers = await _group(client)
    thibaut = uuid.uuid4()
    await _push(client, headers, _delta("player", thibaut, 1, name="Thibaut"))

    body = await _push(
        client,
        headers,
        _delta("player", thibaut, 2, name="Thibaut D"),
        _delta("player", thibaut, 3, op="delete"),
    )
    assert _statuses(body) == [("applied", None), ("applied", None)]
    stored = await _get(session_factory, Player, thibaut)
    assert (stored.name, stored.deleted_at is not None) == ("Thibaut D", True)

    newcomers = await _push(
        client,
        headers,
        _delta("player", uuid.uuid4(), 4, name="Thibaut"),
        _delta("player", uuid.uuid4(), 5, name="Thibaut D"),
    )
    assert _statuses(newcomers) == [("applied", None)] * 2


async def test_a_game_type_renamed_off_its_builtin_key(client, session_factory):
    """A renamed built-in type sends ``builtin_key`` null (``isBuiltinRename``): the key is
    freed for the group's next built-in row. A rename that omits the key keeps it."""
    from app.models import GameType

    _body, headers = await _group(client)
    zapzap, kept, again, clash = (uuid.uuid4() for _ in range(4))
    base = {"icon_code_point": 1, "card_color_value": 1}
    await _push(
        client,
        headers,
        _delta("game_type", zapzap, 1, name="ZapZap", builtin_key="zapzap", **base),
        _delta("game_type", kept, 2, name="Belote", builtin_key="belote", **base),
    )

    renamed = await _push(
        client,
        headers,
        _delta("game_type", zapzap, 3, name="Our ZapZap", builtin_key=None, **base),
        _delta("game_type", kept, 4, name="Our Belote", **base),  # no builtin_key: no opinion
    )
    assert _statuses(renamed) == [("applied", None)] * 2
    assert (await _get(session_factory, GameType, zapzap)).builtin_key is None
    assert (await _get(session_factory, GameType, kept)).builtin_key == "belote"

    reseeded = await _push(
        client,
        headers,
        _delta("game_type", again, 5, name="ZapZap", builtin_key="zapzap", **base),
    )
    assert _statuses(reseeded) == [("applied", None)]

    before = await _world(session_factory)
    refused = await _push(
        client,
        headers,
        _delta("game_type", clash, 6, name="Belote", builtin_key="belote", **base),
        _delta("game_type", zapzap, 7, name="ZapZap", **base),  # renamed back onto a held name
    )
    assert _statuses(refused) == [("rejected", "builtin_key_taken"), ("rejected", "name_taken")]
    assert await _world(session_factory) == before


# --- Malformed input ---------------------------------------------------------------


async def test_an_unknown_entity_type_is_one_rejected_delta_not_a_refused_batch(
    client, session_factory
):
    """A newer app may push an entity this server does not know yet: its siblings in the
    batch still go through. Until 2026-11-25 the whole batch was a 422."""
    _body, headers = await _group(client)
    game, rnd = uuid.uuid4(), uuid.uuid4()

    body = await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("spaceship", uuid.uuid4(), 2, name="Nope"),
        _delta("round", rnd, 3, game_id=str(game), round_number=1),
    )

    assert _statuses(body) == [
        ("applied", None),
        ("rejected", "unknown entity type"),
        ("applied", None),
    ]
    assert [r["server_seq"] for r in body["results"]] == [1, None, 2]
    assert _uuids(await _pull(client, headers)) == {str(game), str(rnd)}


@pytest.mark.parametrize(
    "envelope",
    [
        {"entity_type": "game", "entity_uuid": "not-a-uuid", "op": "upsert", "client_lamport": 1},
        {"entity_type": "game", "entity_uuid": 42, "op": "upsert", "client_lamport": 1},
        {"entity_type": "game", "op": "upsert", "client_lamport": 1},
        {"entity_type": "game", "entity_uuid": "UUID", "client_lamport": 1},
        {"entity_type": "game", "entity_uuid": "UUID", "op": "upsert"},
        {"entity_type": "game", "entity_uuid": "UUID", "op": "merge", "client_lamport": 1},
        {"entity_type": "", "entity_uuid": "UUID", "op": "upsert", "client_lamport": 1},
        {"entity_type": "x" * 33, "entity_uuid": "UUID", "op": "upsert", "client_lamport": 1},
        {"entity_type": None, "entity_uuid": "UUID", "op": "upsert", "client_lamport": 1},
        {"entity_type": "game", "entity_uuid": "UUID", "op": "upsert", "client_lamport": -1},
        {"entity_type": "game", "entity_uuid": "UUID", "op": "upsert", "client_lamport": 2**63},
        {"entity_type": "game", "entity_uuid": "UUID", "op": "upsert", "client_lamport": 1.5},
        {
            "entity_type": "game",
            "entity_uuid": "UUID",
            "op": "upsert",
            "client_lamport": 1,
            "payload": ["name", "G"],
        },
        {
            "entity_type": "game",
            "entity_uuid": "UUID",
            "op": "upsert",
            "client_lamport": 1,
            "payload": None,
        },
    ],
)
async def test_a_malformed_envelope_refuses_the_batch_whole_and_writes_nothing(
    client, session_factory, envelope
):
    """The envelope is the contract's shape, not a value: a 422 for the request, which
    no client of ours can send. A valid sibling is not applied either."""
    _body, headers = await _group(client)
    bad = {k: (str(uuid.uuid4()) if v == "UUID" else v) for k, v in envelope.items()}
    before = await _world(session_factory)

    r = await client.post(
        "/sync/push",
        json={"deltas": [_delta("game", uuid.uuid4(), 1000, name="Sibling"), bad]},
        headers=headers,
    )

    assert r.status_code == 422, r.text
    assert await _world(session_factory) == before


async def test_the_largest_lamport_a_bigint_holds_is_accepted(client):
    _body, headers = await _group(client)
    game = uuid.uuid4()
    body = await _push(client, headers, _delta("game", game, 2**63 - 1, name="G"))
    assert _statuses(body) == [("applied", None)]
    assert (await _pull(client, headers))["deltas"][0]["client_lamport"] == 2**63 - 1


@pytest.mark.parametrize(
    ("entity_type", "payload"),
    [
        ("game", {}),  # no name
        ("game_type", {"name": "T", "card_color_value": 1}),  # no icon_code_point
        ("player", {"color_value": 1}),  # no name
        ("round", {"round_number": 1}),  # no game_id
        ("round", {"game_id": "GAME"}),  # no round_number
        ("score", {"round_id": "ROUND", "player_id": "PLAYER"}),  # no value
        ("game_analysis", {"game_id": "GAME"}),  # no content
        ("game", {"name": None}),
        ("round", {"game_id": "GAME", "round_number": None}),
        ("score", {"round_id": "ROUND", "player_id": "PLAYER", "value": None}),
    ],
)
async def test_a_create_missing_a_required_value_is_rejected_without_a_row(
    client, session_factory, entity_type, payload
):
    _body, headers = await _group(client)
    payload = _resolve(payload, await _free_parents(client, headers))
    before = await _world(session_factory)

    body = await _push(client, headers, _delta(entity_type, uuid.uuid4(), 100, **payload))

    assert _statuses(body) == [("rejected", "integrity constraint violation")]
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before


@pytest.mark.parametrize(
    ("entity_type", "key"),
    [
        ("game", "name"),
        ("game", "started_at"),
        ("game_type", "icon_code_point"),
        ("game_type", "card_color_value"),
        ("player", "name"),
        ("round", "round_number"),
        ("round", "game_id"),
        ("score", "value"),
        ("game_analysis", "content"),
    ],
)
async def test_an_update_nulling_a_required_value_is_rejected_and_the_row_kept(
    client, session_factory, entity_type, key
):
    _body, headers = await _group(client)
    ids = await _seed(client, headers)
    before = await _world(session_factory)

    target = ids[_ID_KEY.get(entity_type, entity_type)]
    body = await _push(client, headers, _delta(entity_type, target, 100, **{key: None}))

    assert body["results"][0]["status"] == "rejected"
    assert body["results"][0]["reason"] in ("integrity constraint violation", "parent_missing")
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before


async def test_extra_keys_are_neither_stored_nor_logged(client, session_factory):
    from app.models import Game

    body_a, headers = await _group(client)
    _b_body, b = await _group(client, "B")
    game = uuid.uuid4()
    body = await _push(
        client,
        headers,
        {
            **_delta(
                "game",
                game,
                1,
                name="G",
                id=str(uuid.uuid4()),
                group_id=_b_body["group"]["id"],
                deleted_at="2026-01-01T00:00:00Z",
                created_at="2000-01-01T00:00:00Z",
                evil={"nested": ["value"]},
            ),
            "server_seq": 999,
            "origin_device_id": str(uuid.uuid4()),
        },
    )

    assert _statuses(body) == [("applied", None)]
    assert body["server_seq_max"] == 1
    stored = await _get(session_factory, Game, game)
    assert str(stored.group_id) == body_a["group"]["id"]
    assert stored.deleted_at is None
    assert stored.created_at.year > 2000
    [logged] = (await _pull(client, headers))["deltas"]
    assert logged["payload"] == {"name": "G"}
    assert logged["origin_device_id"] == body_a["device"]["id"]
    assert (await _pull(client, b))["deltas"] == []


@pytest.mark.parametrize(
    ("entity_type", "payload", "reason"),
    [
        ("game", {"name": "G", "is_lowest_score_wins": "yes"}, "must be a boolean"),
        ("game", {"name": "G", "is_lowest_score_wins": 1}, "must be a boolean"),
        ("game", {"name": "G", "is_lowest_score_wins": float("nan")}, "must be a boolean"),
        ("game", {"name": "G", "started_at": 12345}, "must be an ISO 8601 timestamp"),
        ("game", {"name": "G", "ended_at": {"at": 1}}, "must be an ISO 8601 timestamp"),
        ("game", {"name": "G", "started_at": "yesterday"}, "must be an ISO 8601 timestamp"),
        ("game", {"name": "G", "started_at": "2026-W48-3"}, "must be an ISO 8601 timestamp"),
        # No zone: every pulling device would read it in its own local time.
        ("game", {"name": "G", "ended_at": "2026-11-25T10:00:00"}, "ISO 8601 timestamp"),
        ("game", {"name": "G", "ended_at": "2026-11-25T10:00:00.000"}, "ISO 8601 timestamp"),
        ("game", {"name": "G", "started_at": "2026-13-01T00:00:00Z"}, "ISO 8601 timestamp"),
        # Fullwidth digits: Unicode digits, not the ASCII ones a timestamp is made of.
        (
            "game",
            {
                "name": "G",
                "started_at": "".join(chr(0xFF10 + int(c)) for c in "2026") + "-11-25T10:00:00Z",
            },
            "ISO 8601 timestamp",
        ),
        ("game", {"name": 1.5}, "name must be a string"),
        ("game", {"name": ["G"]}, "name must be a string"),
        ("game", {"name": "G", "game_type_id": 5}, "parent_missing"),
        ("game", {"name": "G", "game_type_id": "not-a-uuid"}, "parent_missing"),
        ("round", {"game_id": "not-a-uuid", "round_number": 1}, "parent_missing"),
        ("round", {"game_id": "GAME", "round_number": "2"}, "round_number must be an integer"),
        ("round", {"game_id": "GAME", "round_number": 2, "comment": 7}, "must be a string"),
        ("score", {"round_id": "ROUND", "player_id": "PLAYER", "value": 1.5}, "an integer"),
        ("score", {"round_id": "ROUND", "player_id": "PLAYER", "value": True}, "an integer"),
        (
            "game_type",
            {"name": "T", "icon_code_point": 1, "card_color_value": 1, "is_default": "x"},
            "is_default must be a boolean",
        ),
        (
            "game_type",
            {"name": "T", "icon_code_point": 1, "card_color_value": 1, "rules": 5},
            "rules must be a string",
        ),
        (
            "game_type",
            {"name": "T", "icon_code_point": 1, "card_color_value": 1, "keypad_shortcut": 5},
            "keypad_shortcut must be a string",
        ),
        ("game_analysis", {"game_id": "GAME", "content": "x", "generated_at": 3}, "ISO 8601"),
        ("game_analysis", {"game_id": "GAME", "content": {"text": "x"}}, "must be a string"),
        # Postgres refuses both in a text column and in the jsonb log; SQLite stores them,
        # so the check runs on both. Through Postgres: test_sync_ws_integration.py.
        ("game", {"name": "a\x00b"}, "name contains a NUL character"),
        ("game_analysis", {"game_id": "GAME", "content": "x", "model_id": "m\udfff"}, "UTF-8"),
        ("player", {"name": 42}, "name must be a string"),
        ("player", {"name": "Alice", "color_value": "red"}, "color_value must be an integer"),
        ("game_player", {"game_id": "GAME", "player_id": "PLAYER", "order_index": "1"}, "integer"),
        ("game_player", {"game_id": "GAME", "player_id": 5, "order_index": 1}, "malformed"),
    ],
)
async def test_a_value_of_the_wrong_json_type_is_rejected_not_a_500(
    client, session_factory, entity_type, payload, reason
):
    """Each of the boolean, timestamp and uuid cases reached the driver until 2026-11-25,
    and the whole push answered 500 — a batch the client then resent for ever. A
    malformed timestamp string was dropped from the row but logged, and every device
    that pulled it threw in ``DateTime.parse``."""
    _body, headers = await _group(client)
    payload = _resolve(payload, await _free_parents(client, headers))
    before = await _world(session_factory)

    body = await _push(client, headers, _delta(entity_type, uuid.uuid4(), 100, **payload))

    assert body["results"][0]["status"] == "rejected"
    assert reason in body["results"][0]["reason"]
    assert body["server_seq_max"] == 0
    assert await _world(session_factory) == before


@pytest.mark.parametrize(
    "stamp",
    [
        "2026-11-25T10:00:00.000Z",  # Dart's toIso8601String, UTC
        "2026-11-25T10:00:00.123456Z",  # with microseconds
        "2026-11-25T10:00:00+00:00",
        "2026-11-25T11:00:00.5+01:00",
    ],
)
async def test_every_timestamp_the_app_writes_is_accepted(client, session_factory, stamp):
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    body = await _push(client, headers, _delta("game", game, 1, name="G", ended_at=stamp))
    assert _statuses(body) == [("applied", None)]
    assert (await _get(session_factory, Game, game)).ended_at is not None
    assert (await _pull(client, headers))["deltas"][0]["payload"]["ended_at"] == stamp


@pytest.mark.parametrize(
    ("entity_type", "payload", "reason"),
    [
        ("game", {"name": "G" * 65}, "name longer than 64 characters"),
        ("player", {"name": "A" * 33}, "name longer than 32 characters"),
        ("round", {"game_id": "GAME", "round_number": 2, "comment": "c" * 501}, "comment longer"),
        (
            "game_type",
            {"name": "T", "icon_code_point": 1, "card_color_value": 1, "rules": "r" * 8001},
            "rules longer than 8000 characters",
        ),
        ("game_analysis", {"game_id": "GAME", "content": "x" * 20_001}, "content longer"),
        ("score", {"round_id": "ROUND", "player_id": "PLAYER", "value": 1_000_001}, "value out"),
        ("score", {"round_id": "ROUND", "player_id": "PLAYER", "value": -(10**30)}, "value out"),
        ("round", {"game_id": "GAME", "round_number": -1}, "round_number out of bounds"),
        ("round", {"game_id": "GAME", "round_number": 2**63}, "round_number out of bounds"),
        ("player", {"name": "Alice", "color_value": 2**32}, "color_value out of bounds"),
        (
            "game_type",
            {"name": "T", "icon_code_point": 1, "card_color_value": 1, "max_rounds": 0},
            "max_rounds out of bounds",
        ),
        (
            "game_type",
            {"name": "T", "icon_code_point": 0x110000, "card_color_value": 1},
            "icon_code_point out of bounds",
        ),
        ("game_player", {"game_id": "GAME", "player_id": "PLAYER", "order_index": 65}, "out of"),
    ],
)
async def test_a_value_past_its_bounds_is_rejected(
    client, session_factory, entity_type, payload, reason
):
    _body, headers = await _group(client)
    payload = _resolve(payload, await _free_parents(client, headers))
    before = await _world(session_factory)

    body = await _push(client, headers, _delta(entity_type, uuid.uuid4(), 100, **payload))

    assert body["results"][0]["status"] == "rejected"
    assert reason in body["results"][0]["reason"]
    assert await _world(session_factory) == before


@pytest.mark.parametrize(
    ("column", "value", "reason"),
    [
        ("player_dead_threshold", 2**31, "player_dead_threshold out of bounds"),
        ("card_color_value", 2**63, "card_color_value out of bounds"),
    ],
)
async def test_an_integer_column_without_a_bound_still_cannot_overflow(
    client, session_factory, monkeypatch, column, value, reason
):
    """The backstop under ``NUMERIC_BOUNDS``: a column added without a bound refuses what
    its SQL type cannot hold (INTEGER, BIGINT) instead of failing the push."""
    from app.services import delta_bounds

    bounds = {k: v for k, v in delta_bounds.NUMERIC_BOUNDS["game_type"].items() if k != column}
    monkeypatch.setitem(delta_bounds.NUMERIC_BOUNDS, "game_type", bounds)
    _body, headers = await _group(client)
    before = await _world(session_factory)

    payload = {"name": "T", "icon_code_point": 1, "card_color_value": 1, column: value}
    body = await _push(client, headers, _delta("game_type", uuid.uuid4(), 1, **payload))

    assert _statuses(body)[0][0] == "rejected"
    assert reason in _statuses(body)[0][1]
    assert await _world(session_factory) == before


async def test_a_batch_of_500_is_taken_and_one_of_501_refused_whole(client, session_factory):
    """The server's cap is 500 (``PushRequest``); the app sends batches of 100."""
    _body, headers = await _group(client)
    before = await _world(session_factory)

    over = [_delta("game", uuid.uuid4(), i, name="G") for i in range(1, 502)]
    r = await client.post("/sync/push", json={"deltas": over}, headers=headers)
    assert r.status_code == 422
    assert await _world(session_factory) == before

    body = await _push(client, headers, *over[:500])
    assert {r["status"] for r in body["results"]} == {"applied"}
    assert body["server_seq_max"] == 500


async def test_an_empty_batch_consumes_nothing(client, session_factory):
    _body, headers = await _group(client)
    await _push(client, headers, _delta("game", uuid.uuid4(), 1, name="G"))
    before = await _world(session_factory)

    for body in ({"deltas": []}, {}):
        r = await client.post("/sync/push", json=body, headers=headers)
        assert r.status_code == 200, r.text
        assert r.json() == {"results": [], "server_seq_max": 0}
    assert await _world(session_factory) == before


async def test_the_same_entity_twice_in_one_batch(client, session_factory):
    from app.models import Game

    _body, headers = await _group(client)
    rising, falling = uuid.uuid4(), uuid.uuid4()

    body = await _push(
        client,
        headers,
        _delta("game", rising, 1, name="First"),
        _delta("game", rising, 2, name="Second"),
        _delta("game", falling, 20, name="Newer"),
        _delta("game", falling, 10, name="Older"),
        _delta("game", rising, 2, name="Second"),  # the same delta again: a duplicate
        _delta("game", rising, 1, name="Other"),  # the same lamport, another payload
    )

    assert _statuses(body) == [
        ("applied", None),
        ("applied", None),
        ("applied", None),
        ("merged_lww", None),
        ("duplicate", None),
        ("rejected", "lamport_reused"),
    ]
    assert [r["server_seq"] for r in body["results"]] == [1, 2, 3, 4, 2, None]
    assert body["server_seq_max"] == 4
    assert (await _get(session_factory, Game, rising)).name == "Second"
    assert (await _get(session_factory, Game, falling)).name == "Newer"


@pytest.mark.parametrize(
    "query",
    [
        "since_seq=-1",
        f"since_seq={2**63}",
        f"since_seq={10**30}",
        "since_seq=abc",
        "limit=0",
        "limit=-1",
        "limit=2001",
        f"limit={10**30}",
    ],
)
async def test_a_pull_cursor_out_of_range_is_422(client, query):
    _body, headers = await _group(client)
    r = await client.get(f"/sync/pull?{query}", headers=headers)
    assert r.status_code == 422, r.text


async def test_a_pull_at_the_edges_of_its_range(client):
    _body, headers = await _group(client)
    await _push(client, headers, _delta("game", uuid.uuid4(), 1, name="G"))

    top = await _pull(client, headers, since_seq=2**63 - 1)
    assert top == {"deltas": [], "server_seq_max": 2**63 - 1, "has_more": False}
    r = await client.get("/sync/pull?since_seq=0&limit=2000", headers=headers)
    assert r.status_code == 200
    assert len(r.json()["deltas"]) == 1


# --- Membership ------------------------------------------------------------------


async def test_leave_then_rejoin_and_repush_old_games(client, session_factory):
    """Leaving turns the games local; sharing them again from the new device row pushes
    the same uuids at lamports that start over. Nothing is refused, nothing doubled."""
    body, old = await _group(client)
    ids = await _seed(client, old)
    world_before = await _world(session_factory)
    r = await client.post(f"/groups/me/devices/{body['device']['id']}/revoke", headers=old)
    assert r.status_code == 204, r.text

    joined = await client.post(
        "/groups/join",
        json={"share_token": body["group"]["share_token"], "device_label": "again"},
    )
    assert joined.status_code == 201, joined.text
    new = {"Authorization": f"Bearer {joined.json()['device']['token']}"}

    repush = await _push(
        client,
        new,
        _delta("game", ids["game"], 3, name="G", game_type_id=str(ids["game_type"])),
        _delta("round", ids["round"], 5, game_id=str(ids["game"]), round_number=1),
        _delta(
            "score",
            ids["score"],
            6,
            round_id=str(ids["round"]),
            player_id=str(ids["player"]),
            value=10,
        ),
    )

    assert {r["status"] for r in repush["results"]} <= {"applied", "merged_lww"}
    world_after = await _world(session_factory)
    for table in ("players", "game_types", "games", "game_players", "rounds", "scores"):
        assert len(world_after[table]) == len(world_before[table])
    from app.models import Game, Round, Score

    assert (await _get(session_factory, Game, ids["game"])).name == "G"
    assert (await _get(session_factory, Round, ids["round"])).round_number == 1
    assert (await _get(session_factory, Score, ids["score"])).value == 10
    # The old device row stays revoked.
    assert (await client.get("/sync/pull", headers=old)).status_code == 401


@pytest.mark.parametrize("also_drop_device", [False, True])
async def test_a_token_of_a_group_the_server_no_longer_has_is_401(
    client, session_factory, also_drop_device
):
    from app.models import Device, Group

    body, headers = await _group(client)
    _other_body, other = await _group(client, "Other")
    await _seed(client, other)
    async with session_factory() as s:
        # SQLite runs without foreign keys here, so the device row survives its group
        # unless removed too: both shapes of "the server no longer has it".
        if also_drop_device:
            await s.delete(await s.get(Device, uuid.UUID(body["device"]["id"])))
        await s.delete(await s.get(Group, uuid.UUID(body["group"]["id"])))
        await s.commit()
    before = await _world(session_factory)

    pushed = await client.post(
        "/sync/push",
        json={"deltas": [_delta("game", uuid.uuid4(), 1, name="Orphan")]},
        headers=headers,
    )
    assert pushed.status_code == 401
    assert (await client.get("/sync/pull", headers=headers)).status_code == 401
    assert (await client.post("/sync/ws-ticket", headers=headers)).status_code == 401
    assert await _world(session_factory) == before
