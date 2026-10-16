# ClubHelenaCusworth

## Descripción General

App para Android programada en Dart usando Flutter para la consulta y reserva de canchas deportivas, sustentada por un backend al cual el cliente de Flutter le habla, realizado en Python (FastAPI) y desplegado en Render.

## Funcionalidades

- Registro de cuenta e inicio de sesión, autenticado por Firebase.
- Inicio de sesión usando Google.
- Recuperación de contraseña a través de un código de 6 dígitos enviado por mail.
- Consulta y edición de perfil.
- Consulta de sedes.
- Consulta, filtro por tipo de deporte (fútbol 5 y 11, tenis, golf, hockey) y reserva de canchas.
- Cancelación de reservas.
- Notificaciones push de reservas próximas.
- Manejo de errores en caso de falta de conexión, sesión caducada, servidor caído, login erróneo o usuario ya registrado.

## Stack Completo

- Dart
- Flutter
- Python, FastAPI
- Swagger (documentación de la API)
- Firebase Auth, FCM (Firebase Cloud Messaging)
- PostgreSQL
- Render (despliegue)

## Requisitos Previos

- SDK de Flutter (3.47 en adelante).
- Android Studio con un emulador de Android con una imagen del sistema Google Play (para permitir el funcionamiento de las notificaciones push e inicio de sesión con Google).
- JDK (Java Development Kit) 17.

## Ejecución

Con el emulador abierto:

```bash
flutter pub get
flutter run
```

La primera solicitud puede tardar ~1 minuto, debido a que el servicio gratuito de Render se suspende al detectar inactividad por parte del cliente.

## Configuración (opcional)

- `--dart-define=API_BASE_URL=http://10.0.2.2:8000` usa un backend local desde el emulador en lugar de Render.
- `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>` usa otro Web client ID de Firebase.
- El inicio de sesión con Google requiere registrar en Firebase el SHA-1 de la clave que firma la app (`cd android && ./gradlew signingReport`) y volver a descargar `android/app/google-services.json`.

## Tests y Builds

- `flutter test` corre [test/models_and_validators_test.dart](test/models_and_validators_test.dart).
- `flutter build apk --release` genera build/app/outputs/flutter-apk/app-release.apk (la carpeta build/ no se encuentra comiteada).
- `dart run flutter_launcher_icons` regenera el ícono desde [assets/app_icon.png](assets/app_icon.png).

## App

- Responsabilidad de cada módulo en [el README.md de lib/](lib/README.md).

## Backend

- Más detalles en [el README.md del backend](backend/README.md).
- [Documentación de la API de producción](https://sports-club-0e2j.onrender.com/docs).
