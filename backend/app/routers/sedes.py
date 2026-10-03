from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from ..config import settings
from ..deps import get_db, get_firebase_claims
from ..models import Cancha, Reserva, Sede
from ..schemas import DisponibilidadOut, SedeDetail, SedeOut, SlotOut

router = APIRouter(tags=["sedes"], dependencies=[Depends(get_firebase_claims)])


def club_now() -> datetime:
    return datetime.now(ZoneInfo(settings.club_timezone)).replace(tzinfo=None)


def all_slots() -> list[time]:
    return [time(h) for h in range(settings.open_hour, settings.close_hour)]


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


@router.get("/canchas/{cancha_id}/disponibilidad", response_model=DisponibilidadOut)
def disponibilidad(cancha_id: int, fecha: date, db: Session = Depends(get_db)):
    if db.get(Cancha, cancha_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cancha no encontrada")
    taken = set(
        db.scalars(
            select(Reserva.hora).where(
                Reserva.cancha_id == cancha_id,
                Reserva.fecha == fecha,
                Reserva.estado == "confirmada",
            )
        )
    )
    now = club_now()
    slots = [
        SlotOut(
            hora=slot,
            disponible=slot not in taken and datetime.combine(fecha, slot) > now,
        )
        for slot in all_slots()
    ]
    return DisponibilidadOut(fecha=fecha, slots=slots)
