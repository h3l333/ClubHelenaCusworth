import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'date_utils.dart';
import 'services/api_client.dart';
import 'services/profile_store.dart';
import 'widgets/common.dart';
import 'widgets/form_fields.dart';

// Se muestra cuando el usuario existe en Firebase pero no tiene perfil en la base
// (ej. primer inicio de sesion con Google).
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController();
  late final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _dniController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final parts = (FirebaseAuth.instance.currentUser?.displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) _firstNameController.text = parts.first;
    if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await ApiClient.instance.createUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: parseBirthDate(_birthDateController.text),
        dni: _dniController.text.trim(),
      );
      ProfileStore.instance.setProfile(profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Completá tu perfil',
                    style: TextStyle(
                      color: Colors.grey[850],
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Necesitamos estos datos para poder reservar canchas.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Nombre',
                          controller: _firstNameController,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Apellido',
                          controller: _lastNameController,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Fecha de nacimiento',
                    controller: _birthDateController,
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
                      if (picked != null) {
                        _birthDateController.text = formatDate(picked);
                      }
                    },
                    validator: validateBirthDate,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Documento (DNI)',
                    controller: _dniController,
                    hint: '12.345.678',
                    keyboardType: TextInputType.number,
                    validator: validateDni,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: limeFilledStyle(),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => FirebaseAuth.instance.signOut(),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
