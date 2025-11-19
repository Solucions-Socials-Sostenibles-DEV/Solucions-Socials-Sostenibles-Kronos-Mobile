import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
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
  bool get _canAddNotes => _userRole == 'admin' || _userRole == 'manager';
  String? _userName;
  List<String> _notas = <String>[];
  Map<String, String> _horarios = <String, String>{};
  bool _loadingChecklist = true;
  List<Map<String, dynamic>> _ckEquipamiento = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ckMenus = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ckBebidas = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ckGeneralPre = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ckGeneralDurante = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ckGeneralPost = <Map<String, dynamic>>[];

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
          .select('name, role')
          .eq('id', uid)
          .limit(1);
      if (mounted) {
        setState(() {
          _userRole = rows.isNotEmpty ? rows.first['role'] as String? : null;
          _userName =
              rows.isNotEmpty &&
                  (rows.first['name'] as String?)?.trim().isNotEmpty == true
              ? rows.first['name'] as String
              : (client.auth.currentUser?.email ?? 'usuario');
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
          final Map<String, dynamic>? h =
              hojaRuta?['horarios'] as Map<String, dynamic>?;
          _horarios = <String, String>{
            if (h != null && (h['montaje']?.toString().isNotEmpty ?? false))
              'Montaje': h['montaje'].toString(),
            if (h != null && (h['welcome']?.toString().isNotEmpty ?? false))
              'Welcome': h['welcome'].toString(),
            if (h != null && (h['desayuno']?.toString().isNotEmpty ?? false))
              'Desayuno': h['desayuno'].toString(),
            if (h != null && (h['comida']?.toString().isNotEmpty ?? false))
              'Comida': h['comida'].toString(),
            if (h != null && (h['recogida']?.toString().isNotEmpty ?? false))
              'Recogida': h['recogida'].toString(),
          };
        });
        // Cargar personal cuando se carga la hoja de ruta
        await _loadPersonal();
        await _loadChecklist();
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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      (Route<dynamic> r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
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
                // Sección de horarios
                _HorariosCard(horarios: _horarios, primary: primary),
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
                  canEdit: _canAddNotes,
                  onAdd: _addNota,
                  onDelete: _deleteNota,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                // Sección checklist de servicio
                _ChecklistCard(
                  loading: _loadingChecklist,
                  generalPre: _ckGeneralPre,
                  generalDurante: _ckGeneralDurante,
                  generalPost: _ckGeneralPost,
                  equipamiento: _ckEquipamiento,
                  menus: _ckMenus,
                  bebidas: _ckBebidas,
                  onToggle: _toggleChecklistItem,
                  onChangePriority: _changeChecklistPriority,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                // Apartado: Equipamientos y Material
                _EquipamientosMaterialCard(
                  items: _ckEquipamiento,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                // Apartado: Menús
                _MenusCard(items: _ckMenus, primary: primary),
                const SizedBox(height: 16),
                // Apartado: Bebidas
                _BebidasCard(items: _ckBebidas, primary: primary),
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
    if (!_canAddNotes) {
      _showSnack('No tienes permisos para añadir notas');
      return;
    }
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

  Future<void> _deleteNota(int index) async {
    if (!_canAddNotes) {
      _showSnack('No tienes permisos para eliminar notas');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text('¿Seguro que quieres eliminar esta nota?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirm != true || _hojaRutaActual?['id'] == null) return;
    try {
      final List<String> nuevas = <String>[..._notas]..removeAt(index);
      await _hojaRutaService.actualizarNotas(
        _hojaRutaActual!['id'] as String,
        nuevas,
      );
      if (mounted) {
        setState(() => _notas = nuevas);
        _showSnack('Nota eliminada');
      }
    } catch (e) {
      _showSnack('Error al eliminar la nota: $e');
    }
  }

  Future<void> _loadChecklist() async {
    if (_hojaRutaActual?['id'] == null) return;
    setState(() => _loadingChecklist = true);
    try {
      final String hojaId = _hojaRutaActual!['id'] as String;
      final List<Map<String, dynamic>> items = await _hojaRutaService
          .getChecklist(hojaId);
      final List<Map<String, dynamic>> equip = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> menus = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> bebidas = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> gPre = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> gDurante = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> gPost = <Map<String, dynamic>>[];
      for (final Map<String, dynamic> it in items) {
        final String tipo = (it['tipo'] as String?)?.toLowerCase() ?? '';
        if (tipo == 'equipamiento') {
          equip.add(it);
        } else if (tipo == 'menus') {
          menus.add(it);
        } else if (tipo == 'bebidas') {
          bebidas.add(it);
        } else if (tipo == 'general') {
          final String fase = (it['fase'] as String?)?.toLowerCase() ?? '';
          if (fase == 'preevento' || fase == 'pre-evento' || fase == 'pre') {
            gPre.add(it);
          } else if (fase == 'duranteevento' ||
              fase == 'durante-el-evento' ||
              fase == 'durante') {
            gDurante.add(it);
          } else {
            gPost.add(it);
          }
        }
      }
      if (mounted) {
        setState(() {
          _ckEquipamiento = equip;
          _ckMenus = menus;
          _ckBebidas = bebidas;
          _ckGeneralPre = gPre;
          _ckGeneralDurante = gDurante;
          _ckGeneralPost = gPost;
          _loadingChecklist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingChecklist = false);
        _showSnack('Error al cargar checklist: $e');
      }
    }
  }

  Future<void> _toggleChecklistItem({
    required String tipo,
    String? fase,
    required String tareaId,
    required bool current,
  }) async {
    if (_hojaRutaActual?['id'] == null) return;
    try {
      await _hojaRutaService.actualizarTareaChecklist(
        hojaRutaId: _hojaRutaActual!['id'] as String,
        tipo: tipo,
        fase: fase,
        tareaId: tareaId,
        completed: !current,
        assignedTo: !current
            ? (_userName ??
                  Supabase.instance.client.auth.currentUser?.email ??
                  'usuario')
            : null,
      );
      await _loadChecklist();
    } catch (e) {
      _showSnack('No se pudo actualizar la tarea: $e');
    }
  }

  Future<void> _changeChecklistPriority({
    required String tipo,
    String? fase,
    required String tareaId,
    required String priority,
  }) async {
    if (_hojaRutaActual?['id'] == null) return;
    try {
      await _hojaRutaService.actualizarPrioridadChecklist(
        hojaRutaId: _hojaRutaActual!['id'] as String,
        tipo: tipo,
        fase: fase,
        tareaId: tareaId,
        priority: priority,
      );
      await _loadChecklist();
    } catch (e) {
      _showSnack('No se pudo actualizar la prioridad: $e');
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

class _HorariosCard extends StatelessWidget {
  const _HorariosCard({required this.horarios, required this.primary});

  final Map<String, String> horarios;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final List<MapEntry<String, String>> entries = horarios.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                'Horarios',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin horarios',
                style: TextStyle(
                  color: fg.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.schedule, size: 18, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entries[i].key}: ${entries[i].value}',
                          style: TextStyle(color: fg, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  if (i != entries.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _NotasCard extends StatelessWidget {
  const _NotasCard({
    required this.notas,
    required this.canEdit,
    required this.onAdd,
    required this.onDelete,
    required this.primary,
  });

  final List<String> notas;
  final bool canEdit;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (canEdit) ...<Widget>[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Eliminar nota',
                          color: primary,
                          onPressed: () => onDelete(i),
                        ),
                      ],
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

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.loading,
    required this.generalPre,
    required this.generalDurante,
    required this.generalPost,
    required this.equipamiento,
    required this.menus,
    required this.bebidas,
    required this.onToggle,
    required this.onChangePriority,
    required this.primary,
  });

  final bool loading;
  final List<Map<String, dynamic>> generalPre;
  final List<Map<String, dynamic>> generalDurante;
  final List<Map<String, dynamic>> generalPost;
  final List<Map<String, dynamic>> equipamiento;
  final List<Map<String, dynamic>> menus;
  final List<Map<String, dynamic>> bebidas;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required bool current,
  })
  onToggle;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required String priority,
  })
  onChangePriority;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                'Checklist de servicio',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else
            DefaultTabController(
              length: 4,
              child: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: false,
                    labelColor: primary,
                    indicatorColor: primary,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    tabs: const <Widget>[
                      Tab(text: 'General'),
                      Tab(text: 'Equipo'),
                      Tab(text: 'Menús'),
                      Tab(text: 'Bebidas'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      children: <Widget>[
                        _GeneralChecklist(
                          pre: generalPre,
                          durante: generalDurante,
                          post: generalPost,
                          onToggle: onToggle,
                          onChangePriority: onChangePriority,
                        ),
                        _SimpleChecklist(
                          items: equipamiento,
                          tipo: 'equipamiento',
                          onToggle: onToggle,
                          onChangePriority: onChangePriority,
                        ),
                        _SimpleChecklist(
                          items: menus,
                          tipo: 'menus',
                          onToggle: onToggle,
                          onChangePriority: onChangePriority,
                        ),
                        _SimpleChecklist(
                          items: bebidas,
                          tipo: 'bebidas',
                          onToggle: onToggle,
                          onChangePriority: onChangePriority,
                        ),
                      ],
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

class _SimpleChecklist extends StatelessWidget {
  const _SimpleChecklist({
    required this.items,
    required this.tipo,
    required this.onToggle,
    required this.onChangePriority,
  });
  final List<Map<String, dynamic>> items;
  final String tipo;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required bool current,
  })
  onToggle;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required String priority,
  })
  onChangePriority;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final Map<String, dynamic> it = items[i];
        final String tareaId = (it['tarea_id'] as String?) ?? '${it['id']}';
        final String task = (it['task'] as String?) ?? '';
        final bool completed = (it['completed'] as bool?) ?? false;
        final String priority = ((it['priority'] as String?) ?? 'media')
            .toLowerCase();
        final String? assignedTo =
            (it['assigned_to'] as String?)?.trim().isEmpty == true
            ? null
            : (it['assigned_to'] as String?);
        Color chipColor;
        switch (priority) {
          case 'alta':
            chipColor = Colors.redAccent;
            break;
          case 'baja':
            chipColor = Colors.green;
            break;
          default:
            chipColor = Colors.amber[700]!;
        }
        return CheckboxListTile(
          value: completed,
          onChanged: (_) =>
              onToggle(tipo: tipo, tareaId: tareaId, current: completed),
          title: Text(task),
          subtitle: GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (BuildContext ctx) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(
                            Icons.priority_high,
                            color: Colors.redAccent,
                          ),
                          title: const Text('Alta'),
                          onTap: () {
                            Navigator.pop(ctx);
                            onChangePriority(
                              tipo: tipo,
                              tareaId: tareaId,
                              priority: 'alta',
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.low_priority,
                            color: Colors.amber[700],
                          ),
                          title: const Text('Media'),
                          onTap: () {
                            Navigator.pop(ctx);
                            onChangePriority(
                              tipo: tipo,
                              tareaId: tareaId,
                              priority: 'media',
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
                          ),
                          title: const Text('Baja'),
                          onTap: () {
                            Navigator.pop(ctx);
                            onChangePriority(
                              tipo: tipo,
                              tareaId: tareaId,
                              priority: 'baja',
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Row(
              children: <Widget>[
                if (assignedTo != null) ...<Widget>[
                  Flexible(
                    child: Text(
                      'Asignado: $assignedTo',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chipColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Prioridad ${priority[0].toUpperCase()}${priority.substring(1)}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GeneralChecklist extends StatelessWidget {
  const _GeneralChecklist({
    required this.pre,
    required this.durante,
    required this.post,
    required this.onToggle,
    required this.onChangePriority,
  });
  final List<Map<String, dynamic>> pre;
  final List<Map<String, dynamic>> durante;
  final List<Map<String, dynamic>> post;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required bool current,
  })
  onToggle;
  final void Function({
    required String tipo,
    String? fase,
    required String tareaId,
    required String priority,
  })
  onChangePriority;

  Widget _section(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    String fase,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ...items.map((Map<String, dynamic> it) {
          final String tareaId = (it['tarea_id'] as String?) ?? '${it['id']}';
          final String task = (it['task'] as String?) ?? '';
          final bool completed = (it['completed'] as bool?) ?? false;
          final String priority = ((it['priority'] as String?) ?? 'media')
              .toLowerCase();
          final String? assignedTo =
              (it['assigned_to'] as String?)?.trim().isEmpty == true
              ? null
              : (it['assigned_to'] as String?);
          Color chipColor;
          switch (priority) {
            case 'alta':
              chipColor = Colors.redAccent;
              break;
            case 'baja':
              chipColor = Colors.green;
              break;
            default:
              chipColor = Colors.amber[700]!;
          }
          return CheckboxListTile(
            value: completed,
            onChanged: (_) => onToggle(
              tipo: 'general',
              fase: fase,
              tareaId: tareaId,
              current: completed,
            ),
            title: Text(task),
            subtitle: GestureDetector(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (BuildContext ctx) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(
                              Icons.priority_high,
                              color: Colors.redAccent,
                            ),
                            title: const Text('Alta'),
                            onTap: () {
                              Navigator.pop(ctx);
                              onChangePriority(
                                tipo: 'general',
                                fase: fase,
                                tareaId: tareaId,
                                priority: 'alta',
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.low_priority,
                              color: Colors.amber[700],
                            ),
                            title: const Text('Media'),
                            onTap: () {
                              Navigator.pop(ctx);
                              onChangePriority(
                                tipo: 'general',
                                fase: fase,
                                tareaId: tareaId,
                                priority: 'media',
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.arrow_downward,
                              color: Colors.green,
                            ),
                            title: const Text('Baja'),
                            onTap: () {
                              Navigator.pop(ctx);
                              onChangePriority(
                                tipo: 'general',
                                fase: fase,
                                tareaId: tareaId,
                                priority: 'baja',
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                children: <Widget>[
                  if (assignedTo != null) ...<Widget>[
                    Flexible(
                      child: Text(
                        'Asignado: $assignedTo',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: chipColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Prioridad ${priority[0].toUpperCase()}${priority.substring(1)}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _section(context, 'Pre-Evento', pre, 'preEvento'),
          _section(context, 'Durante el evento', durante, 'duranteEvento'),
          _section(context, 'Post-Evento', post, 'postEvento'),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : primary.withOpacity(0.20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
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

class _EquipamientosMaterialCard extends StatelessWidget {
  const _EquipamientosMaterialCard({
    required this.items,
    required this.primary,
  });

  final List<Map<String, dynamic>> items;
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
                'Equipamientos y Material',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin equipamientos ni material',
                style: TextStyle(
                  color: fg.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
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
                          (items[i]['task'] as String?) ?? '—',
                          style: TextStyle(color: fg, fontSize: 16),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (i != items.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MenusCard extends StatelessWidget {
  const _MenusCard({required this.items, required this.primary});

  final List<Map<String, dynamic>> items;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    // Agrupar por bloque de menú (Welcome, PAUSA CAFE, COMIDA, REFRESCOS)
    final Map<String, List<Map<String, dynamic>>> grouped =
        <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> it in items) {
      final String task = (it['task'] as String?)?.trim() ?? '';
      final String rawCat =
          (it['categoria'] ?? it['category'] ?? it['fase'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
      final String cat = _normalizeMenuBlock(
        rawCat.isEmpty ? _inferMenuBlock(task) : rawCat,
      );
      grouped.putIfAbsent(cat, () => <Map<String, dynamic>>[]).add(it);
    }

    // Orden fijo de categorías como desktop
    const List<String> order = <String>[
      'welcome',
      'pausa_cafe',
      'comida',
      'refrescos',
      'otros',
    ];

    // Etiquetas visuales
    String labelFor(String key) {
      switch (key) {
        case 'welcome':
          return 'Welcome';
        case 'pausa_cafe':
          return 'PAUSA CAFE';
        case 'comida':
          return 'COMIDA';
        case 'refrescos':
          return 'REFRESCOS';
        default:
          return 'Otros';
      }
    }

    final List<String> categories = <String>[
      ...order.where((String k) => grouped.containsKey(k)),
      ...grouped.keys.where((String k) => !order.contains(k)),
    ];

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
                'Menús',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin menús definidos',
                style: TextStyle(
                  color: fg.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int c = 0; c < categories.length; c++) ...<Widget>[
                  if (c > 0) const SizedBox(height: 10),
                  Text(
                    labelFor(categories[c]),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...grouped[categories[c]]!.asMap().entries.map((
                    MapEntry<int, Map<String, dynamic>> entry,
                  ) {
                    final Map<String, dynamic> it = entry.value;
                    final String task = (it['task'] as String?) ?? '—';
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == grouped[categories[c]]!.length - 1
                            ? 0
                            : 6,
                      ),
                      child: Row(
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
                              task,
                              style: TextStyle(color: fg, fontSize: 16),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // Normaliza posibles valores a las claves canónicas
  String _normalizeMenuBlock(String raw) {
    final String t = raw
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();
    if (t.contains('welcome') ||
        t.contains('aperitivo') ||
        t.contains('recepcion') ||
        t.contains('recepción')) {
      return 'welcome';
    }
    if (t.contains('pausa') ||
        t.contains('cafe') ||
        t.contains('caf\u00E9') ||
        t.contains('coffee')) {
      return 'pausa_cafe';
    }
    if (t.contains('comida') ||
        t.contains('almuerzo') ||
        t.contains('lunch') ||
        t.contains('menu') ||
        t.contains('men\u00FA')) {
      return 'comida';
    }
    if (t.contains('refresco') ||
        t.contains('bebida') ||
        t.contains('drinks') ||
        t.contains('refrescos')) {
      return 'refrescos';
    }
    return 'otros';
  }

  // Inferencia por contenido del texto cuando no hay categoría explícita
  String _inferMenuBlock(String task) {
    final String t = task.toLowerCase();
    if (t.contains('welcome') ||
        t.contains('aperitivo') ||
        t.contains('recepcion') ||
        t.contains('recepción')) {
      return 'welcome';
    }
    if (t.contains('pausa') ||
        t.contains('cafe') ||
        t.contains('caf\u00E9') ||
        t.contains('coffee')) {
      return 'pausa_cafe';
    }
    if (t.contains('comida') ||
        t.contains('almuerzo') ||
        t.contains('plato') ||
        t.contains('primer') ||
        t.contains('segundo') ||
        t.contains('principal') ||
        t.contains('menu') ||
        t.contains('men\u00FA') ||
        t.contains('arro') ||
        t.contains('carne') ||
        t.contains('pescado')) {
      return 'comida';
    }
    if (t.contains('refresco') ||
        t.contains('bebida') ||
        t.contains('drinks') ||
        t.contains('agua') ||
        t.contains('zum') ||
        t.contains('soda')) {
      return 'refrescos';
    }
    return 'otros';
  }
}

class _BebidasCard extends StatelessWidget {
  const _BebidasCard({required this.items, required this.primary});

  final List<Map<String, dynamic>> items;
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
                'Bebidas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin bebidas',
                style: TextStyle(
                  color: fg.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
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
                          (items[i]['task'] as String?) ?? '—',
                          style: TextStyle(color: fg, fontSize: 16),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (i != items.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
