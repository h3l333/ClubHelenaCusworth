from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..config import settings
from ..deps import get_current_user, get_db
from ..models import Cancha, Reserva, User
from ..notifier import club_now_naive, is_due, notify_reserva
from ..schemas import ReservaCreate, ReservaOut
from .sedes import club_now

router = APIRouter(prefix="/reservas", tags=["reservas"])


def _out(reserva: Reserva) -> ReservaOut:
    return ReservaOut(
        id=reserva.id,
        cancha_id=reserva.cancha_id,
        cancha=f"{reserva.cancha.display_name} ({reserva.cancha.tipo})",
        sede=reserva.cancha.sede.name,
        fecha=reserva.fecha,
        hora_inicio=reserva.hora_inicio.strftime("%H:%M"),
        hora_fin=reserva.hora_fin.strftime("%H:%M"),
        price=float(reserva.price),
        estado=reserva.estado,
    )


def _load(db: Session, reserva_id: int) -> Reserva | None:
    return db.scalar(
        select(Reserva)
        .options(joinedload(Reserva.cancha).joinedload(Cancha.sede))
        .where(Reserva.id == reserva_id)
    )


@router.get("/me", response_model=list[ReservaOut])
def my_reservas(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(
        select(Reserva)
        .options(joinedload(Reserva.cancha).joinedload(Cancha.sede))
        .where(Reserva.user_id == user.id)
        .order_by(Reserva.fecha, Reserva.hora_inicio)
    ).all()
    return [_out(r) for r in rows]


@router.post("", response_model=ReservaOut, status_code=status.HTTP_201_CREATED)
def create_reserva(
    body: ReservaCreate,
    background: BackgroundTasks,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # FOR UPDATE serializa las reservas concurrentes de la misma cancha hasta el commit.
    cancha = db.scalar(
        select(Cancha).where(Cancha.id == body.cancha_id).with_for_update()
    )
    if cancha is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cancha no encontrada")
    sede = cancha.sede
    if body.hora_inicio < sede.hora_apertura or body.hora_fin > sede.hora_cierre:
        raise HTTPException(
            422,
            f"{sede.name} funciona de {sede.hora_apertura:%H:%M} a {sede.hora_cierre:%H:%M}",
        )
    now = club_now()
    if datetime.combine(body.fecha, body.hora_inicio) <= now:
        raise HTTPException(422, "El horario ya paso")
    if body.fecha > now.date() + timedelta(days=settings.max_booking_days_ahead):
        raise HTTPException(
            422,
            f"Solo se puede reservar hasta {settings.max_booking_days_ahead} dias adelante",
        )

    overlap = db.scalar(
        select(Reserva.id).where(
            Reserva.cancha_id == cancha.id,
            Reserva.fecha == body.fecha,
            Reserva.estado == "confirmada",
            Reserva.hora_inicio < body.hora_fin,
            Reserva.hora_fin > body.hora_inicio,
        )
    )
    if overlap is not None:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Ese horario ya fue reservado")

    horas = body.hora_fin.hour - body.hora_inicio.hour
    reserva = Reserva(
        user_id=user.id,
        cancha_id=cancha.id,
        fecha=body.fecha,
        hora_inicio=body.hora_inicio,
        hora_fin=body.hora_fin,
        price=cancha.price * horas,
        estado="confirmada",
    )
    db.add(reserva)
    db.commit()
    if is_due(reserva, club_now_naive()):
        background.add_task(notify_reserva, reserva.id)
    return _out(_load(db, reserva.id))


@router.delete("/{reserva_id}", response_model=ReservaOut)
def cancel_reserva(
    reserva_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    reserva = _load(db, reserva_id)
    if reserva is None or reserva.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reserva no encontrada")
    if reserva.estado != "confirmada":
        raise HTTPException(status.HTTP_409_CONFLICT, "La reserva ya no esta activa")
    if datetime.combine(reserva.fecha, reserva.hora_inicio) <= club_now():
        raise HTTPException(
            status.HTTP_409_CONFLICT, "No se puede cancelar una reserva pasada"
        )
    reserva.estado = "cancelada"
    db.commit()
    return _out(reserva)

