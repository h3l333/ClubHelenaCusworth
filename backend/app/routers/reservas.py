from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from ..config import settings
from ..deps import get_current_user, get_db
from ..models import Cancha, Reserva, User
from ..notifier import club_now_naive, is_due, notify_reserva
from ..schemas import ReservaCreate, ReservaOut
from .sedes import all_slots, club_now

router = APIRouter(prefix="/reservas", tags=["reservas"])


def _out(reserva: Reserva) -> ReservaOut:
    return ReservaOut(
        id=reserva.id,
        cancha_id=reserva.cancha_id,
        cancha=(
            f"{reserva.cancha.name} - "
            f"{reserva.cancha.subtype or reserva.cancha.sport}"
        ),
        sede=reserva.cancha.sede.name,
        fecha=reserva.fecha,
        hora=reserva.hora.strftime("%H:%M"),
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
        .order_by(Reserva.fecha, Reserva.hora)
    ).all()
    return [_out(r) for r in rows]


@router.post("", response_model=ReservaOut, status_code=status.HTTP_201_CREATED)
def create_reserva(
    body: ReservaCreate,
    background: BackgroundTasks,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cancha = db.get(Cancha, body.cancha_id)
    if cancha is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cancha no encontrada")
    if body.hora not in all_slots():
        raise HTTPException(
            422, "Horario fuera del turno del club"
        )
    now = club_now()
    if datetime.combine(body.fecha, body.hora) <= now:
        raise HTTPException(422, "El horario ya paso")
    if body.fecha > now.date() + timedelta(days=settings.max_booking_days_ahead):
        raise HTTPException(
            422,
            f"Solo se puede reservar hasta {settings.max_booking_days_ahead} dias adelante",
        )

    reserva = Reserva(
        user_id=user.id,
        cancha_id=cancha.id,
        fecha=body.fecha,
        hora=body.hora,
        price=cancha.price,
        estado="confirmada",
    )
    db.add(reserva)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Ese horario ya fue reservado")
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
    if datetime.combine(reserva.fecha, reserva.hora) <= club_now():
        raise HTTPException(
            status.HTTP_409_CONFLICT, "No se puede cancelar una reserva pasada"
        )
    reserva.estado = "cancelada"
    db.commit()
    return _out(reserva)

