import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/hoja_ruta_service.dart';
import '../../utils/date_formatter.dart';

class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key});

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  late final AuthService _authService;
  late final HojaRutaService _hojaRutaService;
  int _totalHojasRuta = 0;
  DateTime? _ultimaActualizacion;
  bool _loadingStats = true;
  Map<String, dynamic>? _hojaRutaActual;
  bool _loadingHojaRuta = true;
  List<Map<String, dynamic>> _personal = <Map<String, dynamic>>[];
  bool _loadingPersonal = true;
  String? _userRole;
  bool get _canEditPersonal =>
      _userRole == 'admin' ||
      _userRole == 'management' ||
      _userRole == 'manager';
  List<String> _notas = <String>[];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
    _hojaRutaService = HojaRutaService(Supabase.instance.client);
    _loadUserRole();
    _loadEstadisticas();
    _loadHojaRutaActual();
  }

  Future<void> _loadUserRole() async {
    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? uid = client.auth.currentUser?.id;
      if (uid == null) return;
      final List<Map<String, dynamic>> rows = await client
          .from('user_profiles')
          .select('role')
          .eq('id', uid)
          .limit(1);
      if (mounted) {
        setState(() {
          _userRole = rows.isNotEmpty ? rows.first['role'] as String? : null;
        });
      }
    } catch (_) {
      // Ignorar: se considerará sin permisos de edición
    }
  }

  Future<void> _loadPersonal() async {
    if (_hojaRutaActual == null || _hojaRutaActual!['id'] == null) {
      setState(() {
        _personal = <Map<String, dynamic>>[];
        _loadingPersonal = false;
      });
      return;
    }

    setState(() {
      _loadingPersonal = true;
    });

    try {
      final hojaRutaId = _hojaRutaActual!['id'] as String;
      final personal = await _hojaRutaService.getPersonalHojaRuta(hojaRutaId);
      if (mounted) {
        setState(() {
          _personal = personal;
          _loadingPersonal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPersonal = false;
        });
        _showSnack('Error al cargar el personal: $e');
      }
    }
  }

  Future<void> _loadEstadisticas() async {
    setState(() {
      _loadingStats = true;
    });

    try {
      final stats = await _hojaRutaService.getEstadisticas();
      if (mounted) {
        setState(() {
          _totalHojasRuta = stats['total'] as int;
          _ultimaActualizacion = stats['ultimaActualizacion'] as DateTime?;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
        _showSnack('Error al cargar estadísticas: $e');
      }
    }
  }

  Future<void> _loadHojaRutaActual() async {
    setState(() {
      _loadingHojaRuta = true;
    });

    try {
      final hojaRuta = await _hojaRutaService.getHojaRutaActual();
      if (mounted) {
        setState(() {
          _hojaRutaActual = hojaRuta;
          _loadingHojaRuta = false;
          _notas =
              (hojaRuta?['notas'] as List<dynamic>?)
                  ?.map((dynamic e) => e?.toString() ?? '')
                  .where((String e) => e.isNotEmpty)
                  .toList() ??
              <String>[];
        });
        // Cargar personal cuando se carga la hoja de ruta
        await _loadPersonal();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingHojaRuta = false;
        });
        _showSnack('Error al cargar la hoja de ruta: $e');
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hoja de Ruta',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gestión de la hoja de ruta',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth > 700;
          final EdgeInsets padding = EdgeInsets.symmetric(
            horizontal: wide ? 32 : 16,
            vertical: 20,
          );
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Sección de acciones en tarjeta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1F2227)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Acciones',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ActionList(
                        primary: primary,
                        primaryDark: primaryDark,
                        onTapConfirmar: () =>
                            _showSnack('Confirmar Lista y material'),
                        onTapEliminar: () => _showSnack('Eliminar'),
                        onTapHistorico: () => _showSnack('Histórico'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Sección de estadísticas
                _EstadisticasCard(
                  total: _totalHojasRuta,
                  ultimaActualizacion: _ultimaActualizacion,
                  loading: _loadingStats,
                  onRefresh: _loadEstadisticas,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                // Sección de información general
                _InformacionGeneralCard(
                  hojaRuta: _hojaRutaActual,
                  loading: _loadingHojaRuta,
                  onRefresh: _loadHojaRutaActual,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                // Sección de personal
                _PersonalCard(
                  personal: _personal,
                  loading: _loadingPersonal,
                  onRefresh: _loadPersonal,
                  onEditarHoras: _editarHorasPersonal,
                  onVerDatos: _verDatosEmpleado,
                  primary: primary,
                  canEdit: _canEditPersonal,
                ),
                const SizedBox(height: 16),
                _NotasCard(
                  notas: _notas,
                  canEdit: _canEditPersonal,
                  onAdd: _addNota,
                  primary: primary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Subida de hoja deshabilitada en esta versión

  Future<void> _addNota() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        const Color primary = Color(0xFF4CAF51);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Añadir nota importante',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe la nota...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          final String text = controller.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(context).pop(text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
      },
    );
    if (result != null && result.isNotEmpty && _hojaRutaActual?['id'] != null) {
      try {
        final List<String> nuevas = <String>[..._notas, result];
        await _hojaRutaService.actualizarNotas(
          _hojaRutaActual!['id'] as String,
          nuevas,
        );
        if (mounted) {
          setState(() => _notas = nuevas);
          _showSnack('Nota añadida');
        }
      } catch (e) {
        _showSnack('Error al guardar la nota: $e');
      }
    }
  }

  Future<void> _editarHorasPersonal(Map<String, dynamic> empleado) async {
    if (!_canEditPersonal) {
      _showSnack('No tienes permisos para editar horas');
      return;
    }
    final String personalId = empleado['id'] as String;
    final String nombre = empleado['nombre'] as String;
    final double horasActuales = (empleado['horas'] as num?)?.toDouble() ?? 0.0;

    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) =>
          _EditarHorasDialog(nombre: nombre, horasActuales: horasActuales),
    );

    if (result != null && result != horasActuales) {
      try {
        await _hojaRutaService.actualizarHorasPersonal(personalId, result);
        if (mounted) {
          _showSnack('Horas actualizadas correctamente');
          await _loadPersonal();
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Error al actualizar las horas: $e');
        }
      }
    }
  }

  void _verDatosEmpleado(Map<String, dynamic> empleado) {
    // TODO: Implementar vista de datos del empleado
    _showSnack('Ver datos de ${empleado['nombre']} (próximamente)');
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({
    required this.primary,
    required this.primaryDark,
    required this.onTapConfirmar,
    required this.onTapEliminar,
    required this.onTapHistorico,
  });

  final Color primary;
  final Color primaryDark;
  final VoidCallback onTapConfirmar;
  final VoidCallback onTapEliminar;
  final VoidCallback onTapHistorico;

  @override
  Widget build(BuildContext context) {
    final List<_ActionItem> items = <_ActionItem>[
      _ActionItem(
        label: 'Confirmar Lista y material',
        icon: Icons.checklist_outlined,
        onTap: onTapConfirmar,
      ),
      _ActionItem(
        label: 'Eliminar',
        icon: Icons.delete_outline,
        onTap: onTapEliminar,
      ),
      _ActionItem(
        label: 'Histórico',
        icon: Icons.history,
        onTap: onTapHistorico,
      ),
    ];

    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          _ActionButton(
            label: items[i].label,
            icon: items[i].icon,
            primary: primary,
            primaryDark: primaryDark,
            onTap: items[i].onTap,
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActionItem {
  _ActionItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.primaryDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color primary;
  final Color primaryDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final LinearGradient gradient = LinearGradient(
      colors: <Color>[primary, primaryDark],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: fg.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotasCard extends StatelessWidget {
  const _NotasCard({
    required this.notas,
    required this.canEdit,
    required this.onAdd,
    required this.primary,
  });

  final List<String> notas;
  final bool canEdit;
  final VoidCallback onAdd;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Notas importantes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (canEdit)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: 'Añadir nota',
                  color: primary,
                  style: IconButton.styleFrom(
                    backgroundColor: primary.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (notas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin notas',
                style: TextStyle(
                  color: fg.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int i = 0; i < notas.length; i++) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notas[i],
                          style: TextStyle(color: fg, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (i != notas.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _EstadisticasCard extends StatelessWidget {
  const _EstadisticasCard({
    required this.total,
    required this.ultimaActualizacion,
    required this.loading,
    required this.onRefresh,
    required this.primary,
  });

  final int total;
  final DateTime? ultimaActualizacion;
  final bool loading;
  final VoidCallback onRefresh;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: loading ? null : onRefresh,
                tooltip: 'Actualizar estadísticas',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Column(
              children: <Widget>[
                // Total de hojas de ruta
                _StatItem(
                  icon: Icons.assignment,
                  label: 'Total de hojas de ruta',
                  value: total.toString(),
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                // Última actualización
                _StatItem(
                  icon: Icons.update,
                  label: 'Última actualización',
                  value: ultimaActualizacion != null
                      ? DateFormatter.formatDateTime(
                          ultimaActualizacion!,
                          pattern: 'dd/MM/yyyy HH:mm',
                        )
                      : 'N/A',
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformacionGeneralCard extends StatelessWidget {
  const _InformacionGeneralCard({
    required this.hojaRuta,
    required this.loading,
    required this.onRefresh,
    required this.primary,
  });

  final Map<String, dynamic>? hojaRuta;
  final bool loading;
  final VoidCallback onRefresh;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Información General',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: loading ? null : onRefresh,
                tooltip: 'Actualizar información',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hojaRuta == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay hoja de ruta cargada',
                  style: TextStyle(
                    color: fg.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                _InfoRow(
                  label: 'Fecha del Servicio',
                  value: _formatFechaServicio(hojaRuta!['fecha_servicio']),
                  icon: Icons.calendar_today,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Cliente',
                  value: hojaRuta!['cliente'] as String? ?? '—',
                  icon: Icons.business,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Nº Personas',
                  value: (hojaRuta!['num_personas'] as int? ?? 0).toString(),
                  icon: Icons.people,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Responsable',
                  value: hojaRuta!['responsable'] as String? ?? '—',
                  icon: Icons.person,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Transportista',
                  value: hojaRuta!['transportista'] as String? ?? '—',
                  icon: Icons.local_shipping,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Contacto',
                  value: hojaRuta!['contacto'] as String? ?? '—',
                  icon: Icons.phone,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Dirección',
                  value: hojaRuta!['direccion'] as String? ?? '—',
                  icon: Icons.location_on,
                  color: primary,
                  isDark: isDark,
                  fg: fg,
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatFechaServicio(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      if (fecha is String) {
        final date = DateTime.parse(fecha);
        return DateFormatter.formatDate(date);
      }
      return fecha.toString();
    } catch (_) {
      return fecha.toString();
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({
    required this.personal,
    required this.loading,
    required this.onRefresh,
    required this.onEditarHoras,
    required this.onVerDatos,
    required this.primary,
    required this.canEdit,
  });

  final List<Map<String, dynamic>> personal;
  final bool loading;
  final VoidCallback onRefresh;
  final Function(Map<String, dynamic>) onEditarHoras;
  final Function(Map<String, dynamic>) onVerDatos;
  final Color primary;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    // Calcular el total de horas
    double totalHoras = 0.0;
    if (!loading && personal.isNotEmpty) {
      for (final empleado in personal) {
        final horas = (empleado['horas'] as num?)?.toDouble() ?? 0.0;
        totalHoras += horas;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Personal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (!loading && personal.isNotEmpty && canEdit)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.access_time, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'Total: ${totalHoras.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: loading ? null : onRefresh,
                tooltip: 'Actualizar personal',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (personal.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay personal asignado',
                  style: TextStyle(
                    color: fg.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int i = 0; i < personal.length; i++) ...<Widget>[
                  _PersonalItem(
                    empleado: personal[i],
                    onEditarHoras: () => onEditarHoras(personal[i]),
                    onVerDatos: () => onVerDatos(personal[i]),
                    primary: primary,
                    isDark: isDark,
                    fg: fg,
                    canEdit: canEdit,
                  ),
                  if (i != personal.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _PersonalItem extends StatelessWidget {
  const _PersonalItem({
    required this.empleado,
    required this.onEditarHoras,
    required this.onVerDatos,
    required this.primary,
    required this.isDark,
    required this.fg,
    required this.canEdit,
  });

  final Map<String, dynamic> empleado;
  final VoidCallback onEditarHoras;
  final VoidCallback onVerDatos;
  final Color primary;
  final bool isDark;
  final Color fg;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final String nombre = empleado['nombre'] as String? ?? '—';
    final double horas = (empleado['horas'] as num?)?.toDouble() ?? 0.0;
    final String horasTexto = horas.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                if (canEdit)
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: fg.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$horasTexto horas',
                        style: TextStyle(
                          fontSize: 13,
                          color: fg.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botón Ver Datos
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: onVerDatos,
            tooltip: 'Ver datos',
            color: primary,
            style: IconButton.styleFrom(
              backgroundColor: primary.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),
          // Botón Editar
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEditarHoras,
              tooltip: 'Editar horas',
              color: primary,
              style: IconButton.styleFrom(
                backgroundColor: primary.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditarHorasDialog extends StatefulWidget {
  const _EditarHorasDialog({required this.nombre, required this.horasActuales});

  final String nombre;
  final double horasActuales;

  @override
  State<_EditarHorasDialog> createState() => _EditarHorasDialogState();
}

class _EditarHorasDialogState extends State<_EditarHorasDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.horasActuales.toStringAsFixed(1),
    );
    // Seleccionar todo el texto al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _incrementar() {
    final double current = double.tryParse(_controller.text) ?? 0.0;
    final double nuevo = current + 0.5;
    _controller.text = nuevo.toStringAsFixed(1);
  }

  void _decrementar() {
    final double current = double.tryParse(_controller.text) ?? 0.0;
    final double nuevo = (current - 0.5).clamp(0.0, double.infinity);
    _controller.text = nuevo.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

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
                    'Editar Horas',
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
            const SizedBox(height: 16),
            Text(
              'Empleado: ${widget.nombre}',
              style: TextStyle(fontSize: 14, color: fg.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            // Controles de horas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _decrementar,
                  iconSize: 32,
                  color: primary,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _incrementar,
                  iconSize: 32,
                  color: primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'horas',
                style: TextStyle(fontSize: 14, color: fg.withOpacity(0.6)),
              ),
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
                      final double? horas = double.tryParse(_controller.text);
                      if (horas != null && horas >= 0) {
                        Navigator.of(context).pop(horas);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor, introduce un número válido',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
