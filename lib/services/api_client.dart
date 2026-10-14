import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../date_utils.dart';
import '../reserva.dart';
import '../sede.dart';
import '../user_profile.dart';

// URL base del backend. Se sobreescribe con --dart-define=API_BASE_URL=... (ej. http://10.0.2.2:8000 para un backend local).
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://sports-club-0e2j.onrender.com',
);

// El plan gratuito de Render "duerme" el servicio y el primer request puede tardar ~1 minuto.
const _timeout = Duration(seconds: 60);

const _offlineMessage =
    'Sin conexion a internet. Verifique su red e intente de nuevo.';
const _serverDownMessage =
    'El servidor no esta disponible en este momento. Intente mas tarde.';
const _sessionExpiredMessage = 'Su sesion vencio. Vuelva a iniciar sesion.';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isNotFound => statusCode == 404;
  // 0: no hubo respuesta del servidor (sin internet, servidor caido o timeout).
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

/// Mensaje apto para mostrar al usuario a partir de cualquier error.
String describeError(Object error) => switch (error) {
  ApiException(:final message) => message,
  FormatException() => 'Fecha de nacimiento invalida (use DD/MM/AAAA).',
  _ => 'Ocurrio un error inesperado. Intente de nuevo.',
};

class Slot {
  const Slot({required this.hora, required this.disponible});
  final String hora; // 'HH:MM'
  final bool disponible;
}

/// Consulta un host externo para saber si hay internet.
Future<bool> hasInternet() async {
  try {
    await http
        .head(Uri.parse('https://clients3.google.com/generate_204'))
        .timeout(const Duration(seconds: 5));
    return true;
  } catch (_) {
    return false;
  }
}

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  Future<http.Response> _send(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool forceRefresh,
  ) async {
    // El backend verifica este ID token de Firebase con firebase-admin.
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(
      forceRefresh,
    );
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    final future = switch (method) {
      'POST' => http.post(uri, headers: headers, body: encoded),
      'PATCH' => http.patch(uri, headers: headers, body: encoded),
      'DELETE' => http.delete(uri, headers: headers, body: encoded),
      _ => http.get(uri, headers: headers),
    };
    return future.timeout(_timeout);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    try {
      var res = await _send(method, path, body, query, false);
      // Token vencido o revocado: se reintenta una vez con un token nuevo.
      if (res.statusCode == 401) {
        res = await _send(method, path, body, query, true);
      }
      return _decode(res);
    } on TimeoutException {
      throw ApiException(
        0,
        'El servidor tardo demasiado en responder. Puede estar iniciando, intente de nuevo en unos segundos.',
      );
    } on http.ClientException {
      throw ApiException(0, await _connectionMessage());
    } on FirebaseAuthException catch (e) {
      // getIdToken falla si no hay red o si la sesion fue revocada.
      final offline = e.code == 'network-request-failed';
      throw ApiException(
        offline ? 0 : 401,
        offline ? _offlineMessage : _sessionExpiredMessage,
      );
    }
  }

  // Distingue "sin internet" de "servidor caido".
  Future<String> _connectionMessage() async {
    return await hasInternet() ? _serverDownMessage : _offlineMessage;
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      // Render responde con una pagina HTML (502/503) mientras el servicio esta caido o reiniciando.
      throw ApiException(res.statusCode, _serverDownMessage);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(res.statusCode, _errorMessage(res.statusCode, body));
  }

  String _errorMessage(int status, dynamic body) {
    if (status >= 500) return _serverDownMessage;
    if (status == 401) return _sessionExpiredMessage;
    final detail = body is Map ? body['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      // Errores de validacion de FastAPI: [{msg: 'Value error, ...'}, ...]
      return detail
          .map(
            (e) => e is Map
                ? '${e['msg']}'.replaceFirst('Value error, ', '')
                : '$e',
          )
          .join('\n');
    }
    return 'Error del servidor ($status).';
  }

  Future<UserProfile> createUser({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String dni,
  }) async {
    final json = await _request(
      'POST',
      '/users',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': toIsoDate(birthDate),
        'dni': dni,
      },
    );
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<void> registerDeviceToken(String token) =>
      _request('POST', '/device-tokens', body: {'token': token});

  Future<void> deleteDeviceToken(String token) =>
      _request('DELETE', '/device-tokens', body: {'token': token});

  Future<UserProfile> getMe() async {
    final json = await _request('GET', '/users/me');
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<UserProfile> updateMe({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String dni,
  }) async {
    final json = await _request(
      'PATCH',
      '/users/me',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': toIsoDate(birthDate),
        'dni': dni,
      },
    );
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  // Borra el perfil y sus reservas y, del lado del servidor, la cuenta de Firebase.
  Future<void> deleteMe() => _request('DELETE', '/users/me');

  Future<void> requestPasswordReset(String email) => _request(
    'POST',
    '/auth/password-reset/request',
    body: {'email': email},
  );

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) => _request(
    'POST',
    '/auth/password-reset/confirm',
    body: {'email': email, 'code': code, 'new_password': newPassword},
  );

  Future<List<Sede>> getSedes() async {
    final json = await _request('GET', '/sedes') as List;
    return json.map((s) => Sede.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<Sede> getSede(int id) async {
    final json = await _request('GET', '/sedes/$id');
    return Sede.fromJson(json as Map<String, dynamic>);
  }

  Future<List<({Cancha cancha, Sede sede})>> getCanchas() async {
    final json = await _request('GET', '/canchas') as List;
    return [
      for (final c in json.cast<Map<String, dynamic>>())
        (
          cancha: Cancha.fromJson(c),
          sede: Sede.fromJson(c['sede'] as Map<String, dynamic>),
        ),
    ];
  }

  Future<List<Slot>> getDisponibilidad(int canchaId, DateTime fecha) async {
    final json = await _request(
      'GET',
      '/canchas/$canchaId/disponibilidad',
      query: {'fecha': toIsoDate(fecha)},
    ) as Map<String, dynamic>;
    return (json['slots'] as List)
        .map(
          (s) => Slot(
            hora: s['hora'] as String,
            disponible: s['disponible'] as bool,
          ),
        )
        .toList();
  }

  Future<List<Reserva>> getReservas() async {
    final json = await _request('GET', '/reservas/me') as List;
    return json
        .map((r) => Reserva.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Reserva> createReserva({
    required int canchaId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
  }) async {
    final json = await _request(
      'POST',
      '/reservas',
      body: {
        'cancha_id': canchaId,
        'fecha': toIsoDate(fecha),
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
      },
    );
    return Reserva.fromJson(json as Map<String, dynamic>);
  }

  Future<Reserva> cancelReserva(int id) async {
    final json = await _request('DELETE', '/reservas/$id');
    return Reserva.fromJson(json as Map<String, dynamic>);
  }
}
