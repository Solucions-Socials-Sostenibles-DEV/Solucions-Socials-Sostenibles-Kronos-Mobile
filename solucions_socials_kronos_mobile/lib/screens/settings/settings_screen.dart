import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme_controller.dart';
import '../../config/external_services_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    final ThemeController controller = context.watch<ThemeController>();
    final bool isDark = controller.isDark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        centerTitle: false,
        titleSpacing: 16,
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
              'Ajustes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ajustes generales de la aplicación',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Sección tipo tarjeta como en Hoja de Ruta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2227) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
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
                      'Preferencias',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  child: SwitchListTile.adaptive(
                    value: isDark,
                    onChanged: controller.toggleDark,
                    title: const Text('Modo oscuro'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sección de divisas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2227) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
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
                      'Configuración de divisas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: _CurrencyDropdown(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Estado de conexiones (debajo de divisas)
          const _ConnectionsStatusCard(),
          const SizedBox(height: 16),
          // Datos de la aplicación
          _AppInfoCard(isDark: isDark),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: child,
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final Color fg = isDark ? Colors.white : Colors.black;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
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
                'Datos de la aplicación',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('Versión', style: TextStyle(color: fg)),
                  subtitle: Text(
                    '1.0.0',
                    style: TextStyle(color: fg.withOpacity(0.7)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(
                    'Contacto del desarrollador',
                    style: TextStyle(color: fg),
                  ),
                  subtitle: Text(
                    'comunicacio@solucionssocials.org',
                    style: TextStyle(color: fg.withOpacity(0.7)),
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

class _ConnectionsStatusCard extends StatefulWidget {
  const _ConnectionsStatusCard();

  @override
  State<_ConnectionsStatusCard> createState() => _ConnectionsStatusCardState();
}

class _ConnectionsStatusCardState extends State<_ConnectionsStatusCard> {
  bool? supabaseOk;
  bool? holdedSolucionsOk;
  bool? holdedMenjadorOk;
  bool loading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    try {
      final bool sb = await _checkSupabase();
      final bool hs = await _checkHttp(
        ExternalServicesConfig.holdedSolucionsUrl,
        ExternalServicesConfig.holdedSolucionsToken,
      );
      final bool hm = await _checkHttp(
        ExternalServicesConfig.holdedMenjadorUrl,
        ExternalServicesConfig.holdedMenjadorToken,
      );
      setState(() {
        supabaseOk = sb;
        holdedSolucionsOk = hs;
        holdedMenjadorOk = hm;
      });
    } catch (e) {
      setState(() => errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<bool> _checkSupabase() async {
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkHttp(String url, String token) async {
    if (url.isEmpty) return false;
    try {
      final Map<String, String> headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final http.Response resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      return resp.statusCode >= 200 && resp.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    Widget statusTile(String title, bool? ok) {
      final bool isOk = ok == true;
      final IconData icon = isOk ? Icons.check_circle : Icons.error;
      final Color color = isOk ? primary : Colors.redAccent;
      final String label = isOk
          ? 'Conectado correctamente'
          : 'Error con la conexión';
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(label, style: TextStyle(color: fg.withOpacity(0.7))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2227) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
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
                'Estado de conexiones',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: loading ? null : _checkAll,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorMsg!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          statusTile('Supabase', supabaseOk),
          statusTile('Holded Solucions', holdedSolucionsOk),
          statusTile('Holded Menjador', holdedMenjadorOk),
        ],
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final ThemeController controller = context.watch<ThemeController>();
    final Currency selected = controller.currency;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;

    final List<DropdownMenuItem<Currency>> items = Currency.values.map((
      Currency c,
    ) {
      return DropdownMenuItem<Currency>(
        value: c,
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Text(
                c.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('${c.label} (${c.symbol})', style: TextStyle(color: fg)),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Tipo de divisa', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: fg.withOpacity(0.2)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Currency>(
              value: selected,
              isExpanded: true,
              items: items,
              onChanged: (Currency? value) {
                if (value != null) {
                  controller.setCurrency(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
