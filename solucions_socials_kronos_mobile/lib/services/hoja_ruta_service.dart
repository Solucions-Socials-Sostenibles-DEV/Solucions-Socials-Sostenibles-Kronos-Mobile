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
            'id, fecha_servicio, cliente, contacto, direccion, transportista, responsable, num_personas, notas, horarios',
          )
          .order('updated_at', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la hoja de ruta actual: $e');
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
}
