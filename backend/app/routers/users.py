from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import firebase
from ..deps import get_current_user, get_db, get_firebase_claims
from ..models import Reserva, User
from ..schemas import UserCreate, UserOut, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])


def _dni_taken(db: Session, dni: str, exclude_id: int | None = None) -> bool:
    query = select(User.id).where(User.dni == dni)
    if exclude_id is not None:
        query = query.where(User.id != exclude_id)
    return db.scalar(query) is not None


def _commit(db: Session) -> None:
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "El usuario o el DNI ya estan registrados")


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    body: UserCreate,
    claims: dict = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
):
    if db.scalar(select(User.id).where(User.firebase_uid == claims["uid"])):
        raise HTTPException(status.HTTP_409_CONFLICT, "El usuario ya existe")
    if _dni_taken(db, body.dni):
        raise HTTPException(status.HTTP_409_CONFLICT, "El DNI ya esta registrado")
    user = User(
        firebase_uid=claims["uid"],
        email=claims.get("email", ""),
        **body.model_dump(),
    )
    db.add(user)
    _commit(db)
    return user


@router.get("/me", response_model=UserOut)
def read_me(user: User = Depends(get_current_user)):
    # 404 means authenticated in Firebase but no profile yet (e.g. first Google sign-in).
    return user


@router.patch("/me", response_model=UserOut)
def update_me(
    body: UserUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    changes = body.model_dump(exclude_unset=True)
    if "dni" in changes and _dni_taken(db, changes["dni"], exclude_id=user.id):
        raise HTTPException(status.HTTP_409_CONFLICT, "El DNI ya esta registrado")
    for key, value in changes.items():
        setattr(user, key, value)
    _commit(db)
    return user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_me(
    claims: dict = Depends(get_firebase_claims), db: Session = Depends(get_db)
):
    """Idempotent: removes the profile and its reservations, then the Firebase account."""
    user = db.scalar(select(User).where(User.firebase_uid == claims["uid"]))
    if user is not None:
        db.execute(delete(Reserva).where(Reserva.user_id == user.id))
        db.delete(user)
        db.commit()
    try:
        firebase.delete_user(claims["uid"])
    except Exception:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY, "No se pudo eliminar la cuenta de autenticacion"
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
