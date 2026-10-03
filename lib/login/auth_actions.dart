import 'package:firebase_auth/firebase_auth.dart';

import '../date_utils.dart';
import '../services/api_client.dart';
import '../services/profile_store.dart';

/// Inicia sesion con email/password. Retorna un mensaje de error o null si salio bien.
Future<String?> signInWithEmail({
  required String email,
  required String password,
}) {
  return _guard(
    () => FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    ),
  );
}

/// Crea la cuenta de Firebase y el perfil en el backend. Retorna un mensaje de error o null.
Future<String?> registerWithEmail({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String birthDateText,
  required String dni,
}) {
  return _guard(() async {
    final birthDate = parseBirthDate(birthDateText);
    final store = ProfileStore.instance;
    // Firebase emite el usuario antes de que exista el perfil: AuthGate espera a que termine.
    store.beginRegistration();
    User? user;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      user = credential.user;
      // Guarda el perfil en Postgres via el backend.
      final profile = await ApiClient.instance.createUser(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        dni: dni,
      );
      store.setProfile(profile);
    } catch (_) {
      store.cancelRegistration();
      // Sin perfil en la base, se elimina la cuenta de Firebase para permitir reintentar el registro.
      try {
        await user?.delete();
      } catch (_) {}
      rethrow;
    }
  });
}

Future<String?> _guard(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on ApiException catch (e) {
    return e.message;
  } on FormatException {
    return 'Fecha de nacimiento invalida (use DD/MM/AAAA).';
  } on FirebaseAuthException catch (e) {
    return e.message ?? 'Error al autenticar. Vuelva a intentar por favor.';
  }
}
