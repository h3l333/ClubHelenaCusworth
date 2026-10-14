import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import OperationalError

from .config import settings
from .notifier import run_forever
from .routers import device_tokens, password_reset, reservas, sedes, users

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(run_forever())
    yield
    task.cancel()


app = FastAPI(title="ClubHelenaCusworth API", lifespan=lifespan)

app.include_router(users.router)
app.include_router(sedes.router)
app.include_router(reservas.router)
app.include_router(password_reset.router)
app.include_router(device_tokens.router)


@app.exception_handler(OperationalError)
async def db_unavailable(request: Request, exc: OperationalError):
    logger.exception("Base de datos no disponible")
    return JSONResponse(status_code=503, content={"detail": "La base de datos no esta disponible. Intente mas tarde."})


@app.exception_handler(Exception)
async def unhandled_error(request: Request, exc: Exception):
    logger.exception("Error no controlado en %s", request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Error interno del servidor."})


@app.get("/health")
def health():
    return {"status": "ok"}
