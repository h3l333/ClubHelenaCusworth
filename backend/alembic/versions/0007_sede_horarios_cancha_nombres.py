"""horario de funcionamiento por sede y formato de nombre de cancha

Revision ID: 0007
Revises: 0006
Create Date: 2026-10-12
"""
import re
import unicodedata
from collections import Counter

from alembic import op
import sqlalchemy as sa

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None

# sede_id -> (apertura, cierre)
HORARIOS = {
    1: ("08:00", "23:00"),
    2: ("07:00", "22:00"),
    3: ("09:00", "21:00"),
    4: ("10:00", "23:00"),
}
# Palabras de la direccion que no forman parte del nombre de la calle.
IGNORADAS = {"av", "avenida", "calle", "km"}
CANCHA_NAME_PATTERN = r"^[A-Za-z]+_[A-Za-z0-9]+_[0-9]+_[A-Za-z]+_[0-9]+$"


def _words(text: str) -> list[str]:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.findall(r"[A-Za-z0-9]+", ascii_text)


def _camel(words: list[str]) -> str:
    return "".join(w[:1].upper() + w[1:] for w in words)


def _cancha_name(localidad: str, address: str, sport: str, numero: int) -> str:
    """'Norte', 'Av. Libertador 1200', 'Futbol', 1 -> 'Norte_Libertador_1200_Futbol_1'."""
    words = [w for w in _words(address) if w.lower() not in IGNORADAS]
    altura = words.pop()
    return f"{_camel(_words(localidad))}_{_camel(words)}_{altura}_{_camel(_words(sport))}_{numero}"


def upgrade() -> None:
    conn = op.get_bind()

    op.add_column("sedes", sa.Column("hora_apertura", sa.Time()))
    op.add_column("sedes", sa.Column("hora_cierre", sa.Time()))
    for sede_id, (apertura, cierre) in HORARIOS.items():
        conn.execute(
            sa.text(
                "UPDATE sedes SET hora_apertura = :a, hora_cierre = :c WHERE id = :id"
            ),
            {"a": apertura, "c": cierre, "id": sede_id},
        )
    # Sedes creadas fuera del seed toman el horario global que habia antes.
    conn.execute(
        sa.text(
            "UPDATE sedes SET hora_apertura = '08:00', hora_cierre = '23:00'"
            " WHERE hora_apertura IS NULL"
        )
    )
    op.alter_column("sedes", "hora_apertura", nullable=False)
    op.alter_column("sedes", "hora_cierre", nullable=False)
    op.create_check_constraint(
        "ck_sedes_horario",
        "sedes",
        "hora_cierre > hora_apertura"
        " AND EXTRACT(MINUTE FROM hora_apertura) = 0"
        " AND EXTRACT(SECOND FROM hora_apertura) = 0"
        " AND EXTRACT(MINUTE FROM hora_cierre) = 0"
        " AND EXTRACT(SECOND FROM hora_cierre) = 0",
    )

    # Numeracion por sede y deporte en orden de id.
    rows = conn.execute(
        sa.text(
            "SELECT c.id, c.sport, s.id, s.localidad, s.address"
            " FROM canchas c JOIN sedes s ON s.id = c.sede_id ORDER BY c.id"
        )
    ).all()
    contador: Counter[tuple[int, str]] = Counter()
    for cancha_id, sport, sede_id, localidad, address in rows:
        contador[(sede_id, sport)] += 1
        conn.execute(
            sa.text("UPDATE canchas SET name = :n WHERE id = :id"),
            {
                "n": _cancha_name(localidad, address, sport, contador[(sede_id, sport)]),
                "id": cancha_id,
            },
        )
    op.create_unique_constraint("uq_canchas_name", "canchas", ["name"])
    op.create_check_constraint(
        "ck_canchas_name_formato", "canchas", f"name ~ '{CANCHA_NAME_PATTERN}'"
    )


def downgrade() -> None:
    conn = op.get_bind()
    op.drop_constraint("ck_canchas_name_formato", "canchas", type_="check")
    op.drop_constraint("uq_canchas_name", "canchas", type_="unique")
    rows = conn.execute(sa.text("SELECT id, sede_id FROM canchas ORDER BY id")).all()
    contador: Counter[int] = Counter()
    for cancha_id, sede_id in rows:
        contador[sede_id] += 1
        conn.execute(
            sa.text("UPDATE canchas SET name = :n WHERE id = :id"),
            {"n": f"Cancha {contador[sede_id]}", "id": cancha_id},
        )
    op.drop_constraint("ck_sedes_horario", "sedes", type_="check")
    op.drop_column("sedes", "hora_cierre")
    op.drop_column("sedes", "hora_apertura")
