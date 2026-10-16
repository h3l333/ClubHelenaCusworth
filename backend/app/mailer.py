import json
import urllib.request

from .config import settings

# Brevo's HTTP API (port 443): Render's free plan blocks outbound SMTP ports.
BREVO_URL = "https://api.brevo.com/v3/smtp/email"


def send_reset_code(to: str, code: str) -> None:
    if not settings.brevo_api_key or not settings.mail_from:
        raise RuntimeError("BREVO_API_KEY o MAIL_FROM no configurados")
    body = {
        "sender": {"email": settings.mail_from},
        "to": [{"email": to}],
        "subject": "Codigo para recuperar tu contrasena",
        "textContent": (
            f"Tu codigo es {code}. Vence en {settings.reset_code_ttl_minutes} minutos.\n"
            "Si no lo solicitaste, ignora este correo."
        ),
    }
    req = urllib.request.Request(
        BREVO_URL,
        data=json.dumps(body).encode(),
        headers={
            "api-key": settings.brevo_api_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15):
        pass
