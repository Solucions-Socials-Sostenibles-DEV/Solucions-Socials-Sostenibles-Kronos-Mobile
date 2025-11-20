import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/date_formatter.dart';
import '../../services/hoja_ruta_service.dart';

class RutaHistoricoScreen extends StatefulWidget {
  const RutaHistoricoScreen({super.key});

  @override
  State<RutaHistoricoScreen> createState() => _RutaHistoricoScreenState();
}

class _RutaHistoricoScreenState extends State<RutaHistoricoScreen> {
  static const Color primary = Color(0xFF4CAF51);
  static const Color primaryDark = Color(0xFF3C8E41);

  late final HojaRutaService _hojaRutaService;
  bool _loading = true;
  List<Map<String, dynamic>> _historico = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _hojaRutaService = HojaRutaService(Supabase.instance.client);
    _loadHistorico();
  }

  Future<void> _loadHistorico() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> data = await _hojaRutaService
          .getHistoricoHojasRuta(limit: 200);
      if (mounted) {
        setState(() {
          _historico = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar histórico: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        centerTitle: false,
        actionsIconTheme: const IconThemeData(color: Colors.white),
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
              'Histórico',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hojas de ruta subidas',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _historico.isEmpty
          ? _EmptyState(isDark: isDark)
          : RefreshIndicator(
              onRefresh: _loadHistorico,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> item = _historico[index];
                  final DateTime? fechaServicio =
                      (item['fecha_servicio'] as String?)?.let(
                        (String s) => DateTime.tryParse(s)?.toLocal(),
                      );
                  final String fecha = fechaServicio != null
                      ? DateFormatter.formatDate(fechaServicio)
                      : '—';
                  final String cliente = item['cliente'] as String? ?? '—';
                  final String responsable =
                      item['responsable'] as String? ?? '—';
                  final int numPersonas = (item['num_personas'] as int?) ?? 0;
                  final String direccion = item['direccion'] as String? ?? '—';

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2227) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primary.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                fecha,
                                style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cliente,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Responsable',
                          value: responsable,
                          fg: fg,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.groups_2_outlined,
                          label: 'Personas',
                          value: numPersonas.toString(),
                          fg: fg,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección',
                          value: direccion,
                          fg: fg,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _historico.length,
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: _RutaHistoricoScreenState.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay histórico disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _RutaHistoricoScreenState.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Las hojas de ruta subidas aparecerán aquí',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20, color: fg.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: fg.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
