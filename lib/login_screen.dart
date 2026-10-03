import 'package:flutter/material.dart';

import 'login/auth_actions.dart';
import 'login/auth_stage.dart';
import 'login/google_auth.dart';
import 'login/login_form.dart';
import 'login/register_form.dart';
import 'login/welcome_view.dart';
import 'services/google_signin_button.dart';

// StatefulWidget es una clase que representa una widget dinamica. Difiere de
// StatelessWidget en varios sentidos:
// StatefulWidget se compone de dos clases...
//  - StatefulWidget, clase que sirve de plantilla/configuracion para mi widget
//  - State, clase que alberga el estado, logica y metodo build de la widget, que
//    define como se ve en pantalla
//
// Importante: Cuando Flutter necesita renderizar un widget, llama al metodo build.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Le pasa al contructor de la clase padre
  // un parametro "key"

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// La clase _LoginScreenState (precedida por un guion bajo para indicar que
// no se debe utilizar fuera de la clase y sus subclases)
class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _dniController = TextEditingController();

  AuthStage _stage = AuthStage.welcome; // Controla que pantalla se muestra: bienvenida, login o registro
  bool _isLoading = false; // Flag que indica si una solicitud de autorizacion asincronica esta ejecutandose
  String? _errorMessage; // Guarda texto retornado por Firebase en caso de que la auten. falle
  bool _googleSignInReady = false;

  late final GoogleAuthService _google;

  @override
  void initState() {
    super.initState();
    _google = GoogleAuthService(onBusy: _setBusy, onError: _showError);
    _google
        .init()
        .then((_) {
          if (mounted) setState(() => _googleSignInReady = true);
        })
        .catchError((Object e) {
          debugPrint('Error al inicializar Google Sign-In: $e');
          _showError('No se pudo inicializar Google Sign-In.');
        });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _dniController.dispose();
    _google.dispose();
    super.dispose();
  }

  void _setBusy(bool busy) {
    if (!mounted) return;
    setState(() {
      _isLoading = busy;
      if (busy) _errorMessage = null;
    });
  }

  void _showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  Future<void> _submit() async {
    final isRegistering = _stage == AuthStage.register;
    final formKey = isRegistering ? _registerFormKey : _loginFormKey;
    if (!formKey.currentState!.validate()) return;

    _setBusy(true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final error = isRegistering
        ? await registerWithEmail(
            email: email,
            password: password,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            birthDateText: _birthDateController.text,
            dni: _dniController.text.trim(),
          )
        : await signInWithEmail(email: email, password: password);

    if (error != null) _showError(error);
    _setBusy(false);
  }

  void _goTo(AuthStage stage) {
    setState(() {
      _stage = stage;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: switch (_stage) {
          AuthStage.welcome => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
            child: WelcomeView(onStart: () => _goTo(AuthStage.login)),
          ),
          AuthStage.login => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LoginForm(
                formKey: _loginFormKey,
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onBack: () => _goTo(AuthStage.welcome),
                onSubmit: _submit,
                onGoogleSignIn: _google.signIn,
                googleSignInButton: _googleSignInReady
                    ? buildGoogleSignInButton()
                    : null,
                onGoToRegister: () => _goTo(AuthStage.register),
              ),
            ),
          ),
          AuthStage.register => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: RegisterForm(
                formKey: _registerFormKey,
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                birthDateController: _birthDateController,
                dniController: _dniController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onBack: () => _goTo(AuthStage.login),
                onSubmit: _submit,
                onGoToLogin: () => _goTo(AuthStage.login),
              ),
            ),
          ),
        },
      ),
    );
  }
}
