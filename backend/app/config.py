from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://postgres:postgres@localhost:5433/sports_club"
    firebase_service_account_json: str = ""
    club_timezone: str = "America/Argentina/Buenos_Aires"
    max_booking_days_ahead: int = 60
    brevo_api_key: str = ""
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
