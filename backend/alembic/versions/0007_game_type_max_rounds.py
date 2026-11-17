"""game_types.max_rounds

The number of rounds after which a game of the type is over (mobile schema v22), or
NULL for no limit; the app combines it with the total condition by OR.
``app/services/delta_bounds.py`` refuses a value outside 1..999 at the push.

Additive: the column is nullable, and every existing row keeps ``NULL``. The server
never derives a limit from a key or a name: a client fills its own built-in rows
(Chouineurs, 4) and pushes them like any other edit.

Revision ID: 0007_game_type_max_rounds
Revises: 0006_game_type_keypad_shortcut
Create Date: 2026-11-17

"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0007_game_type_max_rounds"
down_revision: str | Sequence[str] | None = "0006_game_type_keypad_shortcut"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("game_types", sa.Column("max_rounds", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("game_types", "max_rounds")
