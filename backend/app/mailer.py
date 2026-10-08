import smtplib
from email.message import EmailMessage

from .config import settings


def send_reset_code(to: str, code: str) -> None:
    msg = EmailMessage()
    msg["Subject"] = "Codigo para recuperar tu contrasena"
    msg["From"] = settings.mail_from
    msg["To"] = to
    msg.set_content(
        f"Tu codigo es {code}. Vence en {settings.reset_code_ttl_minutes} minutos.\n"
        "Si no lo solicitaste, ignora este correo."
    )
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as s:
        s.starttls()
        s.login(settings.smtp_user, settings.smtp_password)
        s.send_message(msg)
