import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/fichaje_service.dart';
import '../../utils/logger.dart';

class FichajeScreen extends StatefulWidget {
  const FichajeScreen({super.key});

  @override
  State<FichajeScreen> createState() => _FichajeScreenState();
}

class _FichajeScreenState extends State<FichajeScreen> {
  late FichajeService _fichajeService;
  late final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  String _estado = 'SIN_FICHAJE';
  Map<String, dynamic>? _fichajeActual;
  Map<String, dynamic>? _pausaActiva;

  String? _empleadoId;
  String? _userId;

  // Variables para simular el cronómetro en UI
  Timer? _timer;
  Duration _workedDuration = Duration.zero;

  bool _isCodeValidated = false;
  final TextEditingController _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fichajeService = FichajeService(_client);
    _isLoading = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _validarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _showSnack('Introduce un código');
      return;
    }
    FocusScope.of(context).unfocus(); // Ocultar teclado
    setState(() => _isLoading = true);
    try {
      final data = await _fichajeService.validarCodigo(codigo);
      setState(() {
        _empleadoId = data['empleado_id']?.toString();
        _isCodeValidated = true;
      });
      await _initFichajeDashboard();
    } catch (e) {
      Logger.e('Error al validar código: $e');
      // Si falla por columna inexistente o cualquier cosa, mostrar error
      _showSnack('No se pudo validar el código. Comprueba que sea correcto.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initFichajeDashboard() async {
    setState(() => _isLoading = true);
    try {
      final User? currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        _userId = currentUser.id;
      }

      if (_empleadoId == null) {
         throw Exception('Empleado ID no encontrado');
      }

      // 1. Cerrar fichajes olvidados del día anterior
      await _fichajeService.verificarYCerrarFichajesOlvidados(_empleadoId!);

      // 2. Obtener estado actual
      await _refreshStatus();
    } catch (e) {
      Logger.e('Error en _initFichaje: $e');
      if (mounted) _showSnack('Error al inicializar fichaje: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _fichajeService.getDashboardStatus(_empleadoId!);
      
      if (mounted) {
        setState(() {
          _estado = status['estado'] as String;
          _fichajeActual = status['fichaje'] as Map<String, dynamic>?;
          _pausaActiva = status['pausaActiva'] as Map<String, dynamic>?;
        });
        
        _updateTimer();
      }
    } catch (e) {
      Logger.e('Error en _refreshStatus: $e');
    }
  }

  void _updateTimer() {
    _timer?.cancel();
    _workedDuration = Duration.zero;

    if (_estado == 'FICHAJE_CERRADO' && _fichajeActual != null) {
      // Mostrar horas totales si ya cerró
      final horasLocales = _fichajeActual!['horas_totales'] as num?;
      if (horasLocales != null) {
         _workedDuration = Duration(minutes: (horasLocales * 60).toInt());
      }
      return;
    }

    if (_fichajeActual == null) return;

    final entradaStr = _fichajeActual!['entrada'] as String?;
    if (entradaStr == null) return;

    final entrada = DateTime.parse(entradaStr).toLocal();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // TODO: Para hacerlo exacto, habría que calcular la resta de pausas terminadas y pausa activa
          // Por simplicidad en la UI básica mostramos tiempo desde entrada
          _workedDuration = DateTime.now().difference(entrada);
        });
      }
    });
  }

  Future<void> _ficharEntrada() async {
    setState(() => _isLoading = true);
    try {
      await _fichajeService.registrarEntrada(
        empleadoId: _empleadoId!,
        userId: _userId!,
      );
      _showSnack('Entrada registrada');
      await _refreshStatus();
    } catch (e) {
      _showSnack('Error al registrar entrada: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ficharSalida() async {
    if (_fichajeActual == null) return;
    setState(() => _isLoading = true);
    try {
      await _fichajeService.registrarSalida(
        fichajeId: _fichajeActual!['id'].toString(),
      );
      _showSnack('Salida registrada');
      await _refreshStatus();
    } catch (e) {
      _showSnack('Error al registrar salida: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _iniciarPausaFunc() async {
    if (_fichajeActual == null) return;
    setState(() => _isLoading = true);
    try {
      await _fichajeService.iniciarPausa(
        fichajeId: _fichajeActual!['id'].toString(),
        tipoPausa: 'descanso',
      );
      _showSnack('Pausa iniciada');
      await _refreshStatus();
    } catch (e) {
      _showSnack('Error al iniciar pausa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizarPausaFunc() async {
    if (_pausaActiva == null) return;
    setState(() => _isLoading = true);
    try {
      final String pausaId = (_pausaActiva!['id'] ?? _pausaActiva!['pausa_id']).toString();
      await _fichajeService.finalizarPausa(pausaIdActiva: pausaId);
      _showSnack('Pausa finalizada');
      await _refreshStatus();
    } catch (e) {
      _showSnack('Error al finalizar pausa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60).abs());
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Jornada'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isCodeValidated
              ? _buildCodeInputView()
              : _buildDashboardView(),
    );
  }

  Widget _buildCodeInputView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.access_time_filled, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Introduce tu código de fichaje',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Introduce el código único asignado para fichar. El jefe puede fichar por cualquier empleado.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2227) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.green.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _codigoController,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    hintText: 'EJ: 1234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.password),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _validarCodigo(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Validar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiempo transcurrido
                  if (_estado != 'SIN_FICHAJE')
                    Column(
                      children: [
                        const Text(
                          'Tiempo Transcurrido',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_workedDuration),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),

                  // Botones basados en estado
                  if (_estado == 'SIN_FICHAJE')
                    _buildBigButton(
                      label: 'FICHAR ENTRADA',
                      color: Colors.green,
                      icon: Icons.login,
                      onPressed: _ficharEntrada,
                    ),

                  if (_estado == 'FICHAJE_ABIERTO') ...[
                    _buildBigButton(
                      label: 'INICIAR PAUSA',
                      color: Colors.orange,
                      icon: Icons.pause_circle_outline,
                      onPressed: _iniciarPausaFunc,
                    ),
                    const SizedBox(height: 16),
                    _buildBigButton(
                      label: 'FICHAR SALIDA',
                      color: Colors.redAccent,
                      icon: Icons.logout,
                      onPressed: _ficharSalida,
                    ),
                  ],

                  if (_estado == 'PAUSA_ACTIVA')
                    _buildBigButton(
                      label: 'FINALIZAR PAUSA',
                      color: Colors.blue,
                      icon: Icons.play_circle_outline,
                      onPressed: _finalizarPausaFunc,
                    ),

                  if (_estado == 'FICHAJE_CERRADO')
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Jornada Finalizada',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Has completado tu fichaje por hoy.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            );
  }

  Widget _buildBigButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}

