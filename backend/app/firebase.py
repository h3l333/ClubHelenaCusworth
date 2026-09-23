import json

import firebase_admin
from firebase_admin import auth, credentials

from .config import settings

_app: firebase_admin.App | None = None


def _get_app() -> firebase_admin.App:
    global _app
    if _app is None:
        if not settings.firebase_service_account_json:
            raise RuntimeError("FIREBASE_SERVICE_ACCOUNT_JSON is not set")
        cred = credentials.Certificate(json.loads(settings.firebase_service_account_json))
        _app = firebase_admin.initialize_app(cred)
    return _app


def verify_id_token(token: str) -> dict:
    """Return decoded Firebase claims (uid, email, ...) or raise on an invalid token."""
    return auth.verify_id_token(token, app=_get_app())
