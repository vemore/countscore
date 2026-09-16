"""game_types.builtin_key

The stable identity of a built-in game type, and the key its displayed name is read
from on the client. A built-in type's ``name`` is localized, so two devices in
different locales hold different names for the same type; matching on the name alone
made the group see two. The partial unique index keeps one live row per
``(group_id, builtin_key)`` and leaves ``uq_game_types_group_name`` untouched — a
user's own type still has no key and is still unique by name.

Additive: the column is nullable, and every row that exists before this revision keeps
``builtin_key IS NULL``, which the index ignores. Clients back-fill their own rows
locally (mobile schema v13); the server never guesses a key from a name.

Revision ID: 0004_game_type_builtin_key
Revises: 0003_game_type_rules
Create Date: 2026-09-16

"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0004_game_type_builtin_key"
down_revision: str | Sequence[str] | None = "0003_game_type_rules"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_LIVE_BUILTIN = sa.text("deleted_at IS NULL AND (builtin_key IS NOT NULL)")


def upgrade() -> None:
    op.add_column("game_types", sa.Column("builtin_key", sa.String(32), nullable=True))
    op.create_index(
        "uq_game_types_group_builtin_key",
        "game_types",
        ["group_id", "builtin_key"],
        unique=True,
        postgresql_where=_LIVE_BUILTIN,
        sqlite_where=_LIVE_BUILTIN,
    )


def downgrade() -> None:
    op.drop_index("uq_game_types_group_builtin_key", table_name="game_types")
    op.drop_column("game_types", "builtin_key")
