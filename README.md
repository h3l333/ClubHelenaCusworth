# ClubHelenaCusworth

Flutter app (Firebase Auth) + FastAPI backend (PostgreSQL) for sports court bookings.

The backend is deployed on Render at https://sports-club-0e2j.onrender.com and the app uses it by default, so running the app does not require a local backend.

## Backend (`backend/`)

Requires Python and a running PostgreSQL instance that `DATABASE_URL` points to.

```bash
cd backend
python -m venv .venv && .venv/Scripts/activate   # PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
cp .env.example .env            # set DATABASE_URL and FIREBASE_SERVICE_ACCOUNT_JSON
                                # and SMTP_* / MAIL_FROM (password reset codes)
alembic upgrade head            # creates tables and seeds sedes/canchas
uvicorn app.main:app --reload
```

The API runs on http://localhost:8000. If `.venv` and `.env` already exist, skip those steps and only activate the venv, install, migrate and run.

Schema changes: edit `app/models.py`, add a new file in `alembic/versions/`, commit both.

## Deployment (Render)

`render.yaml` defines the web service (`sports-club-api`, root directory `backend`) and a free PostgreSQL database (`sports-club-db`).

- Start command: `alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT`. Migrations run on every deploy, so a new database gets its tables and seeded sedes/canchas automatically. If the service was created manually instead of from the Blueprint, set this start command in the dashboard.
- Environment variables (set in the dashboard):
  - `DATABASE_URL`- the database's Internal Database URL (linked automatically when created from the Blueprint).
  - `FIREBASE_SERVICE_ACCOUNT_JSON`- the full service account JSON (same value as the local `.env`).
  - `SMTP_*` and `MAIL_FROM`- for password reset emails.
- Health check: `GET /health` (does not touch the database or Firebase).
- Free plan notes: the service sleeps when idle and the first request can take about a minute; the free database expires after 30 days and must be recreated (re-link `DATABASE_URL` and redeploy).

Troubleshooting (the app shows "El servidor no esta disponible" for any 5xx):

- `503 Authentication is not configured`- `FIREBASE_SERVICE_ACCOUNT_JSON` is missing.
- `connection to server at "127.0.0.1", port 5433 failed` in the logs- `DATABASE_URL` is missing, so the local default is used.
- `relation "users" does not exist`- migrations did not run; check the start command.

## App

```bash
flutter run
```

Google sign-in uses the Firebase project's Web client ID, set as the default of `GOOGLE_SERVER_CLIENT_ID` in `lib/login/google_auth.dart`. To use a different one, add `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com`.

The app uses the Render backend by default. To use a local backend from the Android emulator, add `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.

Google sign-in on Android also needs the debug/release SHA-1 registered in the Firebase console, then re-download `android/app/google-services.json`.

Court/sede photos go in `assets/images/{futbol,tenis,hockey}/` (missing images show a placeholder).
