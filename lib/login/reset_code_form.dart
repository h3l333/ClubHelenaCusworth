import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class ResetCodeForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const ResetCodeForm({
    super.key,
    required this.formKey,
    required this.codeController,
    required this.passwordController,
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
            title: 'Ingresar código',
            isLoading: isLoading,
            onBack: onBack,
          ),
          const SizedBox(height: 28),
          LabeledField(
            label: 'Código de 6 dígitos',
            controller: codeController,
            hint: '123456',
            keyboardType: TextInputType.number,
            validator: (v) =>
                RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Código inválido.',
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Nueva contraseña',
            controller: passwordController,
            hint: 'Mínimo 6 caracteres',
            obscureText: true,
            validator: validatePassword,
          ),
          const SizedBox(height: 24),
          AuthErrorText(errorMessage),
          AuthSubmitButton(
            label: 'Cambiar contraseña',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
