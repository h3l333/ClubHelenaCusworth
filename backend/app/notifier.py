import asyncio
import logging
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import select, update

from .config import settings
from .db import SessionLocal
from .firebase import send_push
from .models import DeviceToken, Reserva

log = logging.getLogger(__name__)
INTERVAL_SECONDS = 60
LEAD = timedelta(hours=1)


def club_now_naive() -> datetime:
    return datetime.now(ZoneInfo(settings.club_timezone)).replace(tzinfo=None)


def is_due(r: Reserva, now: datetime) -> bool:
    return now < datetime.combine(r.fecha, r.hora) <= now + LEAD


def notify_reserva(reserva_id: int) -> None:
    """Envia el aviso una sola vez; el UPDATE condicional actua de candado."""
    with SessionLocal() as db:
        claimed = db.execute(
            update(Reserva)
            .where(Reserva.id == reserva_id, Reserva.notified_at.is_(None))
            .values(notified_at=datetime.now(timezone.utc))
        ).rowcount
        db.commit()
        if not claimed:
            return
        r = db.get(Reserva, reserva_id)
        tokens = list(
            db.scalars(select(DeviceToken.token).where(DeviceToken.user_id == r.user_id))
        )
        try:
            if tokens:
                send_push(
                    tokens, "Reserva proxima", f"{r.cancha.name} a las {r.hora:%H:%M}"
                )
        except Exception:
            r.notified_at = None  # liberar para reintentar en el proximo ciclo
            db.commit()
            raise


def notify_upcoming() -> None:
    now = club_now_naive()
    with SessionLocal() as db:
        pending = db.scalars(
            select(Reserva).where(
                Reserva.estado == "confirmada",
                Reserva.notified_at.is_(None),
                Reserva.fecha.between(now.date(), (now + LEAD).date()),
            )
        ).all()
    for r in pending:
        if is_due(r, now):
            notify_reserva(r.id)


async def run_forever() -> None:
    while True:
        try:
            await asyncio.to_thread(notify_upcoming)
        except Exception:
            log.exception("notifier failed")
        await asyncio.sleep(INTERVAL_SECONDS)
