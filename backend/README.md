# backend/

API REST en FastAPI con PostgreSQL, desplegada en Render. Volver al [README.md principal](../README.md).

- Producción: https://sports-club-0e2j.onrender.com
- Documentación Swagger/OpenAPI: [/docs](https://sports-club-0e2j.onrender.com/docs)

## Requisitos Previos

- Python 3.13.
- PostgreSQL accesible desde `DATABASE_URL` (por defecto `localhost:5433`, base `sports_club`).
- Proyecto de Firebase con una cuenta de servicio (Configuración del proyecto -> Cuentas de servicio -> Generar nueva clave privada).
- Cuenta de Brevo (ver [Envío de emails](#envío-de-emails)).

## Ejecución Local

Desde `backend/`:

```bash
python -m venv .venv
.venv/Scripts/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

- En PowerShell, activar el entorno con `.venv\Scripts\Activate.ps1`.
- Completar `.env` antes de migrar (ver [Variables de entorno](#variables-de-entorno)).
- `alembic upgrade head` crea las tablas y carga las sedes y canchas iniciales.
- La API queda en http://localhost:8000 y Swagger en http://localhost:8000/docs.
- Para usarla desde el emulador, correr la app con `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.

Cambios de esquema: editar `app/models.py` y agregar una migración en `alembic/versions/`.

## Estructura

| Archivo                                | Responsabilidad                                                                                       |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| [app/main.py](app/main.py)             | Crea la app, registra los routers y los manejadores de errores, e inicia el notificador.              |
| [app/routers/](app/routers/)           | Endpoints de usuarios, sedes y canchas, reservas, tokens de dispositivo y recuperación de contraseña. |
| [app/models.py](app/models.py)         | Tablas de SQLAlchemy.                                                                                 |
| [app/schemas.py](app/schemas.py)       | Validación de solicitudes y respuestas con Pydantic.                                                  |
| [app/deps.py](app/deps.py)             | Dependencias: sesión de base de datos y usuario autenticado por token de Firebase.                    |
| [app/firebase.py](app/firebase.py)     | Firebase Admin: verificación de tokens, contraseñas y push (FCM).                                     |
| [app/notifier.py](app/notifier.py)     | Bucle que envía recordatorios de reservas que comienzan dentro de la próxima hora.                    |
| [app/mailer.py](app/mailer.py)         | Envío del código de recuperación por Brevo.                                                           |
| [alembic/versions/](alembic/versions/) | Migraciones y datos iniciales.                                                                        |

## Variables de Entorno

Definidas en [.env.example](.env.example). En local se leen de `backend/.env`; en Render, de la pestaña Environment del servicio.

| Variable                        | Descripción                                                             |
| ------------------------------- | ----------------------------------------------------------------------- |
| `DATABASE_URL`                  | Conexión a PostgreSQL. En Render, la Internal Database URL de la base.  |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON de la cuenta de servicio de Firebase, en una sola línea.           |
| `BREVO_API_KEY`                 | API key de Brevo para enviar los códigos de recuperación de contraseña. |
| `MAIL_FROM`                     | Remitente de esos emails. Debe estar verificado en Brevo.               |

## Envío de Emails

Los códigos de recuperación se envían con la API HTTP de Brevo y no por SMTP, ya que el plan gratuito de Render bloquea los puertos SMTP salientes (25, 465 y 587) pero no bloquea solicitudes salientes al puerto 443 (HTTPS).

1. Crear una cuenta en [Brevo](https://www.brevo.com) y verificar el remitente en Senders, Domains & Dedicated IPs -> Senders.
2. Generar una API key en SMTP & API -> API Keys.
3. Cargar `BREVO_API_KEY` y `MAIL_FROM` en Render (o en `backend/.env`).

El email se envía en segundo plano, después de que el endpoint responde `204`. Si falla, el error aparece solo en los logs.

## Despliegue en Render

1. Crear una base PostgreSQL (plan Free).
2. Crear un Web Service desde este repositorio con:
   - Root Directory: `backend`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - Health Check Path: `/health`
3. Cargar las [variables de entorno](#variables-de-entorno) y `PYTHON_VERSION=3.13.5`.

Las migraciones corren en cada inicio, así que una base nueva recibe las tablas y los datos iniciales sola.

[render.yaml](../render.yaml) define lo mismo como Blueprint (New -> Blueprint). El servicio actual se configuró manualmente desde el dashboard, por lo que los cambios en el archivo no se aplican solos: hay que replicarlos en la pestaña Environment.

Plan gratuito: el servicio se suspende tras un período de inactividad (la primera solicitud tarda ~1 minuto) y la base gratuita vence a los 30 días, tras lo cual hay que recrearla y actualizar `DATABASE_URL`.

## Resolución de Problemas

La app muestra "El servidor no está disponible" ante cualquier error 5xx; la causa está en los logs de Render.

| Error en los logs                                              | Causa                                                           |
| -------------------------------------------------------------- | --------------------------------------------------------------- |
| `503 Authentication is not configured` o `Auth no configurado` | Falta `FIREBASE_SERVICE_ACCOUNT_JSON`.                          |
| `connection to server at "127.0.0.1", port 5433 failed`        | Falta `DATABASE_URL` y se usa el valor local por defecto.       |
| `relation "users" does not exist`                              | No corrieron las migraciones: revisar el Start Command.         |
| `BREVO_API_KEY o MAIL_FROM no configurados`                    | Faltan esas variables.                                          |
| `HTTP Error 401` en `mailer.py`                                | API key de Brevo inválida.                                      |
| `HTTP Error 400` en `mailer.py`                                | `MAIL_FROM` no está verificado como emisor de correos en Brevo. |
