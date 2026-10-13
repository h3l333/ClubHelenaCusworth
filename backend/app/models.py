from datetime import date, datetime, time
from decimal import Decimal

from sqlalchemy import (
    JSON,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Time,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base

CANCHA_NAME_PATTERN = r"^[A-Za-z]+_[A-Za-z0-9]+_[0-9]+_[A-Za-z]+_[0-9]+$"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(320))
    first_name: Mapped[str | None] = mapped_column(String(100))
    last_name: Mapped[str | None] = mapped_column(String(100))
    birth_date: Mapped[date | None] = mapped_column(Date)
    dni: Mapped[str | None] = mapped_column(String(20), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Sede(Base):
    __tablename__ = "sedes"
    __table_args__ = (
        # Horario de funcionamiento en horas completas; el cierre es exclusivo (ultimo turno = cierre - 1h).
        CheckConstraint(
            "hora_cierre > hora_apertura"
            " AND EXTRACT(MINUTE FROM hora_apertura) = 0"
            " AND EXTRACT(SECOND FROM hora_apertura) = 0"
            " AND EXTRACT(MINUTE FROM hora_cierre) = 0"
            " AND EXTRACT(SECOND FROM hora_cierre) = 0",
            name="ck_sedes_horario",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    localidad: Mapped[str] = mapped_column(String(100))
    address: Mapped[str] = mapped_column(String(200))
    header_image: Mapped[str | None] = mapped_column(String(300))
    hora_apertura: Mapped[time] = mapped_column(Time)
    hora_cierre: Mapped[time] = mapped_column(Time)

    canchas: Mapped[list["Cancha"]] = relationship(
        back_populates="sede", order_by="Cancha.id"
    )

    @property
    def sports(self) -> list[str]:
        return list(dict.fromkeys(c.sport for c in self.canchas))


class Cancha(Base):
    __tablename__ = "canchas"
    __table_args__ = (
        # Formato Localidad_Calle_Numero_Tipo_N, ej: Moron_Rivadavia_19850_Paddle_1.
        CheckConstraint(
            f"name ~ '{CANCHA_NAME_PATTERN}'", name="ck_canchas_name_formato"
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    sede_id: Mapped[int] = mapped_column(
        ForeignKey("sedes.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(100), unique=True)
    sport: Mapped[str] = mapped_column(String(50))
    subtype: Mapped[str | None] = mapped_column(String(50))
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    features: Mapped[list[str]] = mapped_column(JSON, default=list)
    image: Mapped[str | None] = mapped_column(String(300))

    sede: Mapped[Sede] = relationship(back_populates="canchas")


class Reserva(Base):
    __tablename__ = "reservas"
    # La superposicion de horarios se valida en create_reserva bloqueando la fila de la cancha.
    __table_args__ = (
        Index(
            "ix_reservas_cancha_fecha_confirmada",
            "cancha_id",
            "fecha",
            postgresql_where=text("estado = 'confirmada'"),
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    cancha_id: Mapped[int] = mapped_column(ForeignKey("canchas.id"), index=True)
    fecha: Mapped[date] = mapped_column(Date)
    hora_inicio: Mapped[time] = mapped_column(Time)
    hora_fin: Mapped[time] = mapped_column(Time)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    estado: Mapped[str] = mapped_column(String(20), default="confirmada")
    notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    cancha: Mapped[Cancha] = relationship()


class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(320), index=True)
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(default=0)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token: Mapped[str] = mapped_column(String(512), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
