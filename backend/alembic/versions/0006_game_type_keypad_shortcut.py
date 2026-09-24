"""game_types.keypad_shortcut

The score keypad's per-type key, a value or an operation on the score typed (mobile
schema v21): the client's compact JSON, such as ``{"kind": "multiply", "amount": 2}``,
with an optional ``"label"``. NULL is a plain 0. ``app/services/delta_bounds.py``
refuses a malformed value at the push, so what a device pulls is always well formed.

Additive: the column is nullable, and every existing row keeps ``NULL``. Clients fill
their own built-in rows locally (``applyV21``) and push them like any other edit; the
server never guesses a shortcut from a key or a name.

Revision ID: 0006_game_type_keypad_shortcut
Revises: 0005_group_owner
Create Date: 2026-09-24

"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0006_game_type_keypad_shortcut"
down_revision: str | Sequence[str] | None = "0005_group_owner"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("game_types", sa.Column("keypad_shortcut", sa.String(128), nullable=True))


def downgrade() -> None:
    op.drop_column("game_types", "keypad_shortcut")
