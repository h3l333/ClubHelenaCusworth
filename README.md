# ClubHelenaCusworth

Flutter app (Firebase Auth) + FastAPI backend (PostgreSQL) for sports court bookings.

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

Deploy: `render.yaml` (Render web service + free Postgres). Set `FIREBASE_SERVICE_ACCOUNT_JSON`, `SMTP_*` and `MAIL_FROM` in the Render dashboard.

## App

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

`GOOGLE_SERVER_CLIENT_ID` is required so the backend can verify the Google ID token.

The app uses the Render backend (`https://sports-club-0e2j.onrender.com`) by default. To use a local backend from the Android emulator, add `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.

Google sign-in on Android also needs the debug/release SHA-1 registered in the Firebase console, then re-download `android/app/google-services.json`.

Court/sede photos go in `assets/images/{futbol,tenis,hockey}/` (missing images show a placeholder).
