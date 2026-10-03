import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

// Client ID de tipo "Web" del proyecto de Firebase; se pasa con --dart-define=GOOGLE_SERVER_CLIENT_ID=...
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
// OAuth Client ID de tipo "Web" requerido por google_sign_in_web; se pasa con --dart-define=GOOGLE_CLIENT_ID=...
const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

const _genericError = 'Error al autenticar. Vuelva a intentar por favor.';
const _googleError = 'No se pudo iniciar sesión con Google.';

/// Encapsula el flujo de Google Sign-In + Firebase, sin depender de widgets.
class GoogleAuthService {
  GoogleAuthService({required this.onBusy, required this.onError});

  /// Se invoca con true al iniciar una autenticacion y con false al terminar.
  final void Function(bool busy) onBusy;
  final void Function(String message) onError;

  final _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  // En Web, google_sign_in no soporta authenticate(): el resultado del login
  // llega via este stream, alimentado por el boton propio de Google (renderButton).
  Future<void> init() async {
    if (kIsWeb && _googleClientId.isEmpty) {
      throw StateError('Falta --dart-define=GOOGLE_CLIENT_ID=...');
    }
    await _googleSignIn.initialize(
      clientId: _googleClientId.isEmpty ? null : _googleClientId,
      // google_sign_in_web no permite pasar serverClientId: lo rechaza con un assert.
      serverClientId: kIsWeb || _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    if (kIsWeb) {
      _subscription = _googleSignIn.authenticationEvents.listen(
        _handleEvent,
        onError: _handleError,
      );
    }
  }

  void dispose() => _subscription?.cancel();

  // Solo se usa fuera de Web: alli google_sign_in soporta authenticate() de forma imperativa.
  Future<void> signIn() async {
    if (kIsWeb) return;
    onBusy(true);
    try {
      final account = await _googleSignIn.authenticate();
      await _signInToFirebase(account.authentication.idToken);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code != GoogleSignInExceptionCode.canceled) onError(_googleError);
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? _genericError);
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

  // En Web, este callback recibe el resultado de que el usuario interactue
  // con el boton renderizado por Google (renderButton).
  Future<void> _handleEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    onBusy(true);
    try {
      await _signInToFirebase(event.user.authentication.idToken);
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? _genericError);
    } catch (e) {
      debugPrint('Error inesperado al iniciar sesión con Google: $e');
      onError(_googleError);
    } finally {
      onBusy(false);
    }
  }

  void _handleError(Object error) {
    debugPrint('Google authenticationEvents error: $error');
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return;
    }
    onError(_googleError);
  }
}
