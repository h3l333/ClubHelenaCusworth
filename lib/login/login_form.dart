import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGoToRegister;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onBack,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onGoToRegister,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Iniciar sesión',
            isLoading: isLoading,
            onBack: onBack,
          ),
          const SizedBox(height: 28),
          LabeledField(
            label: 'Correo electrónico',
            controller: emailController,
            hint: 'ejemplo@correo.com',
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Contraseña',
            controller: passwordController,
            hint: 'Mínimo 6 caracteres',
            obscureText: true,
            validator: validatePassword,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 12),
          AuthErrorText(errorMessage),
          AuthSubmitButton(
            label: 'Iniciar sesión',
            isLoading: isLoading,
            onPressed: onSubmit,
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
          AuthSwitchLink(
            prompt: '¿No tenés cuenta? ',
            action: 'Registrate',
            isLoading: isLoading,
            onTap: onGoToRegister,
          ),
        ],
      ),
    );
  }
}
