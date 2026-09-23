import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilEdit extends StatefulWidget {
  const PerfilEdit({super.key});

  @override
  State<PerfilEdit> createState() => _PerfilEditState();
}

class _PerfilEditState extends State<PerfilEdit> {
  static const _fullName = 'Carlos García';
  static const _email = 'carlos@sportsclub.com';

  final _nombreController = TextEditingController(text: 'Carlos');
  final _apellidoController = TextEditingController(text: 'García');
  final _dniController = TextEditingController(text: '31.234.567');
  final _fechaController = TextEditingController(text: '1990-05-15');
  final _emailController = TextEditingController(text: _email);

  bool _editing = false;

  String get _initials {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() => _editing = !_editing);
    if (!_editing) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _eliminarCuenta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es permanente y no se puede deshacer. ¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.currentUser?.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                  children: [
                    const TextSpan(text: 'MI '),
                    TextSpan(
                      text: 'PERFIL',
                      style: TextStyle(color: Colors.lime[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildDatosPersonalesCard(),
              const SizedBox(height: 16),
              _buildCerrarSesionButton(),
              const SizedBox(height: 16),
              _buildZonaPeligro(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.lime[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fullName,
                style: TextStyle(
                  color: Colors.grey[850],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _email,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'MIEMBRO ACTIVO',
                style: TextStyle(
                  color: Colors.lime[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatosPersonalesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DATOS PERSONALES',
                style: TextStyle(
                  color: Colors.grey[850],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _toggleEditing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lime[800],
                  side: BorderSide(color: Colors.lime[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: Icon(_editing ? Icons.check : Icons.edit, size: 16),
                label: Text(_editing ? 'Guardar' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField('NOMBRE', _nombreController)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('APELLIDO', _apellidoController)),
            ],
          ),
          const SizedBox(height: 16),
          _buildField('DNI', _dniController),
          const SizedBox(height: 16),
          _buildField('FECHA DE NACIMIENTO', _fechaController),
          const SizedBox(height: 16),
          _buildField(
            'EMAIL',
            _emailController,
            suffix: 'solo lectura',
            readOnly: true,
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? suffix,
    bool readOnly = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
            children: [
              TextSpan(text: label),
              if (suffix != null)
                TextSpan(
                  text: '  ($suffix)',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly || !_editing,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: readOnly,
            fillColor: Colors.grey[100],
            suffixIcon: icon != null
                ? Icon(icon, color: Colors.grey[500], size: 18)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCerrarSesionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cerrarSesion,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[850],
          side: BorderSide(color: Colors.grey[300]!),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Cerrar sesión'),
      ),
    );
  }

  Widget _buildZonaPeligro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[400],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'ZONA DE PELIGRO',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _eliminarCuenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}
