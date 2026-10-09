import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_client.dart';

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static String? _token;
  static StreamSubscription<String>? _refreshSub;

  /// Pide permiso, registra el token en el backend y escucha renovaciones.
  static Future<void> init() async {
    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    _token = token;
    await ApiClient.instance.registerDeviceToken(token);
    _refreshSub ??= _fcm.onTokenRefresh.listen((t) async {
      _token = t;
      await ApiClient.instance.registerDeviceToken(t);
    });
  }

  /// Llamar ANTES de signOut: el DELETE necesita la sesion activa.
  static Future<void> dispose() async {
    final token = _token;
    _token = null;
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (token == null) return;
    try {
      await ApiClient.instance.deleteDeviceToken(token);
    } catch (_) {
      // Sin red o sesion vencida: no bloquear el cierre de sesion.
    }
  }
}
