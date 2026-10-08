import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Response, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from .. import firebase, mailer
from ..config import settings
from ..deps import get_db
from ..models import PasswordResetCode
from ..schemas import PasswordResetConfirm, PasswordResetRequest

router = APIRouter(prefix="/auth/password-reset", tags=["auth"])

_INVALID = "Codigo invalido o vencido."


def _hash(email: str, code: str) -> str:
    return hashlib.sha256(f"{email}:{code}".encode()).hexdigest()


def _latest(db: Session, email: str) -> PasswordResetCode | None:
    return db.scalars(
        select(PasswordResetCode)
        .where(PasswordResetCode.email == email, PasswordResetCode.used_at.is_(None))
        .order_by(PasswordResetCode.id.desc())
    ).first()


@router.post("/request", status_code=status.HTTP_204_NO_CONTENT)
def request_code(
    body: PasswordResetRequest,
    background: BackgroundTasks,
    db: Session = Depends(get_db),
):
    email = body.email.strip().lower()
    now = datetime.now(timezone.utc)
    try:
        uid = firebase.get_uid_by_email(email)
    except firebase.FirebaseNotConfigured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Auth no configurado")
    # Misma respuesta exista o no la cuenta, para no revelar correos registrados.
    if uid is None:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    last = _latest(db, email)
    if last and (now - last.created_at).total_seconds() < settings.reset_resend_cooldown_seconds:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    code = f"{secrets.randbelow(1_000_000):06d}"
    db.execute(delete(PasswordResetCode).where(PasswordResetCode.email == email))
    db.add(
        PasswordResetCode(
            email=email,
            code_hash=_hash(email, code),
            expires_at=now + timedelta(minutes=settings.reset_code_ttl_minutes),
        )
    )
    db.commit()
    background.add_task(mailer.send_reset_code, email, code)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/confirm", status_code=status.HTTP_204_NO_CONTENT)
def confirm_code(body: PasswordResetConfirm, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    row = _latest(db, email)
    now = datetime.now(timezone.utc)
    if row is None or row.expires_at < now or row.attempts >= settings.reset_max_attempts:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, _INVALID)

    row.attempts += 1
    db.commit()
    if not hmac.compare_digest(row.code_hash, _hash(email, body.code)):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, _INVALID)

    try:
        uid = firebase.get_uid_by_email(email)
        if uid is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, _INVALID)
        firebase.set_password(uid, body.new_password)
    except firebase.FirebaseNotConfigured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Auth no configurado")

    row.used_at = now
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
