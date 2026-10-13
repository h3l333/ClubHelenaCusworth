import re
from datetime import date, time
from typing import Annotated

from pydantic import (
    AfterValidator,
    BaseModel,
    ConfigDict,
    Field,
    field_serializer,
    model_validator,
)


def _clean_name(value: str) -> str:
    value = " ".join(value.split())
    if not value:
        raise ValueError("No puede estar vacio")
    return value


def _clean_dni(value: str) -> str:
    digits = re.sub(r"[.\s-]", "", value)
    if not re.fullmatch(r"\d{6,10}", digits):
        raise ValueError("DNI invalido: use entre 6 y 10 digitos")
    return digits


def _check_birth_date(value: date) -> date:
    if value > date.today() or value.year < 1900:
        raise ValueError("Fecha de nacimiento invalida")
    return value


Name = Annotated[str, Field(max_length=100), AfterValidator(_clean_name)]
Dni = Annotated[str, Field(max_length=20), AfterValidator(_clean_dni)]
BirthDate = Annotated[date, AfterValidator(_check_birth_date)]


class UserCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    first_name: Name
    last_name: Name
    birth_date: BirthDate
    dni: Dni


class UserUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    first_name: Name | None = None
    last_name: Name | None = None
    birth_date: BirthDate | None = None
    dni: Dni | None = None

    @model_validator(mode="after")
    def _no_explicit_nulls(self):
        for field in self.model_fields_set:
            if getattr(self, field) is None:
                raise ValueError(f"{field} no puede ser null")
        return self


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    firebase_uid: str
    email: str
    first_name: str | None
    last_name: str | None
    birth_date: date | None
    dni: str | None


class CanchaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    display_name: str
    sport: str
    subtype: str | None
    price: float
    features: list[str]
    image: str | None


class SedeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    localidad: str
    address: str
    header_image: str | None
    hora_apertura: time
    hora_cierre: time
    sports: list[str]

    @field_serializer("hora_apertura", "hora_cierre")
    def _ser_hora(self, value: time) -> str:
        return value.strftime("%H:%M")


class SedeDetail(SedeOut):
    canchas: list[CanchaOut]


class CanchaConSedeOut(CanchaOut):
    sede: SedeOut


class SlotOut(BaseModel):
    hora: time
    disponible: bool

    @field_serializer("hora")
    def _ser_hora(self, value: time) -> str:
        return value.strftime("%H:%M")


class DisponibilidadOut(BaseModel):
    fecha: date
    slots: list[SlotOut]


class ReservaCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    cancha_id: int
    fecha: date
    hora_inicio: time
    hora_fin: time

    @model_validator(mode="after")
    def _horas_completas(self):
        for value in (self.hora_inicio, self.hora_fin):
            if value.minute or value.second or value.microsecond:
                raise ValueError("Los horarios deben ser horas completas (minuto 00)")
        if self.hora_fin <= self.hora_inicio:
            raise ValueError("La hora de fin debe ser posterior a la de inicio")
        return self


class ReservaOut(BaseModel):
    id: int
    cancha_id: int
    cancha: str
    sede: str
    fecha: date
    hora_inicio: str
    hora_fin: str
    price: float
    estado: str


class PasswordResetRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: Annotated[str, Field(max_length=320)]


class PasswordResetConfirm(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: Annotated[str, Field(max_length=320)]
    code: Annotated[str, Field(pattern=r"^\d{6}$")]
    new_password: Annotated[str, Field(min_length=6, max_length=128)]


class DeviceTokenIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    token: Annotated[str, Field(min_length=1, max_length=512)]
