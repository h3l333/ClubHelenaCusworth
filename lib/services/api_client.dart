import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// URL base del backend. Se sobreescribe con --dart-define=API_BASE_URL=... (ej. http://10.0.2.2:8000 en el emulador de Android).
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  // Adjunta el ID token de Firebase del usuario actual; el backend lo verifica con firebase-admin.
  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final detail = body is Map ? body['detail'] : null;
    throw ApiException(res.statusCode, detail?.toString() ?? 'Error del servidor (${res.statusCode}).');
  }

  Future<Map<String, dynamic>> createUser({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String dni,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: await _headers(),
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate.toIso8601String().substring(0, 10),
        'dni': dni,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(Uri.parse('$_baseUrl/users/me'), headers: await _headers());
    return _decode(res);
  }
}
