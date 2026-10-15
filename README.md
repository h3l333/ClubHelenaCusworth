# ClubHelenaCusworth

## Descripción General

App para Android programada en Dart usando Flutter para la consulta y reserva de canchas deportivas, sustentada por un backend al cual el cliente de Flutter le habla, realizado en Python (FastAPI) y desplegado en Render.

## Funcionalidades

- Registro de cuenta e inicio de sesión, autenticado por Firebase.
- Cambio de contraseña a través de un código de 6 dígitos envíado por mail.
- Consulta y edición de perfil.
- Consulta de sedes.
- Consulta, filtro por tipo de deporte (fútbol 5 y 11, tenis, golf, hockey) y reserva de canchas.
- Cancelación de reservas.
- Notificaciones push de reservas próximas.
- Manejo de errores en caso de falta de conexión, sesión caducada, server caído, login erróneo o usuario ya registrado.

## Stack Completo

- Dart
- Flutter
- Firebase Auth, FCM (Firebase Cloud Messaging)
- PostgreSQL
- Render (despliegue)

## Requisitos Previos

- SDK de Flutter (3.47 en adelante).
- Android Studio con un emulador de Android con una imagen del sistema Google Play (para permitir el funcionamiento de las notificaciones push e inicio de sesión con Google).
- JDK (Java Development Kit) 17.

## Run

Con el emulador abierto:

```
flutter pub get
flutter run
```

La primera solicitud puede tardar ~1 minuto, debido a que el servicio gratuito de Render se suspende al detectar inactividad por parte del cliente.

## Tests y Builds

- `flutter tests` corre [tests/models_and_validators_test.dart](test/models_and_validators_test.dart)
- `flutter build apk --release` genera build/app/outputs/flutter-apk/app-release.apk (la carpeta build/ no se encuentra comiteada)
- `dart run flutter_launcher_icons` regenera el ícono desde [assets/app_icon.png](assets/app_icon.png)

## Backend

- Más detalles en [el README.md del backend](backend\README.md).
- [Documentación de la API de producción](https://sports-club-0e2j.onrender.com/docs).
