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
    return _translateAuthError(e);
  }
}

String _translateAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'El correo ingresado no es valido.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espere un momento antes de volver a intentar.';
    case 'network-request-failed':
      return 'Sin conexion a internet. Verifique su red e intente de nuevo.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contrasena incorrectos.';
    case 'email-already-in-use':
      return 'Ya existe una cuenta con ese correo.';
    case 'weak-password':
      return 'La contrasena es demasiado debil.';
    default:
      return e.message ?? 'Error al autenticar. Vuelva a intentar por favor.';
  }
}

// Retorna null si sale bien.
Future<String?> requestResetCode({required String email}) {
  return _guard(() => ApiClient.instance.requestPasswordReset(email.trim()));
}

// Retorna null si sale bien.
Future<String?> confirmResetCode({
  required String email,
  required String code,
  required String newPassword,
}) {
  return _guard(
    () => ApiClient.instance.confirmPasswordReset(
      email: email.trim(),
      code: code.trim(),
      newPassword: newPassword,
    ),
  );
}
