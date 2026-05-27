"""initial schema

Creates the full server-side schema: groups, devices, players, game_types, games,
game_players, rounds, scores, comments, change_log, rate_limits.

Revision ID: 0001_initial
Revises:
Create Date: 2026-05-27

"""
from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001_initial"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "groups",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("share_token", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("comment_style", sa.String(16), nullable=False, server_default="narrative"),
        sa.Column("comment_language", sa.String(8), nullable=False, server_default="fr"),
        sa.Column("monthly_budget_cents", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("current_month_used_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("budget_resets_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_groups_share_token", "groups", ["share_token"], unique=True)

    op.create_table(
        "devices",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("token_hash", sa.String(255), nullable=False),
        sa.Column("label", sa.String(64), nullable=False),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_devices_token_hash", "devices", ["token_hash"], unique=True)
    op.create_index("ix_devices_group_id", "devices", ["group_id"])

    op.create_table(
        "players",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(32), nullable=False),
        sa.Column("name_normalized", sa.String(32), nullable=False),
        sa.Column("color_value", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("length(name) BETWEEN 1 AND 32", name="ck_player_name_length"),
    )
    op.create_index("ix_players_group_id", "players", ["group_id"])
    op.create_index(
        "uq_players_group_name", "players", ["group_id", "name_normalized"], unique=True
    )

    op.create_table(
        "game_types",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("icon_code_point", sa.Integer(), nullable=False),
        sa.Column("card_color_value", sa.Integer(), nullable=False),
        sa.Column("is_lowest_score_wins", sa.Boolean(), nullable=False),
        sa.Column("is_default", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("player_dead_condition_type", sa.String(16), nullable=True),
        sa.Column("player_dead_threshold", sa.Integer(), nullable=True),
        sa.Column("game_over_condition_type", sa.String(32), nullable=True),
        sa.Column("game_over_threshold", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("group_id", "name", name="uq_game_types_group_name"),
    )
    op.create_index("ix_game_types_group_id", "game_types", ["group_id"])

    op.create_table(
        "games",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column(
            "game_type_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("game_types.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("is_lowest_score_wins", sa.Boolean(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_games_group_id", "games", ["group_id"])

    op.create_table(
        "game_players",
        sa.Column(
            "game_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("games.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "player_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("players.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("color_value", sa.Integer(), nullable=True),
    )

    op.create_table(
        "rounds",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "game_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("games.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("round_number", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("game_id", "round_number", name="uq_rounds_game_number"),
    )
    op.create_index("ix_rounds_game_id", "rounds", ["game_id"])

    op.create_table(
        "scores",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "player_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("players.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "round_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("rounds.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("value", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("player_id", "round_id", name="uq_scores_player_round"),
    )
    op.create_index("ix_scores_round_id", "scores", ["round_id"])

    op.create_table(
        "comments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "game_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("games.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "created_by_device_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("devices.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("style", sa.String(16), nullable=False),
        sa.Column("language", sa.String(8), nullable=False),
        sa.Column("scores_hash", sa.String(64), nullable=False),
        sa.Column("prompt_hash", sa.String(64), nullable=False),
        sa.Column("model", sa.String(64), nullable=False),
        sa.Column("tokens_in", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("tokens_out", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("cost_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_comments_group_created", "comments", ["group_id", "created_at"])
    op.create_index("ix_comments_game_id", "comments", ["game_id"])

    op.create_table(
        "change_log",
        sa.Column("id", sa.BigInteger(), primary_key=True, autoincrement=True),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "origin_device_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("devices.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("entity_type", sa.String(32), nullable=False),
        sa.Column("entity_uuid", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("op", sa.String(8), nullable=False),
        sa.Column("payload", postgresql.JSONB(), nullable=False),
        sa.Column("client_lamport", sa.BigInteger(), nullable=False),
        sa.Column("server_seq", sa.BigInteger(), nullable=False),
        sa.Column("applied_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_change_log_group_seq", "change_log", ["group_id", "server_seq"])
    op.create_index(
        "ix_change_log_dedup",
        "change_log",
        ["origin_device_id", "client_lamport"],
        unique=True,
    )
    op.create_index(
        "ix_change_log_entity",
        "change_log",
        ["entity_type", "entity_uuid", "client_lamport"],
    )
    op.create_index("ix_change_log_server_seq", "change_log", ["server_seq"])

    op.create_table(
        "rate_limits",
        sa.Column(
            "device_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("devices.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("minute_window_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("minute_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("hour_window_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("hour_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("day_window_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("day_count", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_table("rate_limits")
    op.drop_index("ix_change_log_server_seq", table_name="change_log")
    op.drop_index("ix_change_log_entity", table_name="change_log")
    op.drop_index("ix_change_log_dedup", table_name="change_log")
    op.drop_index("ix_change_log_group_seq", table_name="change_log")
    op.drop_table("change_log")
    op.drop_index("ix_comments_game_id", table_name="comments")
    op.drop_index("ix_comments_group_created", table_name="comments")
    op.drop_table("comments")
    op.drop_index("ix_scores_round_id", table_name="scores")
    op.drop_table("scores")
    op.drop_index("ix_rounds_game_id", table_name="rounds")
    op.drop_table("rounds")
    op.drop_table("game_players")
    op.drop_index("ix_games_group_id", table_name="games")
    op.drop_table("games")
    op.drop_index("ix_game_types_group_id", table_name="game_types")
    op.drop_table("game_types")
    op.drop_index("uq_players_group_name", table_name="players")
    op.drop_index("ix_players_group_id", table_name="players")
    op.drop_table("players")
    op.drop_index("ix_devices_group_id", table_name="devices")
    op.drop_index("ix_devices_token_hash", table_name="devices")
    op.drop_table("devices")
    op.drop_index("ix_groups_share_token", table_name="groups")
    op.drop_table("groups")
