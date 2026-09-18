"""0005_group_owner gives every existing group the earliest-joined device still live.

The DDL itself is exercised by CI's `alembic upgrade/downgrade/check` round trip on
Postgres; this pins the back-fill statement, run here on the SQLite test engine against
groups created before owners existed.
"""

from __future__ import annotations

import importlib.util
import uuid
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import update

from app.models import Device, Group

_MIGRATION = Path(__file__).parents[1] / "alembic" / "versions" / "0005_group_owner.py"


def _assign_owners_sql():
    spec = importlib.util.spec_from_file_location("m0005", _MIGRATION)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module._ASSIGN_OWNERS


def _device(group: Group, label: str, month: int, revoked: bool = False) -> Device:
    return Device(
        group_id=group.id,
        token_hash=f"hash-{uuid.uuid4()}",
        label=label,
        joined_at=datetime(2026, month, 1, tzinfo=UTC),
        revoked_at=datetime(2026, 9, 1, tzinfo=UTC) if revoked else None,
    )


async def test_existing_groups_get_the_earliest_live_device_as_owner(session):
    kept, creator_left, empty = Group(name="kept"), Group(name="left"), Group(name="empty")
    session.add_all([kept, creator_left, empty])
    await session.flush()
    first, second = _device(kept, "first", 1), _device(kept, "second", 2)
    gone, heir = _device(creator_left, "gone", 1, revoked=True), _device(creator_left, "heir", 3)
    session.add_all([second, first, heir, gone, _device(empty, "only", 1, revoked=True)])
    await session.flush()
    # As before the revision: nobody owns anything.
    await session.execute(update(Group).values(owner_device_id=None))
    await session.commit()

    await session.execute(_assign_owners_sql())
    await session.commit()

    for group in (kept, creator_left, empty):
        await session.refresh(group)
    assert kept.owner_device_id == first.id
    assert creator_left.owner_device_id == heir.id
    assert empty.owner_device_id is None
