import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _saving = false;
  String? _error;
  final PageController _controller = PageController();
  int _page = 0;

  Future<void> _complete() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client
          .from('user_profiles')
          .update(<String, dynamic>{'onboarding_completed': true})
          .eq('id', userId);
      // Navegar a la app principal
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainShell()),
          (Route<dynamic> r) => false,
        );
      }
    } catch (e) {
      setState(() => _error = 'No se pudo completar el onboarding');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_page < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primary = Color(0xFF4CAF51);
    final Color fg = isDark ? Colors.white : Colors.black;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Encabezado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF4CAF51), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Bienvenido a SSS Kronos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Un breve recorrido por las secciones principales',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2227) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : primary.withOpacity(0.15),
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
                            Expanded(
                              child: PageView(
                                controller: _controller,
                                onPageChanged: (int i) => setState(() => _page = i),
                                children: <Widget>[
                                  _OnbPage(
                                    icon: Icons.dashboard_rounded,
                                    title: 'Hoja de Ruta',
                                    fg: fg,
                                    desc: const <String>[
                                      'Consulta la hoja activa con cliente, personas y horarios.',
                                      'Gestiona el checklist de servicio por categorías.',
                                      'Añade notas importantes (según tu rol).',
                                    ],
                                  ),
                                  _OnbPage(
                                    icon: Icons.people_alt_rounded,
                                    title: 'Personal',
                                    fg: fg,
                                    desc: const <String>[
                                      'Visualiza el equipo asignado.',
                                      'Roles con permisos (Admin, Gestión, Jefe) pueden editar horas.',
                                      'Usuarios ven el listado sin horas.',
                                    ],
                                  ),
                                  _OnbPage(
                                    icon: Icons.restaurant_menu_rounded,
                                    title: 'Menús y Bebidas',
                                    fg: fg,
                                    desc: const <String>[
                                      'Menús agrupados: Welcome, Pausa Café, Comida, Refrescos.',
                                      'Contenido proveniente de la versión desktop (Excel).',
                                      'Vista limpia, sin edición desde móvil.',
                                    ],
                                  ),
                                  _OnbPage(
                                    icon: Icons.settings_rounded,
                                    title: 'Ajustes y Perfil',
                                    fg: fg,
                                    desc: const <String>[
                                      'Activa modo oscuro y elige divisa.',
                                      'Comprueba el estado de conexiones.',
                                      'Edita tu nombre y, si tu rol lo permite, cambia roles.',
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Indicadores
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List<Widget>.generate(4, (int i) {
                                final bool active = _page == i;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                  height: 8,
                                  width: active ? 20 : 8,
                                  decoration: BoxDecoration(
                                    color: active ? primary : (isDark ? Colors.white12 : Colors.black12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Acciones
                    Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: _saving ? null : _skip,
                          child: const Text('Saltar'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _next,
                          icon: _saving
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_page < 3 ? Icons.arrow_forward_rounded : Icons.check_rounded, size: 18),
                          label: Text(_page < 3 ? 'Siguiente' : 'Finalizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  const _OnbPage({
    required this.icon,
    required this.title,
    required this.desc,
    required this.fg,
  });

  final IconData icon;
  final String title;
  final List<String> desc;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: fg.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 34, color: fg.withOpacity(0.9)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...desc.map(
            (String t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
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


