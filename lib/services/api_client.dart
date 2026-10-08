import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../date_utils.dart';
import '../reserva.dart';
import '../sede.dart';
import '../user_profile.dart';

// URL base del backend. Se sobreescribe con --dart-define=API_BASE_URL=... (ej. https://sports-club-api.onrender.com).
// El valor por defecto solo sirve para el emulador de Android contra un backend local.
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

// El plan gratuito de Render "duerme" el servicio y el primer request puede tardar ~1 minuto.
const _timeout = Duration(seconds: 60);

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class Slot {
  const Slot({required this.hora, required this.disponible});
  final String hora; // 'HH:MM'
  final bool disponible;
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
      'DELETE' => http.delete(uri, headers: headers),
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
      throw ApiException(0, 'El servidor tardo demasiado en responder.');
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(res.statusCode, _errorMessage(res.statusCode, body));
  }

  String _errorMessage(int status, dynamic body) {
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
    required String hora,
  }) async {
    final json = await _request(
      'POST',
      '/reservas',
      body: {'cancha_id': canchaId, 'fecha': toIsoDate(fecha), 'hora': hora},
    );
    return Reserva.fromJson(json as Map<String, dynamic>);
  }

  Future<Reserva> cancelReserva(int id) async {
    final json = await _request('DELETE', '/reservas/$id');
    return Reserva.fromJson(json as Map<String, dynamic>);
  }
}
