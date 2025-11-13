import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../utils/roles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  bool _isRegister = false;
  String _selectedRole = RoleUtils.canonical.last; // user

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    setState(() => _isSubmitting = true);
    try {
      if (_isRegister) {
        final String fullName = _nameController.text.trim();
        if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
          _showSnack('Completa nombre, email y contraseña');
          return;
        }
        await _authService.signUp(
          email: email,
          password: password,
          fullName: fullName,
          role: _selectedRole,
        );
      } else {
        if (email.isEmpty || password.isEmpty) {
          _showSnack('Introduce email y contraseña');
          return;
        }
        await _authService.signInWithEmail(email: email, password: password);
      }
      // AuthGate se encargará de la navegación cuando haya sesión
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final Color muted = fg.withOpacity(0.7);
    const Color primary = Color(0xFF4CAF51);
    final LinearGradient bgGradient = isDark
        ? const LinearGradient(
            colors: <Color>[Color(0xFF0B0C0F), Color(0xFF14161A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: <Color>[Colors.white, Color(0xFFF2FAFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.asset(
                        'assets/images/Logo Minimalist SSS High Opacity.PNG',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      'SSS Kronos',
                      style: TextStyle(
                        color: fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegister ? 'Crea tu cuenta' : 'Accede para continuar',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Card translucida (glassmorphism)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : Colors.white.withOpacity(0.55))
                                    .withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.08),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (_isRegister) ...<Widget>[
                                _AppleField(
                                  controller: _nameController,
                                  label: 'Nombre completo',
                                  keyboardType: TextInputType.name,
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 12),
                                _RolePicker(
                                  value: _selectedRole,
                                  onChanged: (String v) =>
                                      setState(() => _selectedRole = v),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _AppleField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),
                              _AppleField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                obscure: true,
                                icon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 20),
                              _PrimaryButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isRegister
                                            ? 'Crear cuenta'
                                            : 'Iniciar sesión',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Column(
                      children: <Widget>[
                        Text(
                          _isRegister
                              ? '¿Ya tienes cuenta?'
                              : '¿No tienes cuenta?',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () =>
                                    setState(() => _isRegister = !_isRegister),
                          child: Text(
                            _isRegister ? 'Iniciar sesión' : 'Crear una',
                            style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Protegido por Supabase',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleField extends StatefulWidget {
  const _AppleField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.icon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final IconData? icon;

  @override
  State<_AppleField> createState() => _AppleFieldState();
}

class _AppleFieldState extends State<_AppleField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final Color hint = fg.withOpacity(0.55);
    const Color primary = Color(0xFF4CAF51);
    final Color fill = isDark
        ? const Color(0xFF23262B).withOpacity(0.7)
        : Colors.white.withOpacity(0.9);
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscure,
      decoration: InputDecoration(
        prefixIcon: widget.icon != null ? Icon(widget.icon, color: hint) : null,
        labelText: widget.label,
        labelStyle: TextStyle(color: hint),
        filled: true,
        fillColor: fill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hint.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: hint,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
      style: TextStyle(color: fg),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    const LinearGradient gradient = LinearGradient(
      colors: <Color>[primary, primaryDark],
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          color: onPressed == null ? Colors.grey.withOpacity(0.4) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final Map<String, String> descriptions = <String, String>{
      'user': 'Acceso básico de la aplicación',
      'manager': 'Gestión de equipos y reportes',
      'management': 'Analisis completo de archivos',
      'admin': 'Control total del sistema',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Rol',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: RoleUtils.canonical
                  .map(
                    (String r) => DropdownMenuItem<String>(
                      value: r,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(RoleUtils.label(r), style: TextStyle(color: fg)),
                          const SizedBox(height: 2),
                          Text(
                            descriptions[r] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: fg.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? r) {
                if (r != null) onChanged(r);
              },
            ),
          ),
        ),
      ],
    );
  }
}
