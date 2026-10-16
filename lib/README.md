# lib/

Código de la app Flutter. Volver al [README.md principal](../README.md).

## Raíz

| Archivo | Responsabilidad |
| --- | --- |
| [main.dart](main.dart) | Punto de entrada: inicializa Firebase y define `AuthGate` (elige pantalla según la sesión de Firebase) y `ProfileGate` (carga el perfil del backend antes de mostrar la app). |
| [firebase_options.dart](firebase_options.dart) | Configuración de Firebase generada por FlutterFire CLI. No editar a mano. |
| [login_screen.dart](login_screen.dart) | Pantalla de autenticación: alterna entre las vistas de `login/` según el `AuthStage` actual. |
| [complete_profile_screen.dart](complete_profile_screen.dart) | Pide los datos faltantes cuando el usuario existe en Firebase pero no tiene perfil en el backend (ej. primer inicio con Google). |
| [home_screen.dart](home_screen.dart) | Pantalla de inicio: encabezado, próxima reserva, filtros, carrusel de sedes y menú de perfil. |
| [sedes_screen.dart](sedes_screen.dart) | Pestaña "Sedes": listado de sedes del club. |
| [sede_screen.dart](sede_screen.dart) | Detalle de una sede con sus canchas para reservar. |
| [canchas_screen.dart](canchas_screen.dart) | Pestaña "Canchas": todas las canchas con su sede, filtrables por tipo. |
| [booking_sheet.dart](booking_sheet.dart) | Hoja inferior para reservar una cancha: elige día (próximos 14) y horario disponible. |
| [reservas_screen.dart](reservas_screen.dart) | Historial de reservas del usuario, con filtro por estado y cancelación. |
| [perfil_edit.dart](perfil_edit.dart) | Edición del perfil del usuario y eliminación de la cuenta. |
| [profile_widgets.dart](profile_widgets.dart) | Botones de notificaciones y avatar compartidos entre las pantallas principales. |
| [sede.dart](sede.dart) | Modelos `Sede` y `Cancha`, construidos desde el JSON del backend. |
| [reserva.dart](reserva.dart) | Modelo `Reserva` y su enum `EstadoReserva`. |
| [user_profile.dart](user_profile.dart) | Modelo `UserProfile` (perfil guardado en Postgres). |
| [date_utils.dart](date_utils.dart) | Parseo, formato y validación de fechas y DNI; iniciales de un nombre. |

## login/

Piezas de la pantalla de autenticación.

| Archivo | Responsabilidad |
| --- | --- |
| [auth_stage.dart](login/auth_stage.dart) | Enum con las vistas posibles: bienvenida, login, registro, olvido de contraseña y código de reseteo. |
| [auth_actions.dart](login/auth_actions.dart) | Lógica sin UI: login y registro con email, reseteo de contraseña y traducción de errores de Firebase. |
| [google_auth.dart](login/google_auth.dart) | `GoogleAuthService`: flujo de Google Sign-In + Firebase. |
| [welcome_view.dart](login/welcome_view.dart) | Vista de bienvenida con las opciones de ingreso. |
| [login_form.dart](login/login_form.dart) | Formulario de inicio de sesión. |
| [register_form.dart](login/register_form.dart) | Formulario de registro. |
| [forgot_password_form.dart](login/forgot_password_form.dart) | Pide el email para enviar el código de reseteo. |
| [reset_code_form.dart](login/reset_code_form.dart) | Ingreso del código y la nueva contraseña. |

## services/

| Archivo | Responsabilidad |
| --- | --- |
| [api_client.dart](services/api_client.dart) | Cliente HTTP del backend (usuarios, sedes, canchas, disponibilidad, reservas, tokens de dispositivo) y mensajes de error para el usuario. |
| [profile_store.dart](services/profile_store.dart) | `ChangeNotifier` con el perfil del usuario actual y su estado de carga. |
| [push_service.dart](services/push_service.dart) | Notificaciones push con Firebase Cloud Messaging: registra y elimina el token del dispositivo. |

## widgets/

| Archivo | Responsabilidad |
| --- | --- |
| [common.dart](widgets/common.dart) | Widgets genéricos: imagen con fallback, error con reintento, carga, estilo de botón, encabezado/errores/botón/enlace de los formularios de autenticación y `showSnack`. |
| [form_fields.dart](widgets/form_fields.dart) | Validadores (requerido, email, contraseña), decoración de inputs y `LabeledField`. |
| [cancha_card.dart](widgets/cancha_card.dart) | Tarjeta de cancha con imagen, características, precio y botón de reserva. |

## theme/

| Archivo | Responsabilidad |
| --- | --- |
| [app_colors.dart](theme/app_colors.dart) | Paleta de colores de la app. |
