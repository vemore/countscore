"""The SQLModel column types match the DDL Alembic creates.

The full comparison is `alembic check` on a migrated Postgres, a CI step of the backend
job. These tests pin the four columns that once drifted, so the fast suite fails first and
names the column, and they prove the SQLite fallback the in-memory test engine relies on.
"""

from __future__ import annotations

import pytest
from sqlalchemy import Column
from sqlalchemy.dialects import postgresql, sqlite

from app.models.change_log import ChangeLog
from app.models.comment import Comment


def _ddl_type(column: Column, dialect) -> str:
    return column.type.compile(dialect=dialect)


@pytest.mark.parametrize(
    ("column", "expected"),
    [
        (ChangeLog.__table__.c.id, "BIGINT"),
        (ChangeLog.__table__.c.client_lamport, "BIGINT"),
        (ChangeLog.__table__.c.server_seq, "BIGINT"),
        (Comment.__table__.c.content, "TEXT"),
    ],
    ids=lambda v: v.key if isinstance(v, Column) else v,
)
def test_postgres_type_matches_0001_initial(column, expected):
    assert _ddl_type(column, postgresql.dialect()) == expected


def test_change_log_id_autoincrements_on_sqlite():
    # Only an `INTEGER PRIMARY KEY` is a rowid alias on SQLite; a BIGINT one never
    # receives a value, and every change_log insert in the test suite would fail.
    assert _ddl_type(ChangeLog.__table__.c.id, sqlite.dialect()) == "INTEGER"


def test_server_seq_keeps_its_index():
    names = {ix.name for ix in ChangeLog.__table__.indexes}
    assert "ix_change_log_server_seq" in names
