import 'package:flutter/material.dart';

import '../date_utils.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class RegisterForm extends StatelessWidget {
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

  const RegisterForm({
    super.key,
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
          AuthHeader(title: 'Registrarme', isLoading: isLoading, onBack: onBack),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Nombre',
                  controller: firstNameController,
                  hint: 'Juan',
                  validator: validateRequired,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Apellido',
                  controller: lastNameController,
                  hint: 'Pérez',
                  validator: validateRequired,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          LabeledField(
            label: 'Confirmar contraseña',
            controller: confirmPasswordController,
            hint: 'Repetí tu contraseña',
            obscureText: true,
            validator: (value) => value != passwordController.text
                ? 'Las contraseñas no coinciden.'
                : null,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Fecha de nacimiento',
            controller: birthDateController,
            hint: 'DD/MM/AAAA',
            readOnly: true,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(now.year - 18),
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked != null) birthDateController.text = formatDate(picked);
            },
            validator: validateBirthDate,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Documento (DNI)',
            controller: dniController,
            hint: '12.345.678',
            keyboardType: TextInputType.number,
            validator: validateDni,
          ),
          const SizedBox(height: 24),
          AuthErrorText(errorMessage),
          AuthSubmitButton(
            label: 'Registrarme',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 16),
          AuthSwitchLink(
            prompt: '¿Ya tenés cuenta? ',
            action: 'Iniciá sesión',
            isLoading: isLoading,
            onTap: onGoToLogin,
          ),
        ],
      ),
    );
  }
}
