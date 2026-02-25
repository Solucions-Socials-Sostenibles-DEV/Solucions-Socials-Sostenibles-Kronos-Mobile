import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/fichaje_service.dart';
import '../../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FichajeCodigosScreen extends StatefulWidget {
  const FichajeCodigosScreen({super.key});

  @override
  State<FichajeCodigosScreen> createState() => _FichajeCodigosScreenState();
}

class _FichajeCodigosScreenState extends State<FichajeCodigosScreen> {
  final AdminService _adminService = AdminService();
  late final FichajeService _fichajeService;

  bool _isLoading = true;
  List<Map<String, dynamic>> _codigos = [];
  List<Map<String, dynamic>> _empleados = [];

  @override
  void initState() {
    super.initState();
    _fichajeService = FichajeService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar empleados (fuente de verdad desde user_profiles)
      _empleados = await _adminService.getUsers();
      
      // 2. Cargar códigos
      final List<Map<String, dynamic>> codigosBd = await _fichajeService.obtenerTodosLosCodigos();
      
      // 3. Cruzar y actualizar descripciones vacías si aplica
      for (var codigo in codigosBd) {
        String descripcion = codigo['descripcion'] as String? ?? '';
        final String empleadoId = codigo['empleado_id'] as String? ?? '';
        
        if (descripcion.trim().isEmpty && empleadoId.isNotEmpty) {
           final Iterable<Map<String, dynamic>> emps = _empleados.where((e) => e['id'] == empleadoId);
           if (emps.isNotEmpty) {
              descripcion = emps.first['name'] as String? ?? 'Empleado sin nombre';
              // Actualizamos en BD usando el servicio
              try {
                await _fichajeService.actualizarDescripcionCodigo(codigo['id'] as int, descripcion);
              } catch (updateError) {
                Logger.e('No se pudo actualizar la descripción en Supabase: $updateError');
              }
              codigo['descripcion'] = descripcion; // Lo actualizamos en la UI
           }
        }
      }

      if (mounted) {
        setState(() {
          _codigos = codigosBd;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.e('Error cargando códigos de fichaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando códigos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getEmpleadoNombre(String? empleadoId, String? descripcionBd) {
    if (descripcionBd != null && descripcionBd.trim().isNotEmpty) {
      return descripcionBd;
    }
    if (empleadoId == null || empleadoId.isEmpty) return 'Desconocido';
    final Iterable<Map<String, dynamic>> emps = _empleados.where((e) => e['id'] == empleadoId);
    return emps.isNotEmpty ? (emps.first['name'] as String? ?? 'Desconocido') : 'Empleado no encontrado';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos de Fichaje'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _codigos.length,
            itemBuilder: (context, index) {
              final codigoObj = _codigos[index];
              final strCodigo = codigoObj['codigo']?.toString() ?? 'N/A';
              final empleadoId = codigoObj['empleado_id']?.toString();
              final descripcionBd = codigoObj['descripcion']?.toString();
              final isActivo = codigoObj['activo'] == true;
              
              final nombreMostrado = _getEmpleadoNombre(empleadoId, descripcionBd);

              return Card(
                color: isDark ? const Color(0xFF1F2227) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActivo ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    child: Icon(
                      Icons.password, 
                      color: isActivo ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                     nombreMostrado,
                     style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isActivo ? 'Estado: Activo' : 'Estado: Inactivo',
                    style: TextStyle(
                      color: isActivo ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      strCodigo,
                      style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                         letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            },
        ),
    );
  }
}
