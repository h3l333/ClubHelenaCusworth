from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routers import password_reset, reservas, sedes, users

app = FastAPI(title="Sports Club API")

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


@app.get("/health")
def health():
    return {"status": "ok"}
