import json
import threading

import firebase_admin
from firebase_admin import auth, credentials, messaging

from .config import settings

_app: firebase_admin.App | None = None
_lock = threading.Lock()


class FirebaseNotConfigured(RuntimeError):
    pass


def _get_app() -> firebase_admin.App:
    global _app
    if _app is None:
        with _lock:
            if _app is None:
                if not settings.firebase_service_account_json:
                    raise FirebaseNotConfigured("FIREBASE_SERVICE_ACCOUNT_JSON is not set")
                cred = credentials.Certificate(
                    json.loads(settings.firebase_service_account_json)
                )
                _app = firebase_admin.initialize_app(cred)
    return _app


def verify_id_token(token: str) -> dict:
    """Return decoded Firebase claims (uid, email, ...) or raise on an invalid token."""
    return auth.verify_id_token(token, app=_get_app())


def delete_user(uid: str) -> None:
    try:
        auth.delete_user(uid, app=_get_app())
    except auth.UserNotFoundError:
        pass


def get_uid_by_email(email: str) -> str | None:
    try:
        return auth.get_user_by_email(email, app=_get_app()).uid
    except auth.UserNotFoundError:
        return None


def set_password(uid: str, new_password: str) -> None:
    auth.update_user(uid, password=new_password, app=_get_app())
    auth.revoke_refresh_tokens(uid, app=_get_app())


def send_push(tokens: list[str], title: str, body: str) -> None:
    msg = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
    )
    messaging.send_each_for_multicast(msg, app=_get_app())
