from datetime import date

from pydantic import BaseModel, ConfigDict


class UserCreate(BaseModel):
    first_name: str
    last_name: str
    birth_date: date
    dni: str


class UserUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    birth_date: date | None = None
    dni: str | None = None


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    email: str
    first_name: str | None
    last_name: str | None
    birth_date: date | None
    dni: str | None
