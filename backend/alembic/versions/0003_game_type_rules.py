"""game_types.rules and game_types.rules_slug

Per-game-type rules: what the group wrote (``rules``, free Markdown) and which
ruleset the app ships for it (``rules_slug``). Both nullable and additive, so
an older client that never sends them keeps working unchanged.

Revision ID: 0003_game_type_rules
Revises: 0002_sync_contract
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0003_game_type_rules"
down_revision: str | Sequence[str] | None = "0002_sync_contract"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("game_types", sa.Column("rules", sa.Text(), nullable=True))
    op.add_column("game_types", sa.Column("rules_slug", sa.String(length=32), nullable=True))


def downgrade() -> None:
    op.drop_column("game_types", "rules_slug")
    op.drop_column("game_types", "rules")
