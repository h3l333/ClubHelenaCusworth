from collections.abc import Iterator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import firebase
from .db import SessionLocal
from .models import User

_bearer = HTTPBearer(auto_error=False)


def get_db() -> Iterator[Session]:
    with SessionLocal() as db:
        yield db


def get_firebase_claims(
    creds: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict:
    if creds is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")
    try:
        return firebase.verify_id_token(creds.credentials)
    except firebase.FirebaseNotConfigured:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE, "Authentication is not configured"
        )
    except Exception:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")


def get_current_user(
    claims: dict = Depends(get_firebase_claims), db: Session = Depends(get_db)
) -> User:
    user = db.scalar(select(User).where(User.firebase_uid == claims["uid"]))
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Perfil no encontrado")
    return user
