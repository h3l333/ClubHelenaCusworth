# backend/

API REST en FastAPI. Volver al [README.md principal](../README.md).

## Variables de entorno

Definidas en [.env.example](.env.example). En local se leen de `backend/.env`; en Render, de la pestaña Environment del servicio.

| Variable | Descripción |
| --- | --- |
| `DATABASE_URL` | Conexión a PostgreSQL. En Render la provee la base de datos. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON de la cuenta de servicio de Firebase, en una sola línea. |
| `BREVO_API_KEY` | API key de Brevo para enviar los códigos de recuperación de contraseña. |
| `MAIL_FROM` | Remitente de esos emails. Debe estar verificado en Brevo. |

## Envío de emails

Los códigos de recuperación se envían con la API HTTP de Brevo y no por SMTP, ya que el plan gratuito de Render bloquea los puertos SMTP salientes (25, 465 y 587).

1. Crear una cuenta en [Brevo](https://www.brevo.com) y verificar el remitente en Senders, Domains & Dedicated IPs -> Senders.
2. Generar una API key en SMTP & API -> API Keys.
3. Cargar `BREVO_API_KEY` y `MAIL_FROM` en Render (o en `backend/.env`).

El email se envía en segundo plano, después de que el endpoint responde `204`. Si falla, el error aparece solo en los logs de Render.

## render.yaml

[render.yaml](../render.yaml) define el despliegue como Blueprint. El servicio actual se configuró manualmente desde el dashboard, por lo que los cambios en el archivo no se aplican solos: hay que replicarlos en la pestaña Environment.
