import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class ForgotPasswordForm extends StatelessWidget {
  final GlobalKey<FormState>
  formKey; // Identificador unico del formulario. Habilita
  // acceso a al metodo .validate().
  final TextEditingController
  emailController; // Guarda y habilita acceso al texto
  // insertado por el usuario.
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const ForgotPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.onBack,
    required this.onSubmit,
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
            title: 'Recuperar contraseña',
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
          const SizedBox(height: 24),
          AuthErrorText(errorMessage),
          AuthSubmitButton(
            label: 'Enviar código',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
