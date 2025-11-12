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
}
