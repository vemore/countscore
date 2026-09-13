"""sync contract for the Flutter client

- colour columns widened to BIGINT: an opaque ARGB value (>= 0xFF000000) overflows int4;
- rounds.comment, and the game_analyses table, so neither is lost on a round trip;
- unique rules on rounds, scores, players and game_types apply to live rows only;
- groups.last_server_seq, read under a row lock, and change_log (group_id, server_seq)
  made unique, so two concurrent pushes cannot mint the same sequence number;
- device tokens now name their device (``<id hex>.<secret>``): devices issued an opaque
  token can never authenticate again, so they are marked revoked.

Revision ID: 0002_sync_contract
Revises: 0001_initial
Create Date: 2026-09-13

"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0002_sync_contract"
down_revision: str | Sequence[str] | None = "0001_initial"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_LIVE = sa.text("deleted_at IS NULL")
_COLOURS = (
    ("players", "color_value", True),
    ("game_players", "color_value", True),
    ("game_types", "card_color_value", False),
)


def upgrade() -> None:
    for table, column, nullable in _COLOURS:
        op.alter_column(
            table,
            column,
            type_=sa.BigInteger(),
            existing_type=sa.Integer(),
            existing_nullable=nullable,
        )

    op.add_column("rounds", sa.Column("comment", sa.Text(), nullable=True))

    op.create_table(
        "game_analyses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "game_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("games.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("model_id", sa.String(128), nullable=True),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "uq_game_analyses_game",
        "game_analyses",
        ["game_id"],
        unique=True,
        postgresql_where=_LIVE,
    )

    op.drop_constraint("uq_rounds_game_number", "rounds", type_="unique")
    op.create_index(
        "uq_rounds_game_number",
        "rounds",
        ["game_id", "round_number"],
        unique=True,
        postgresql_where=_LIVE,
    )
    op.drop_constraint("uq_scores_player_round", "scores", type_="unique")
    op.create_index(
        "uq_scores_player_round",
        "scores",
        ["player_id", "round_id"],
        unique=True,
        postgresql_where=_LIVE,
    )
    op.drop_constraint("uq_game_types_group_name", "game_types", type_="unique")
    op.create_index(
        "uq_game_types_group_name",
        "game_types",
        ["group_id", "name"],
        unique=True,
        postgresql_where=_LIVE,
    )
    op.drop_index("uq_players_group_name", table_name="players")
    op.create_index(
        "uq_players_group_name",
        "players",
        ["group_id", "name_normalized"],
        unique=True,
        postgresql_where=_LIVE,
    )

    op.add_column(
        "groups",
        sa.Column("last_server_seq", sa.BigInteger(), nullable=False, server_default="0"),
    )
    op.execute(
        "UPDATE groups SET last_server_seq = COALESCE("
        "(SELECT MAX(server_seq) FROM change_log WHERE change_log.group_id = groups.id), 0)"
    )
    # A sequence number minted twice by the old max+1 race would make the unique index
    # below fail with a bare driver error; say what is wrong instead.
    duplicates = (
        op.get_bind()
        .execute(
            sa.text(
                "SELECT COUNT(*) FROM (SELECT 1 FROM change_log "
                "GROUP BY group_id, server_seq HAVING COUNT(*) > 1) AS d"
            )
        )
        .scalar()
    )
    if duplicates:
        raise RuntimeError(
            f"change_log holds {duplicates} duplicated (group_id, server_seq) pairs; "
            "renumber them before applying 0002_sync_contract"
        )
    op.drop_index("ix_change_log_group_seq", table_name="change_log")
    op.create_index(
        "ix_change_log_group_seq", "change_log", ["group_id", "server_seq"], unique=True
    )

    op.execute("UPDATE devices SET revoked_at = now() WHERE revoked_at IS NULL")


def downgrade() -> None:
    op.drop_index("ix_change_log_group_seq", table_name="change_log")
    op.create_index("ix_change_log_group_seq", "change_log", ["group_id", "server_seq"])
    op.drop_column("groups", "last_server_seq")

    op.drop_index("uq_players_group_name", table_name="players")
    op.create_index(
        "uq_players_group_name", "players", ["group_id", "name_normalized"], unique=True
    )
    op.drop_index("uq_game_types_group_name", table_name="game_types")
    op.create_unique_constraint("uq_game_types_group_name", "game_types", ["group_id", "name"])
    op.drop_index("uq_scores_player_round", table_name="scores")
    op.create_unique_constraint("uq_scores_player_round", "scores", ["player_id", "round_id"])
    op.drop_index("uq_rounds_game_number", table_name="rounds")
    op.create_unique_constraint("uq_rounds_game_number", "rounds", ["game_id", "round_number"])

    op.drop_index("uq_game_analyses_game", table_name="game_analyses")
    op.drop_table("game_analyses")
    op.drop_column("rounds", "comment")

    for table, column, nullable in _COLOURS:
        op.alter_column(
            table,
            column,
            type_=sa.Integer(),
            existing_type=sa.BigInteger(),
            existing_nullable=nullable,
        )
    # Revoked devices stay revoked: their opaque tokens are not coming back.
