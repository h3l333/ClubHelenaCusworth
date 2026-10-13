from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from ..config import settings
from ..deps import get_db, get_firebase_claims
from ..models import Cancha, Reserva, Sede
from ..schemas import CanchaConSedeOut, DisponibilidadOut, SedeDetail, SedeOut, SlotOut

router = APIRouter(tags=["sedes"], dependencies=[Depends(get_firebase_claims)])


def club_now() -> datetime:
    return datetime.now(ZoneInfo(settings.club_timezone)).replace(tzinfo=None)


def sede_slots(sede: Sede) -> list[time]:
    return [time(h) for h in range(sede.hora_apertura.hour, sede.hora_cierre.hour)]


@router.get("/sedes", response_model=list[SedeOut])
def list_sedes(db: Session = Depends(get_db)):
    return db.scalars(
        select(Sede).options(selectinload(Sede.canchas)).order_by(Sede.id)
    ).all()


@router.get("/sedes/{sede_id}", response_model=SedeDetail)
def get_sede(sede_id: int, db: Session = Depends(get_db)):
    sede = db.scalar(
        select(Sede).options(selectinload(Sede.canchas)).where(Sede.id == sede_id)
    )
    if sede is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sede no encontrada")
    return sede


@router.get("/canchas", response_model=list[CanchaConSedeOut])
def list_canchas(sport: str | None = None, db: Session = Depends(get_db)):
    """Lista todas las canchas con su sede; `sport` filtra por tipo (ej: Futbol)."""
    query = (
        select(Cancha)
        .options(joinedload(Cancha.sede).selectinload(Sede.canchas))
        .order_by(Cancha.sport, Cancha.name)
    )
    if sport:
        query = query.where(Cancha.sport == sport)
    return db.scalars(query).all()


@router.get("/canchas/{cancha_id}/disponibilidad", response_model=DisponibilidadOut)
def disponibilidad(cancha_id: int, fecha: date, db: Session = Depends(get_db)):
    cancha = db.get(Cancha, cancha_id)
    if cancha is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cancha no encontrada")
    reservas = db.execute(
        select(Reserva.hora_inicio, Reserva.hora_fin).where(
            Reserva.cancha_id == cancha_id,
            Reserva.fecha == fecha,
            Reserva.estado == "confirmada",
        )
    )
    # Cada reserva ocupa todos los turnos de una hora entre inicio y fin.
    taken = {
        time(h) for inicio, fin in reservas for h in range(inicio.hour, fin.hour)
    }
    now = club_now()
    slots = [
        SlotOut(
            hora=slot,
            disponible=slot not in taken and datetime.combine(fecha, slot) > now,
        )
        for slot in sede_slots(cancha.sede)
    ]
    return DisponibilidadOut(fecha=fecha, slots=slots)
