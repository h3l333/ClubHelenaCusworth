import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_client.dart';
import 'auth_actions.dart';

// Client ID de tipo "Web" del proyecto de Firebase; se puede sobreescribir con --dart-define=GOOGLE_SERVER_CLIENT_ID=...
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '21035806320-noc70m2fd7tllbmpi0cosd498v1fp5ut.apps.googleusercontent.com',
);

const _googleError = 'No se pudo iniciar sesión con Google.';
const _offlineError =
    'Sin conexion a internet. Verifique su red e intente de nuevo.';

/// Encapsula el flujo de Google Sign-In + Firebase, sin depender de widgets.
class GoogleAuthService {
  GoogleAuthService({required this.onBusy, required this.onError});

  /// Se invoca con true al iniciar una autenticacion y con false al terminar.
  final void Function(bool busy) onBusy;
  final void Function(String message) onError;

  final _googleSignIn = GoogleSignIn.instance;

  Future<void> init() => _googleSignIn.initialize(
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );

  Future<void> signIn() async {
    onBusy(true);
    try {
      final account = await _googleSignIn.authenticate();
      await _signInToFirebase(account.authentication.idToken);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code != GoogleSignInExceptionCode.canceled) {
        onError(_googleError);
      } else if (!await hasInternet()) {
        // Sin red, Credential Manager responde "canceled" (ej. [16] Account reauth failed).
        onError(_offlineError);
      }
    } on FirebaseAuthException catch (e) {
      onError(translateAuthError(e));
    } catch (e) {
      debugPrint('Error inesperado al iniciar sesión con Google: $e');
      onError(_googleError);
    } finally {
      onBusy(false);
    }
  }

  Future<void> _signInToFirebase(String? idToken) async {
    if (idToken == null) {
      throw StateError('Google no devolvio un idToken');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
