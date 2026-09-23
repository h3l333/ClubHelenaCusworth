from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://postgres:postgres@localhost:5432/sports_club"
    firebase_service_account_json: str = ""
    cors_origins: str = ""

    @property
    def sqlalchemy_url(self) -> str:
        # Render provides postgres:// or postgresql://; SQLAlchemy needs the psycopg driver name.
        url = self.database_url
        for prefix in ("postgres://", "postgresql://"):
            if url.startswith(prefix):
                return "postgresql+psycopg://" + url[len(prefix):]
        return url


settings = Settings()
