"""Index helpers shared by the models."""

from __future__ import annotations

from sqlalchemy import Index, text


def live_unique(name: str, *columns: str) -> Index:
    """A unique index over live rows only (``deleted_at IS NULL``).

    A tombstone must not hold its round number, score slot or name forever: a device that
    deletes round 5 and enters a new round 5 would otherwise be refused because of a row
    nobody can see.
    """
    where = text("deleted_at IS NULL")
    return Index(name, *columns, unique=True, postgresql_where=where, sqlite_where=where)
