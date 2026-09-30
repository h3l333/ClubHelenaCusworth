"""sedes, canchas, reservas; users.updated_at and unique dni

Revision ID: 0002
Revises: 0001
Create Date: 2026-09-24
"""
from alembic import op
import sqlalchemy as sa

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None

SEDES = [
    (1, "Sede Norte", "Norte", "Av. Libertador 1200"),
    (2, "Sede Centro", "Centro", "Calle San Martín 450"),
    (3, "Sede Sur", "Sur", "Ruta 8 km 24"),
    (4, "Sede Este", "Este", "Av. Mitre 780"),
]

# (sede_id, name, sport, subtype, price, features)
CANCHAS = [
    (1, "Cancha 1", "Futbol", "Futbol 5", 8000, ["Outdoor", "Iluminada"]),
    (1, "Cancha 2", "Futbol", "Futbol 11", 15000, ["Outdoor"]),
    (1, "Cancha 3", "Tenis", None, 5000, ["Iluminada"]),
    (2, "Cancha 1", "Futbol", "Futbol 5", 8000, ["Outdoor", "Iluminada"]),
    (2, "Cancha 2", "Golf", None, 12000, ["Outdoor"]),
    (3, "Cancha 1", "Tenis", None, 5000, ["Iluminada"]),
    (3, "Cancha 2", "Hockey", None, 9000, ["Outdoor", "Iluminada"]),
    (3, "Cancha 3", "Golf", None, 12000, ["Outdoor"]),
    (4, "Cancha 1", "Futbol", "Futbol 5", 8000, ["Outdoor"]),
]


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_unique_constraint("uq_users_dni", "users", ["dni"])

    sedes = op.create_table(
        "sedes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False, unique=True),
        sa.Column("localidad", sa.String(100), nullable=False),
        sa.Column("address", sa.String(200), nullable=False),
        sa.Column("header_image", sa.String(300)),
    )
    canchas = op.create_table(
        "canchas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "sede_id",
            sa.Integer(),
            sa.ForeignKey("sedes.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("sport", sa.String(50), nullable=False),
        sa.Column("subtype", sa.String(50)),
        sa.Column("price", sa.Numeric(10, 2), nullable=False),
        sa.Column("features", sa.JSON(), nullable=False),
        sa.Column("image", sa.String(300)),
    )
    op.create_index("ix_canchas_sede_id", "canchas", ["sede_id"])
    op.create_table(
        "reservas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "cancha_id", sa.Integer(), sa.ForeignKey("canchas.id"), nullable=False
        ),
        sa.Column("fecha", sa.Date(), nullable=False),
        sa.Column("hora", sa.Time(), nullable=False),
        sa.Column("price", sa.Numeric(10, 2), nullable=False),
        sa.Column("estado", sa.String(20), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_reservas_user_id", "reservas", ["user_id"])
    op.create_index("ix_reservas_cancha_id", "reservas", ["cancha_id"])
    op.create_index(
        "uq_reservas_slot_confirmada",
        "reservas",
        ["cancha_id", "fecha", "hora"],
        unique=True,
        postgresql_where=sa.text("estado = 'confirmada'"),
    )

    op.bulk_insert(
        sedes,
        [
            {"id": i, "name": n, "localidad": loc, "address": addr}
            for i, n, loc, addr in SEDES
        ],
    )
    op.bulk_insert(
        canchas,
        [
            {
                "sede_id": sede_id,
                "name": name,
                "sport": sport,
                "subtype": subtype,
                "price": price,
                "features": features,
            }
            for sede_id, name, sport, subtype, price, features in CANCHAS
        ],
    )
    # Los ids de sedes se insertaron a mano: se avanza la secuencia para futuros INSERT.
    if op.get_context().dialect.name == "postgresql":
        op.execute(
            "SELECT setval(pg_get_serial_sequence('sedes', 'id'), (SELECT MAX(id) FROM sedes))"
        )


def downgrade() -> None:
    op.drop_index("uq_reservas_slot_confirmada", table_name="reservas")
    op.drop_index("ix_reservas_cancha_id", table_name="reservas")
    op.drop_index("ix_reservas_user_id", table_name="reservas")
    op.drop_table("reservas")
    op.drop_index("ix_canchas_sede_id", table_name="canchas")
    op.drop_table("canchas")
    op.drop_table("sedes")
    op.drop_constraint("uq_users_dni", "users", type_="unique")
    op.drop_column("users", "updated_at")
