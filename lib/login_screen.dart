import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'services/api_client.dart';

// En Dart, una clase enum es una clase especial que se usa para
// representar una cantidad fija de valores ctes.
enum _AuthStage { welcome, login, register }

// StatefulWidget es una clase que representa una widget dinamica. Difiere de
// StatelessWidget en varios sentidos:
// StatefulWidget se compone de dos clases...
//  - StatefulWidget, clase que sirve de plantilla/configuracion para mi widget
//  - State, clase que alberga el estado, logica y metodo build de la widget, que
//      define como se ve en pantalla
//
// Importante: Cuando Flutter necesita renderizar un widget, llama al metodo build.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Crea un estado mutable para el widget.
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>(); // Variable que solo se puede setear una vez, privada a este archivo de Dart.
  // GlobalKey identifica unequivocamente a un elemento dentro de toda la app. En este caso, instanciamos la clase indicandole que
  // se vincula al estado del formulario de inicio de sesión.
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  // La clase TextEditingController permite *manejar* input de texto del usuario. Cuando este manipula un campo de texto
  // y lo actualiza, el TextEditingControllre permite notificar a sus listeners.
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _dniController = TextEditingController();

  _AuthStage _stage = _AuthStage.welcome; // Controla que pantalla se muestra: bienvenida, login o registro.
  bool _isLoading = false; // Flag que indica si una solicitud de autorizacion asincronica esta ejecutandose.
  String? _errorMessage; // Guarda texto retornado por Firebase en caso de que la auten. falle.

  final _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  // dispose() se llama sobre un State cuando su elemento asociado es quitado permanentemente del arbol de elementos.
  // Un elemento podría ser quitado del árbol de elementos, por ejemplo:
  //  - Cuando el usuario navega a otra pantalla.
  //  - Cuando su elemento padre lo reemplaza con otro.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isRegistering = _stage == _AuthStage.register;
    final formKey = isRegistering ? _registerFormKey : _loginFormKey;
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (isRegistering) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        try {
          // Guarda el perfil en Postgres via el backend. Espera birthDate como YYYY-MM-DD.
          await ApiClient.instance.createUser(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            birthDate: DateTime.parse(_birthDateController.text.trim()),
            dni: _dniController.text.trim(),
          );
        } catch (e) {
          // Sin perfil en la base, se elimina la cuenta de Firebase para permitir reintentar el registro.
          await credential.user?.delete();
          rethrow;
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } on FormatException {
      setState(() => _errorMessage = 'Fecha de nacimiento invalida (use AAAA-MM-DD).');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ?? 'Error al autenticar. Vuelva a intentar por favor.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false); // "Si este estado aun está en el árbol de estados, indica que no se está cargando."
    }
  }
}
