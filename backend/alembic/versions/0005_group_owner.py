"""groups.owner_device_id

A group gets an owner: the device that created it, the only one allowed to revoke a
sibling device, rotate the share token, or hand the role to another member. Until this
revision every device in a group was equal, so any member could shut out any other.

Existing groups get the earliest-joined device that is still live (ties broken by id,
the order ``GET /groups/me/devices`` lists them in). The creator was the first device
of every group, so this is the creator wherever it has not left. A group with no live
device keeps ``NULL``: nobody can call on its behalf anyway.

Additive: the column is nullable, and no foreign key is declared — ``devices.group_id``
already points the other way, and a device row is only ever deleted with its group.

Revision ID: 0005_group_owner
Revises: 0004_game_type_builtin_key
Create Date: 2026-09-18

"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0005_group_owner"
down_revision: str | Sequence[str] | None = "0004_game_type_builtin_key"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_ASSIGN_OWNERS = sa.text(
    """
    UPDATE groups SET owner_device_id = (
        SELECT d.id FROM devices d
        WHERE d.group_id = groups.id AND d.revoked_at IS NULL
        ORDER BY d.joined_at, d.id
        LIMIT 1
    )
    """
)


def upgrade() -> None:
    op.add_column(
        "groups",
        sa.Column("owner_device_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.execute(_ASSIGN_OWNERS)


def downgrade() -> None:
    op.drop_column("groups", "owner_device_id")
