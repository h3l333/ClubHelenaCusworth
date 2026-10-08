# sports_club

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
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
            --dart-define=GOOGLE_CLIENT_ID=<web-client-id>.apps.googleusercontent.com \
            --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

`GOOGLE_CLIENT_ID` is required for Google sign-in on web (`google_sign_in_web`). `GOOGLE_SERVER_CLIENT_ID` is required on all platforms so the backend can verify the ID token.

### Web

1. Start the backend on port 8000 and set `CORS_ORIGINS=http://localhost:5000` in `backend/.env`.
2. Add `http://localhost:5000` to the OAuth web client's authorized JavaScript origins (Google Cloud console -> APIs & Services -> Credentials).
3. Run the app on a fixed port:

```bash
flutter run -d chrome --web-port 5000 \
            --dart-define=API_BASE_URL=http://localhost:8000 \
            --dart-define=GOOGLE_CLIENT_ID=<web-client-id>.apps.googleusercontent.com \
            --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

The default `API_BASE_URL` (`10.0.2.2`) only works from the Android emulator.

Google sign-in on Android also needs the debug/release SHA-1 registered in the Firebase console, then re-download `android/app/google-services.json`.

Court/sede photos go in `assets/images/{futbol,tenis,hockey}/` (missing images show a placeholder).
