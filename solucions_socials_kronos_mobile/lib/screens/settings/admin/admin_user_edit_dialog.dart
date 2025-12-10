import 'package:flutter/material.dart';
import '../../../utils/roles.dart';
import '../../../services/admin_service.dart';

class AdminUserEditDialog extends StatefulWidget {
  const AdminUserEditDialog({
    super.key,
    required this.userId,
    required this.currentName,
    required this.currentRole,
  });

  final String userId;
  final String currentName;
  final String currentRole;

  @override
  State<AdminUserEditDialog> createState() => _AdminUserEditDialogState();
}

class _AdminUserEditDialogState extends State<AdminUserEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  late String _selectedRole;
  bool _isLoading = false;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedRole = RoleUtils.toCanonical(widget.currentRole);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Actualizar datos perfil
      await _adminService.updateUser(
        widget.userId,
        _nameController.text,
        _selectedRole,
      );

      // 2. Actualizar contraseña si se escribió algo
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6) {
           throw Exception('La contraseña debe tener al menos 6 caracteres');
        }
        await _adminService.updateUserPassword(
          widget.userId,
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true si hubo cambios
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final List<String> roles = RoleUtils.canonical;

    return AlertDialog(
      title: const Text('Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  icon: Icon(Icons.person),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduce un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Rol
              DropdownButtonFormField<String>(
                value: roles.contains(_selectedRole) ? _selectedRole : roles.first,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  icon: Icon(Icons.badge),
                ),
                items: roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(RoleUtils.label(role)),
                  );
                }).toList(),
                onChanged: (String? val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 16),
              // Contraseña (Opcional)
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña (Opcional)',
                  icon: Icon(Icons.lock_reset),
                  helperText: 'Dejar vacío para no cambiar',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              )
            : const Text('Guardar'),
        ),
      ],
    );
  }
}
