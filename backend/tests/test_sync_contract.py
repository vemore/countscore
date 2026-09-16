"""The /sync/push contract a client is written against: batch isolation, group scoping,
delete-wins, stable reject reasons, and the entities added for the Flutter client.

SQLite fixtures; the Postgres-only halves (BigInteger colours, the row lock on
server_seq) are at the end of test_sync_ws_integration.py.
"""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock

import pytest


@pytest.fixture(autouse=True)
def _stub_notify(monkeypatch):
    from app.routes import sync as sync_route

    monkeypatch.setattr(sync_route, "notify_new_seq", AsyncMock(return_value=None))


async def _group(client, name="g"):
    r = await client.post("/groups", json={"name": name, "device_label": "d"})
    assert r.status_code == 201, r.text
    body = r.json()
    return body, {"Authorization": f"Bearer {body['device']['token']}"}


async def _push(client, headers, *deltas):
    r = await client.post("/sync/push", json={"deltas": list(deltas)}, headers=headers)
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


async def _get(session_factory, cls, entity_uuid):
    async with session_factory() as s:
        return await s.get(cls, uuid.UUID(str(entity_uuid)))


# --- Batch isolation -------------------------------------------------------------


async def test_a_rejected_delta_does_not_undo_the_rest_of_its_batch(client, session_factory):
    from app.models import Game, Round

    _body, headers = await _group(client)
    game, round_a, round_b, round_c = (uuid.uuid4() for _ in range(4))

    body = await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("round", round_a, 2, game_id=str(game), round_number=1),
        _delta("game", uuid.uuid4(), 3),  # no name: IntegrityError at flush
        _delta("round", round_b, 4, game_id=str(game), round_number=1),  # number taken
        _delta("round", round_c, 5, game_id=str(game), round_number=2),
    )

    assert _statuses(body) == [
        ("applied", None),
        ("applied", None),
        ("rejected", "integrity constraint violation"),
        ("rejected", "round_number_taken"),
        ("applied", None),
    ]
    assert await _get(session_factory, Game, game) is not None
    assert await _get(session_factory, Round, round_a) is not None
    assert await _get(session_factory, Round, round_c) is not None

    pulled = (await client.get("/sync/pull?since_seq=0", headers=headers)).json()
    assert [d["server_seq"] for d in pulled["deltas"]] == [1, 2, 3]
    assert [d["entity_uuid"] for d in pulled["deltas"]] == [str(game), str(round_a), str(round_c)]
    assert body["server_seq_max"] == 3


async def test_server_seq_continues_across_pushes_without_gaps(client):
    _body, headers = await _group(client)
    first = await _push(client, headers, _delta("game", uuid.uuid4(), 1, name="A"))
    rejected = await _push(client, headers, _delta("game", uuid.uuid4(), 2))
    second = await _push(client, headers, _delta("game", uuid.uuid4(), 3, name="B"))

    assert first["server_seq_max"] == 1
    assert rejected["server_seq_max"] == 0
    assert second["server_seq_max"] == 2


# --- Group scoping (backend security review 2026-09-13, HIGH) ---------------------


async def test_a_device_cannot_touch_another_groups_game(client, session_factory):
    """The review's PoC, inverted: rename, attach a round, tombstone — all refused."""
    from app.models import Game, Round

    a_body, a_headers = await _group(client, "A")
    _b_body, b_headers = await _group(client, "B")
    game = uuid.uuid4()
    await _push(client, a_headers, _delta("game", game, 1, name="Owned by A"))

    round_uuid = uuid.uuid4()
    body = await _push(
        client,
        b_headers,
        _delta("game", game, 10, name="Taken by B"),
        _delta("round", round_uuid, 11, game_id=str(game), round_number=1),
        _delta("game", game, 12, op="delete"),
    )

    assert _statuses(body) == [
        ("rejected", "not in group"),
        ("rejected", "parent_missing"),
        ("rejected", "not in group"),
    ]
    stored = await _get(session_factory, Game, game)
    assert (stored.name, str(stored.group_id), stored.deleted_at) == (
        "Owned by A",
        a_body["group"]["id"],
        None,
    )
    assert await _get(session_factory, Round, round_uuid) is None


async def test_child_entities_are_scoped_through_their_parents(client):
    _a_body, a_headers = await _group(client, "A")
    _b_body, b_headers = await _group(client, "B")
    game, rnd, player, score = (uuid.uuid4() for _ in range(4))
    await _push(
        client,
        a_headers,
        _delta("game", game, 1, name="G"),
        _delta("round", rnd, 2, game_id=str(game), round_number=1),
        _delta("player", player, 3, name="Alice", name_normalized="alice"),
        _delta("score", score, 4, round_id=str(rnd), player_id=str(player), value=5),
    )

    b_player = uuid.uuid4()
    body = await _push(
        client,
        b_headers,
        _delta("round", rnd, 10, round_number=9),
        _delta("score", score, 11, value=99),
        _delta("player", b_player, 12, name="Bob", name_normalized="bob"),
        # B's own player, A's round: the round is the parent that is not B's.
        _delta("score", uuid.uuid4(), 13, round_id=str(rnd), player_id=str(b_player), value=1),
        _delta("game", uuid.uuid4(), 14, name="B game", game_type_id=str(uuid.uuid4())),
    )

    assert _statuses(body) == [
        ("rejected", "not in group"),
        ("rejected", "not in group"),
        ("applied", None),
        ("rejected", "parent_missing"),
        ("rejected", "parent_missing"),
    ]


async def test_pull_never_returns_another_groups_log(client):
    _a_body, a_headers = await _group(client, "A")
    _b_body, b_headers = await _group(client, "B")
    await _push(client, a_headers, _delta("game", uuid.uuid4(), 1, name="A only"))

    pulled = (await client.get("/sync/pull?since_seq=0", headers=b_headers)).json()
    assert pulled["deltas"] == []


# --- Delete wins ------------------------------------------------------------------


async def test_a_delete_beats_a_later_upsert_with_a_higher_lamport(client, session_factory):
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(client, headers, _delta("game", game, 1, name="G"))
    await _push(client, headers, _delta("game", game, 2, op="delete"))

    body = await _push(client, headers, _delta("game", game, 50, name="Back?"))

    assert _statuses(body) == [("merged_lww", None)]
    stored = await _get(session_factory, Game, game)
    assert stored.name == "G"
    assert stored.deleted_at is not None


async def test_a_payload_cannot_undelete_or_forge_server_columns(client, session_factory):
    from app.models import Game

    body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(client, headers, _delta("game", game, 1, name="G"))
    await _push(client, headers, _delta("game", game, 2, op="delete"))

    await _push(
        client,
        headers,
        _delta("game", game, 3, name="G", deleted_at=None, group_id=str(uuid.uuid4())),
    )

    stored = await _get(session_factory, Game, game)
    assert stored.deleted_at is not None
    assert str(stored.group_id) == body["group"]["id"]


async def test_a_delete_for_an_unknown_uuid_blocks_its_creation(client, session_factory):
    """Device B deletes a game whose creation it pushed nothing of — it may arrive later."""
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    assert _statuses(await _push(client, headers, _delta("game", game, 1, op="delete"))) == [
        ("applied", None)
    ]

    body = await _push(client, headers, _delta("game", game, 2, name="Too late"))

    assert _statuses(body) == [("merged_lww", None)]
    assert await _get(session_factory, Game, game) is None


async def test_the_logged_payload_carries_only_client_columns(client):
    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G", deleted_at=None, id="x", unknown=1),
    )

    pulled = (await client.get("/sync/pull?since_seq=0", headers=headers)).json()
    assert pulled["deltas"][0]["payload"] == {"name": "G"}


# --- Live-row uniqueness and reasons ----------------------------------------------


async def test_a_deleted_round_frees_its_number(client):
    _body, headers = await _group(client)
    game, old_round = uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("round", old_round, 2, game_id=str(game), round_number=5),
        _delta("round", old_round, 3, op="delete"),
    )

    body = await _push(
        client, headers, _delta("round", uuid.uuid4(), 4, game_id=str(game), round_number=5)
    )

    assert _statuses(body) == [("applied", None)]


async def test_duplicate_score_and_names_have_their_own_reasons(client):
    _body, headers = await _group(client)
    game, rnd, player = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("round", rnd, 2, game_id=str(game), round_number=1),
        _delta("player", player, 3, name="Alice", name_normalized="alice"),
        _delta("score", uuid.uuid4(), 4, round_id=str(rnd), player_id=str(player), value=1),
        _delta("game_type", uuid.uuid4(), 5, name="Tarot", icon_code_point=1, card_color_value=1),
    )

    body = await _push(
        client,
        headers,
        _delta("score", uuid.uuid4(), 6, round_id=str(rnd), player_id=str(player), value=2),
        _delta("player", uuid.uuid4(), 7, name="ALICE", name_normalized="alice"),
        _delta("game_type", uuid.uuid4(), 8, name="Tarot", icon_code_point=1, card_color_value=1),
    )

    assert _statuses(body) == [
        ("rejected", "score_exists"),
        ("rejected", "name_taken"),
        ("rejected", "name_taken"),
    ]


async def test_a_built_in_game_type_round_trips_its_key(client, session_factory):
    """`builtin_key` carries a built-in type's identity, and its displayed name with it.

    The `name` a device pushes is in that device's locale, so it is not the identity;
    the key is. Both travel, so a device that does not know the key still has a name
    to show.
    """
    from app.models.game import GameType

    _body, headers = await _group(client)
    entity = uuid.uuid4()
    body = await _push(
        client,
        headers,
        _delta(
            "game_type",
            entity,
            1,
            name="Autre",
            builtin_key="other",
            icon_code_point=1,
            card_color_value=1,
        ),
    )
    assert _statuses(body) == [("applied", None)]
    row = await _get(session_factory, GameType, entity)
    assert row.builtin_key == "other"
    assert row.name == "Autre"

    # A second device, in another locale, writing the same row: the name is
    # last-writer-wins and harmless, because nothing reads it for a built-in type.
    body = await _push(
        client,
        headers,
        _delta(
            "game_type",
            entity,
            2,
            name="その他",
            builtin_key="other",
            icon_code_point=1,
            card_color_value=1,
        ),
    )
    assert _statuses(body) == [("applied", None)]
    row = await _get(session_factory, GameType, entity)
    assert (row.builtin_key, row.name) == ("other", "その他")

    # The pull carries the key on to every other device.
    r = await client.get("/sync/pull", params={"since": 0}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["deltas"][-1]["payload"]["builtin_key"] == "other"


async def test_two_rows_cannot_claim_the_same_builtin_key(client):
    """One live row per (group, built-in key), whatever each device calls it.

    Without this, two devices that never pulled before pushing would mint two rows for
    one built-in type and the group would show it twice.
    """
    _body, headers = await _group(client)
    await _push(
        client,
        headers,
        _delta(
            "game_type",
            uuid.uuid4(),
            1,
            name="Yahtzee",
            builtin_key="yahtzee",
            icon_code_point=1,
            card_color_value=1,
        ),
    )

    body = await _push(
        client,
        headers,
        _delta(
            "game_type",
            uuid.uuid4(),
            2,
            name="ヤッツィー",
            builtin_key="yahtzee",
            icon_code_point=1,
            card_color_value=1,
        ),
        # A user's own type has no key, so two of them never collide this way.
        _delta(
            "game_type",
            uuid.uuid4(),
            3,
            name="Le jeu du jeudi",
            icon_code_point=1,
            card_color_value=1,
        ),
        _delta(
            "game_type",
            uuid.uuid4(),
            4,
            name="Le jeu du vendredi",
            icon_code_point=1,
            card_color_value=1,
        ),
    )
    assert _statuses(body) == [
        ("rejected", "builtin_key_taken"),
        ("applied", None),
        ("applied", None),
    ]


async def test_a_builtin_key_longer_than_the_column_is_refused(client):
    _body, headers = await _group(client)
    body = await _push(
        client,
        headers,
        _delta(
            "game_type",
            uuid.uuid4(),
            1,
            name="X",
            builtin_key="k" * 33,
            icon_code_point=1,
            card_color_value=1,
        ),
    )
    assert _statuses(body) == [("rejected", "builtin_key longer than 32 characters")]


async def test_renumbering_a_round_into_a_taken_number_is_refused(client):
    _body, headers = await _group(client)
    game, round_1, round_2 = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("round", round_1, 2, game_id=str(game), round_number=1),
        _delta("round", round_2, 3, game_id=str(game), round_number=2),
    )

    body = await _push(client, headers, _delta("round", round_2, 4, round_number=1))

    assert _statuses(body) == [("rejected", "round_number_taken")]


# --- Fields and entities added for the Flutter client -----------------------------


async def test_round_comment_round_trips(client, session_factory):
    from app.models import Round

    _body, headers = await _group(client)
    game, rnd = uuid.uuid4(), uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta("round", rnd, 2, game_id=str(game), round_number=1, comment="Zap à 3 !"),
    )

    assert (await _get(session_factory, Round, rnd)).comment == "Zap à 3 !"
    too_long = await _push(client, headers, _delta("round", rnd, 3, comment="x" * 501))
    assert too_long["results"][0]["reason"] == "comment longer than 500 characters"


async def test_game_ended_at_round_trips(client, session_factory):
    """`games.ended_at` has existed since 0001_initial but nothing ever set it.

    The client writes it when a game is declared over and writes it back to null
    when the game is reopened, so both directions have to survive the push — the
    null especially, since a payload that simply omitted the key would leave the
    other devices showing a game as finished forever.
    """
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()

    await _push(client, headers, _delta("game", game, 1, name="G", ended_at=None))
    assert (await _get(session_factory, Game, game)).ended_at is None

    await _push(
        client,
        headers,
        _delta("game", game, 2, name="G", ended_at="2026-09-16T19:30:00+00:00"),
    )
    ended = (await _get(session_factory, Game, game)).ended_at
    assert ended is not None
    assert ended.isoformat().startswith("2026-09-16T19:30:00")

    # Reopened on another device: the null must land, not be ignored.
    await _push(client, headers, _delta("game", game, 3, name="G", ended_at=None))
    assert (await _get(session_factory, Game, game)).ended_at is None


async def test_game_ended_at_reaches_the_other_devices(client, session_factory):
    """A pulled delta must carry the field, or the fact never leaves the device."""
    _body, headers = await _group(client)
    game = uuid.uuid4()
    await _push(
        client,
        headers,
        _delta("game", game, 1, name="G", ended_at="2026-09-16T19:30:00+00:00"),
    )

    r = await client.get("/sync/pull?since_seq=0", headers=headers)
    assert r.status_code == 200, r.text
    payload = next(d["payload"] for d in r.json()["deltas"] if d["entity_type"] == "game")
    assert payload["ended_at"].startswith("2026-09-16T19:30:00")


async def test_game_analysis_is_a_synced_entity(client, session_factory):
    from app.models import GameAnalysis

    _body, headers = await _group(client)
    game, analysis = uuid.uuid4(), uuid.uuid4()
    body = await _push(
        client,
        headers,
        _delta("game", game, 1, name="G"),
        _delta(
            "game_analysis",
            analysis,
            2,
            game_id=str(game),
            content="# Analyse",
            model_id="gemini-2.5-flash",
            generated_at="2026-09-13T10:00:00+00:00",
        ),
        _delta("game_analysis", uuid.uuid4(), 3, game_id=str(game), content="second"),
    )

    assert _statuses(body) == [
        ("applied", None),
        ("applied", None),
        ("rejected", "analysis_exists"),
    ]
    stored = await _get(session_factory, GameAnalysis, analysis)
    assert (stored.content, stored.model_id) == ("# Analyse", "gemini-2.5-flash")


async def test_opaque_argb_colours_are_accepted(client, session_factory):
    from app.models import Player

    _body, headers = await _group(client)
    player = uuid.uuid4()
    body = await _push(
        client,
        headers,
        _delta("player", player, 1, name="Alice", name_normalized="alice", color_value=0xFFFFC107),
    )

    assert _statuses(body) == [("applied", None)]
    assert (await _get(session_factory, Player, player)).color_value == 0xFFFFC107
