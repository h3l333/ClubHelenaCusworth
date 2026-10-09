"""reserva notified_at

Revision ID: 0005
Revises: 0004
Create Date: 2026-10-09
"""
from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("reservas", sa.Column("notified_at", sa.DateTime(timezone=True)))


def downgrade() -> None:
    op.drop_column("reservas", "notified_at")
