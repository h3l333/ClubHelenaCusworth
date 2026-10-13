"""reserva hora_inicio y hora_fin

Revision ID: 0006
Revises: 0005
Create Date: 2026-10-12
"""
from alembic import op
import sqlalchemy as sa

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_index("uq_reservas_slot_confirmada", table_name="reservas")
    op.alter_column("reservas", "hora", new_column_name="hora_inicio")
    # Las reservas existentes eran de una hora.
    op.add_column("reservas", sa.Column("hora_fin", sa.Time()))
    op.execute("UPDATE reservas SET hora_fin = hora_inicio + interval '1 hour'")
    op.alter_column("reservas", "hora_fin", nullable=False)
    op.create_index(
        "ix_reservas_cancha_fecha_confirmada",
        "reservas",
        ["cancha_id", "fecha"],
        postgresql_where=sa.text("estado = 'confirmada'"),
    )


def downgrade() -> None:
    op.drop_index("ix_reservas_cancha_fecha_confirmada", table_name="reservas")
    op.drop_column("reservas", "hora_fin")
    op.alter_column("reservas", "hora_inicio", new_column_name="hora")
    op.create_index(
        "uq_reservas_slot_confirmada",
        "reservas",
        ["cancha_id", "fecha", "hora"],
        unique=True,
        postgresql_where=sa.text("estado = 'confirmada'"),
    )
