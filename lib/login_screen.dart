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

  _AuthStage _stage = _AuthStage.welcome; // Controla que pantalla se muestra: bienvenida, login o registro
  bool _isLoading = false; // Flag que indica si una solicitud de autorizacion asincronica esta ejecutandose
  String? _errorMessage; // Guarda texto retornado por Firebase en caso de que la auten. falle

  final _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

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
          // Guarda el perfil en Postgres via el backend.
          await ApiClient.instance.createUser(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            birthDate: _parseBirthDate(_birthDateController.text),
            dni: _dniController.text.trim(),
          );
        } catch (_) {
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
      setState(
        () => _errorMessage = 'Fecha de nacimiento invalida (use DD/MM/AAAA).',
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ?? 'Error al autenticar. Vuelva a intentar por favor.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!_googleSignInInitialized) {
        await _googleSignIn.initialize();
        _googleSignInInitialized = true;
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code != GoogleSignInExceptionCode.canceled) {
        setState(() => _errorMessage = 'No se pudo iniciar sesión con Google.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ?? 'Error al autenticar. Vuelva a intentar por favor.';
      });
    } catch (e) {
      debugPrint('Error inesperado al iniciar sesión con Google: $e');
      setState(() => _errorMessage = 'No se pudo iniciar sesión con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goTo(_AuthStage stage) {
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
          _AuthStage.welcome => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
            child: _WelcomeView(onStart: () => _goTo(_AuthStage.login)),
          ),
          _AuthStage.login => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _LoginForm(
                formKey: _loginFormKey,
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onBack: () => _goTo(_AuthStage.welcome),
                onSubmit: _submit,
                onGoogleSignIn: _signInWithGoogle,
                onGoToRegister: () => _goTo(_AuthStage.register),
              ),
            ),
          ),
          _AuthStage.register => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _RegisterForm(
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
                onBack: () => _goTo(_AuthStage.login),
                onSubmit: _submit,
                onGoToLogin: () => _goTo(_AuthStage.login),
              ),
            ),
          ),
        },
      ),
    );
  }
}

// Convierte DD/MM/AAAA en DateTime; lanza FormatException si el texto o la fecha no son validos.
DateTime _parseBirthDate(String text) {
  final parts = text.trim().split('/');
  if (parts.length != 3) throw const FormatException('Formato invalido');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  final date = DateTime(year, month, day);
  // DateTime normaliza fechas fuera de rango (31/02 -> 03/03), por eso se compara.
  if (date.day != day || date.month != month || date.year != year) {
    throw const FormatException('Fecha fuera de rango');
  }
  return date;
}

InputDecoration _fieldDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.yellow[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.lime[700]!, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.grey[850]),
          cursorColor: Colors.lime[700],
          decoration: _fieldDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final VoidCallback onStart;

  const _WelcomeView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.lime[400],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lime.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'CLUB DEPORTIVO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[850],
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestión de Espacios Deportivos - Zona Oeste',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.lime[400],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: onStart,
            child: const Text('Comenzar'),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGoToRegister;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onBack,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onGoToRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[850]),
              onPressed: isLoading ? null : onBack,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Iniciar sesión',
              style: TextStyle(
                color: Colors.grey[850],
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _LabeledField(
            label: 'Correo electrónico',
            controller: emailController,
            hint: 'ejemplo@correo.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese su correo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Contraseña',
            controller: passwordController,
            hint: 'Mínimo 6 caracteres',
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe contener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.lime[400],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Iniciar sesión'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[400])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continuar con Google'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[850],
                side: BorderSide(color: Colors.grey[700]!, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: isLoading ? null : onGoogleSignIn,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isLoading ? null : onGoToRegister,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                children: [
                  const TextSpan(text: '¿No tenés cuenta? '),
                  TextSpan(
                    text: 'Registrate',
                    style: TextStyle(
                      color: Colors.lime[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController birthDateController;
  final TextEditingController dniController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

  const _RegisterForm({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.birthDateController,
    required this.dniController,
    required this.isLoading,
    required this.errorMessage,
    required this.onBack,
    required this.onSubmit,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[850]),
              onPressed: isLoading ? null : onBack,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Registrarme',
              style: TextStyle(
                color: Colors.grey[850],
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Nombre',
                  controller: firstNameController,
                  hint: 'Juan',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Apellido',
                  controller: lastNameController,
                  hint: 'Pérez',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Correo electrónico',
            controller: emailController,
            hint: 'ejemplo@correo.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese su correo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Contraseña',
            controller: passwordController,
            hint: 'Mínimo 6 caracteres',
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe contener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Confirmar contraseña',
            controller: confirmPasswordController,
            hint: 'Repetí tu contraseña',
            obscureText: true,
            validator: (value) {
              if (value != passwordController.text) {
                return 'Las contraseñas no coinciden.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Fecha de nacimiento',
            controller: birthDateController,
            hint: 'DD/MM/AAAA',
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Requerido';
              try {
                _parseBirthDate(value);
              } on FormatException {
                return 'Use el formato DD/MM/AAAA.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Documento (DNI)',
            controller: dniController,
            hint: '12.345.678',
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 24),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.lime[400],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Registrarme'),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isLoading ? null : onGoToLogin,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                children: [
                  const TextSpan(text: '¿Ya tenés cuenta? '),
                  TextSpan(
                    text: 'Iniciá sesión',
                    style: TextStyle(
                      color: Colors.lime[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
