import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .notifier import run_forever
from .routers import device_tokens, password_reset, reservas, sedes, users



@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(run_forever())
    yield
    task.cancel()


app = FastAPI(title="Sports Club API", lifespan=lifespan)

if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(users.router)
app.include_router(sedes.router)
app.include_router(reservas.router)
app.include_router(password_reset.router)
app.include_router(device_tokens.router)


@app.get("/health")
def health():
    return {"status": "ok"}
