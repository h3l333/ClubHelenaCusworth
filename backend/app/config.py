from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://postgres:postgres@localhost:5433/sports_club"
    firebase_service_account_json: str = ""
    cors_origins: str = ""
    club_timezone: str = "America/Argentina/Buenos_Aires"
    # Horario de atencion: turnos de 1 hora desde open_hour hasta close_hour (exclusivo).
    open_hour: int = 8
    close_hour: int = 23
    max_booking_days_ahead: int = 60
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    mail_from: str = ""
    reset_code_ttl_minutes: int = 10
    reset_max_attempts: int = 5
    reset_resend_cooldown_seconds: int = 60

    @property
    def sqlalchemy_url(self) -> str:
        # Render provides postgres:// or postgresql://; SQLAlchemy needs the psycopg driver name.
        url = self.database_url
        for prefix in ("postgres://", "postgresql://"):
            if url.startswith(prefix):
                return "postgresql+psycopg://" + url[len(prefix):]
        return url


settings = Settings()
