import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/date_formatter.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Map<String, dynamic>? _userProfile;
  User? _authUser;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
    });

    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      // Obtener datos de auth
      _authUser = client.auth.currentUser;

      // Obtener perfil de usuario
      final List<dynamic> profileData = await client
          .from('user_profiles')
          .select('id, name, role, created_at')
          .eq('id', userId)
          .limit(1);

      if (mounted) {
        setState(() {
          _userProfile = profileData.isNotEmpty
              ? profileData.first as Map<String, dynamic>
              : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _showSnack('Error al cargar datos del usuario: $e');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editarPerfil() async {
    final String nombreActual = _userProfile?['name'] as String? ?? '';
    final String rolActual = _userProfile?['role'] as String? ?? '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) =>
          _EditarPerfilDialog(nombreActual: nombreActual, rolActual: rolActual),
    );

    if (result != null) {
      await _guardarCambios(result['nombre']!, result['rol']!);
    }
  }

  Future<void> _guardarCambios(String nuevoNombre, String nuevoRol) async {
    setState(() {
      _saving = true;
    });

    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;

      if (userId == null) {
        _showSnack('No se pudo identificar al usuario');
        return;
      }

      await client
          .from('user_profiles')
          .update(<String, dynamic>{'name': nuevoNombre, 'role': nuevoRol})
          .eq('id', userId);

      if (mounted) {
        _showSnack('Perfil actualizado correctamente');
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al actualizar el perfil: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Image.asset(
              'assets/images/Logo Minimalist SSS High Opacity.PNG',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
        leadingWidth: 56,
        titleSpacing: 8,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Usuario',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Información del perfil',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Tarjeta principal de usuario
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2227) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : primary.withOpacity(0.15),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        // Icono de usuario
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withOpacity(0.1),
                            border: Border.all(
                              color: primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.person, size: 48, color: primary),
                        ),
                        const SizedBox(height: 20),
                        // Nombre
                        Text(
                          _userProfile?['name'] as String? ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rango
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            _userProfile?['role'] as String? ?? 'Sin rol',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Información adicional
                        _InfoItem(
                          icon: Icons.email,
                          label: 'Correo',
                          value: _authUser?.email ?? 'No disponible',
                          color: primary,
                          isDark: isDark,
                          fg: fg,
                        ),
                        const SizedBox(height: 16),
                        _InfoItem(
                          icon: Icons.calendar_today,
                          label: 'Miembro desde',
                          value: _userProfile?['created_at'] != null
                              ? DateFormatter.formatDate(
                                  DateTime.parse(
                                    _userProfile!['created_at'] as String,
                                  ),
                                )
                              : 'No disponible',
                          color: primary,
                          isDark: isDark,
                          fg: fg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón de editar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _editarPerfil,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.edit),
                      label: Text(_saving ? 'Guardando...' : 'Editar Perfil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Apartado de cambiar contraseña
                  _CambiarContrasenaCard(
                    primary: primary,
                    isDark: isDark,
                    fg: fg,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CambiarContrasenaCard extends StatefulWidget {
  const _CambiarContrasenaCard({
    required this.primary,
    required this.isDark,
    required this.fg,
  });

  final Color primary;
  final bool isDark;
  final Color fg;

  @override
  State<_CambiarContrasenaCard> createState() => _CambiarContrasenaCardState();
}

class _CambiarContrasenaCardState extends State<_CambiarContrasenaCard> {
  final TextEditingController _nuevaContrasenaController =
      TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();
  bool _mostrarContrasena = false;
  bool _mostrarConfirmar = false;
  bool _cambiando = false;

  @override
  void dispose() {
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cambiarContrasena() async {
    final String nuevaContrasena = _nuevaContrasenaController.text;
    final String confirmarContrasena = _confirmarContrasenaController.text;

    if (nuevaContrasena.isEmpty) {
      _showSnack('Por favor, introduce una nueva contraseña');
      return;
    }

    if (nuevaContrasena.length < 6) {
      _showSnack('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (nuevaContrasena != confirmarContrasena) {
      _showSnack('Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _cambiando = true;
    });

    try {
      final SupabaseClient client = Supabase.instance.client;
      await client.auth.updateUser(UserAttributes(password: nuevaContrasena));

      if (mounted) {
        _showSnack('Contraseña cambiada correctamente');
        _nuevaContrasenaController.clear();
        _confirmarContrasenaController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al cambiar la contraseña: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cambiando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white10
              : widget.primary.withOpacity(0.15),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cambiar Contraseña',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Campo nueva contraseña
          TextField(
            controller: _nuevaContrasenaController,
            obscureText: !_mostrarContrasena,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              hintText: 'Introduce tu nueva contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarContrasena = !_mostrarContrasena;
                  });
                },
                tooltip: _mostrarContrasena ? 'Ocultar' : 'Mostrar',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Campo confirmar contraseña
          TextField(
            controller: _confirmarContrasenaController,
            obscureText: !_mostrarConfirmar,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              hintText: 'Confirma tu nueva contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarConfirmar ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarConfirmar = !_mostrarConfirmar;
                  });
                },
                tooltip: _mostrarConfirmar ? 'Ocultar' : 'Mostrar',
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Botón cambiar contraseña
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cambiando ? null : _cambiarContrasena,
              icon: _cambiando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.lock_reset),
              label: Text(_cambiando ? 'Cambiando...' : 'Cambiar Contraseña'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: fg.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditarPerfilDialog extends StatefulWidget {
  const _EditarPerfilDialog({
    required this.nombreActual,
    required this.rolActual,
  });

  final String nombreActual;
  final String rolActual;

  @override
  State<_EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<_EditarPerfilDialog> {
  late final TextEditingController _nombreController;
  late String _rolSeleccionado;

  final List<String> _roles = <String>[
    'administrador',
    'Jefe',
    'Supervisor',
    'Empleado',
    'Usuario',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
    _rolSeleccionado = widget.rolActual.isNotEmpty
        ? widget.rolActual
        : _roles.first;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Editar Perfil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Campo nombre
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                hintText: 'Introduce tu nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // Selector de rol
            DropdownButtonFormField<String>(
              value: _roles.contains(_rolSeleccionado)
                  ? _rolSeleccionado
                  : _roles.first,
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              items: _roles.map((String rol) {
                return DropdownMenuItem<String>(value: rol, child: Text(rol));
              }).toList(),
              onChanged: (String? nuevoRol) {
                if (nuevoRol != null) {
                  setState(() {
                    _rolSeleccionado = nuevoRol;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final String nombre = _nombreController.text.trim();
                      if (nombre.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre no puede estar vacío'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(<String, String>{
                        'nombre': nombre,
                        'rol': _rolSeleccionado,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
