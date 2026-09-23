from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..deps import get_db, get_firebase_claims
from ..models import User
from ..schemas import UserCreate, UserOut, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])


def _find(db: Session, uid: str) -> User | None:
    return db.scalar(select(User).where(User.firebase_uid == uid))


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    body: UserCreate,
    claims: dict = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
):
    if _find(db, claims["uid"]):
        raise HTTPException(status.HTTP_409_CONFLICT, "User already exists")
    user = User(
        firebase_uid=claims["uid"],
        email=claims.get("email", ""),
        **body.model_dump(),
    )
    db.add(user)
    db.commit()
    return user


@router.get("/me", response_model=UserOut)
def read_me(
    claims: dict = Depends(get_firebase_claims), db: Session = Depends(get_db)
):
    user = _find(db, claims["uid"])
    if user is None:
        # Authenticated in Firebase but no profile yet (e.g. first Google sign-in).
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found")
    return user


@router.patch("/me", response_model=UserOut)
def update_me(
    body: UserUpdate,
    claims: dict = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
):
    user = _find(db, claims["uid"])
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profile not found")
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    db.commit()
    return user
