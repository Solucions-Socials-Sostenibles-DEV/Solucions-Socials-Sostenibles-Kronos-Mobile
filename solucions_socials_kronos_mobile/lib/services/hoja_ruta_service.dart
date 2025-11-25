import 'package:supabase_flutter/supabase_flutter.dart';

class HojaRutaService {
  HojaRutaService(this._client);

  final SupabaseClient _client;

  /// Obtiene el total de hojas de ruta
  Future<int> getTotalHojasRuta() async {
    try {
      final List<dynamic> data = await _client.from('hojas_ruta').select('id');

      return data.length;
    } catch (e) {
      throw Exception('Error al obtener el total de hojas de ruta: $e');
    }
  }

  /// Obtiene la fecha de la última actualización de cualquier hoja de ruta
  Future<DateTime?> getUltimaActualizacion() async {
    try {
      final List<dynamic> data = await _client
          .from('hojas_ruta')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        final updatedAt = data.first['updated_at'] as String?;
        if (updatedAt != null) {
          return DateTime.parse(updatedAt).toLocal();
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la última actualización: $e');
    }
  }

  /// Obtiene ambas estadísticas en una sola llamada
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final total = await getTotalHojasRuta();
      final ultimaActualizacion = await getUltimaActualizacion();

      return <String, dynamic>{
        'total': total,
        'ultimaActualizacion': ultimaActualizacion,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Obtiene la hoja de ruta más reciente (última actualizada)
  Future<Map<String, dynamic>?> getHojaRutaActual() async {
    try {
      final List<dynamic> data = await _client
          .from('hojas_ruta')
          .select(
            'id, fecha_servicio, cliente, contacto, direccion, transportista, responsable, num_personas, notas, horarios, firma_info, firma_responsable, personal_text',
          )
          .order('fecha_servicio', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la hoja de ruta actual: $e');
    }
  }

  /// Obtiene una hoja de ruta por su ID
  Future<Map<String, dynamic>?> getHojaRutaById(String hojaId) async {
    try {
      final Map<String, dynamic>? data = await _client
          .from('hojas_ruta')
          .select(
            'id, fecha_servicio, cliente, contacto, direccion, transportista, responsable, num_personas, notas, horarios, firma_info, firma_responsable, personal_text',
          )
          .eq('id', hojaId)
          .maybeSingle();
      return data;
    } catch (e) {
      throw Exception('Error al obtener la hoja de ruta por id: $e');
    }
  }

  /// Obtiene el histórico de hojas de ruta, ordenado por actualización descendente
  Future<List<Map<String, dynamic>>> getHistoricoHojasRuta({
    int limit = 100,
    int offset = 1, // por defecto omitimos la primera (actual), como en desktop
  }) async {
    try {
      final int end = offset + limit - 1;
      final List<dynamic> data = await _client
          .from('hojas_ruta')
          .select(
            'id, fecha_servicio, cliente, contacto, direccion, transportista, responsable, num_personas',
          )
          .order('fecha_servicio', ascending: false)
          .range(offset, end);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error al obtener el histórico de hojas de ruta: $e');
    }
  }

  /// Marca la hoja como firmada (confirmada) con el nombre del firmante
  Future<void> firmarHojaRuta({
    required String hojaId,
    required String nombreFirmante,
  }) async {
    try {
      final Map<String, dynamic> firmaInfo = <String, dynamic>{
        'firmado': true,
        'firmado_por': nombreFirmante,
        'fecha_firma': DateTime.now().toIso8601String(),
        'firma_data': nombreFirmante,
      };

      await _client
          .from('hojas_ruta')
          .update(<String, dynamic>{
            'firma_info': firmaInfo,
            'firma_responsable': nombreFirmante,
          })
          .eq('id', hojaId);
    } catch (e) {
      throw Exception('Error al firmar la hoja de ruta: $e');
    }
  }

  /// Obtiene el personal de una hoja de ruta
  Future<List<Map<String, dynamic>>> getPersonalHojaRuta(
    String hojaRutaId,
  ) async {
    try {
      final List<dynamic> data = await _client
          .from('hojas_ruta_personal')
          .select('id, nombre, horas, empleado_id')
          .eq('hoja_ruta_id', hojaRutaId)
          .order('nombre');

      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error al obtener el personal: $e');
    }
  }

  /// Actualiza las horas de un empleado
  Future<void> actualizarHorasPersonal(String personalId, double horas) async {
    try {
      await _client
          .from('hojas_ruta_personal')
          .update(<String, dynamic>{'horas': horas})
          .eq('id', personalId);
    } catch (e) {
      throw Exception('Error al actualizar las horas: $e');
    }
  }

  /// Crea o actualiza (upsert) un registro de personal por hoja y nombre
  Future<Map<String, dynamic>?> upsertPersonalHojaRuta({
    required String hojaRutaId,
    required String nombre,
    required double horas,
  }) async {
    try {
      final List<dynamic> rows = await _client
          .from('hojas_ruta_personal')
          .upsert(<String, dynamic>{
            'hoja_ruta_id': hojaRutaId,
            'nombre': nombre,
            'horas': horas,
          }, onConflict: 'hoja_ruta_id,nombre')
          .select()
          .limit(1);
      return rows.isNotEmpty ? rows.first as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Error al crear/actualizar el personal: $e');
    }
  }

  /// Actualiza las notas importantes de una hoja de ruta
  Future<void> actualizarNotas(String hojaRutaId, List<String> notas) async {
    try {
      await _client
          .from('hojas_ruta')
          .update(<String, dynamic>{'notas': notas})
          .eq('id', hojaRutaId);
    } catch (e) {
      throw Exception('Error al actualizar las notas: $e');
    }
  }

  /// Obtiene el checklist completo de una hoja de ruta
  Future<List<Map<String, dynamic>>> getChecklist(String hojaRutaId) async {
    try {
      final List<dynamic> data = await _client
          .from('hojas_ruta_checklist')
          .select(
            'id, hoja_ruta_id, tipo, fase, tarea_id, task, completed, assigned_to, priority',
          )
          .eq('hoja_ruta_id', hojaRutaId)
          .order('tipo')
          .order('fase');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error al obtener el checklist: $e');
    }
  }

  /// Obtiene detalles de un empleado (intenta tabla 'empleados' y fallback a 'employees')
  Future<Map<String, dynamic>?> getEmpleadoDetalle(String empleadoId) async {
    // Intentar tabla 'empleados'; si no existe o falla, ignorar y seguir
    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('empleados')
          .select('*')
          .eq('id', empleadoId)
          .maybeSingle();
    } catch (_) {
      // ignorado: la relación puede no existir en algunos entornos
    }
    if (data == null) {
      try {
        data = await _client
            .from('employees')
            .select('*')
            .eq('id', empleadoId)
            .maybeSingle();
      } catch (_) {
        // ignorado
      }
    }
    return data;
  }

  /// Marca/Desmarca una tarea del checklist
  Future<void> actualizarTareaChecklist({
    required String hojaRutaId,
    required String tipo,
    String? fase,
    required String tareaId,
    required bool completed,
    String? assignedTo,
  }) async {
    try {
      var query = _client
          .from('hojas_ruta_checklist')
          .update(<String, dynamic>{
            'completed': completed,
            'assigned_to': assignedTo,
          })
          .eq('hoja_ruta_id', hojaRutaId)
          .eq('tipo', tipo)
          .eq('tarea_id', tareaId);
      query = fase == null
          ? query.filter('fase', 'is', null)
          : query.eq('fase', fase);
      await query;
    } catch (e) {
      throw Exception('Error al actualizar la tarea del checklist: $e');
    }
  }

  /// Actualiza la prioridad de una tarea del checklist
  Future<void> actualizarPrioridadChecklist({
    required String hojaRutaId,
    required String tipo,
    String? fase,
    required String tareaId,
    required String priority, // 'alta' | 'media' | 'baja'
  }) async {
    try {
      var query = _client
          .from('hojas_ruta_checklist')
          .update(<String, dynamic>{'priority': priority})
          .eq('hoja_ruta_id', hojaRutaId)
          .eq('tipo', tipo)
          .eq('tarea_id', tareaId);
      query = fase == null
          ? query.filter('fase', 'is', null)
          : query.eq('fase', fase);
      await query;
    } catch (e) {
      throw Exception('Error al actualizar la prioridad: $e');
    }
  }
}
