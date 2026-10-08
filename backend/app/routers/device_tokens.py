from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..deps import get_current_user, get_db
from ..models import DeviceToken, User
from ..schemas import DeviceTokenIn

router = APIRouter(prefix="/device-tokens", tags=["push"])


@router.post("", status_code=status.HTTP_204_NO_CONTENT)
def register(
    body: DeviceTokenIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    existing = db.scalar(select(DeviceToken).where(DeviceToken.token == body.token))
    if existing is None:
        db.add(DeviceToken(user_id=user.id, token=body.token))
    elif existing.user_id != user.id:
        existing.user_id = user.id  # device switched accounts
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def unregister(
    body: DeviceTokenIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.execute(
        delete(DeviceToken).where(
            DeviceToken.token == body.token, DeviceToken.user_id == user.id
        )
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
