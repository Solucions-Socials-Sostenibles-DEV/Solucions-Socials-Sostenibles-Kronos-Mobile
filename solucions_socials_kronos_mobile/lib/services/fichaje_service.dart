import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class FichajeService {
  FichajeService(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // 1. OBTENER INFORMACIÓN DE FICHAJES
  // ---------------------------------------------------------------------------

  /// Obtiene el fichaje activo del usuario (el que no tiene fecha de salida)
  Future<Map<String, dynamic>?> getActiveFichaje(String userId) async {
    try {
      final Map<String, dynamic>? response = await _client
          .from('fichajes')
          .select()
          .eq('user_id', userId)
          .isFilter('salida', null)
          .order('entrada', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      Logger.e('Error getting active fichaje: $e');
      rethrow;
    }
  }

  /// Obtiene las pausas activas (sin fecha de fin) para un fichaje específico
  Future<Map<String, dynamic>?> getActivePausa(String fichajeId) async {
    try {
      final Map<String, dynamic>? response = await _client
          .from('fichajes_pausas')
          .select()
          .eq('fichaje_id', fichajeId)
          .isFilter('fin', null)
          .order('inicio', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      Logger.e('Error getting active pausa: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. OPERACIONES SOBRE FICHAJES (Entrada / Salida)
  // ---------------------------------------------------------------------------

  /// Registra un nuevo fichaje de entrada
  Future<Map<String, dynamic>> registrarEntrada({
    required String userId,
    String? ubicacion,
  }) async {
    try {
      // TODO: Si existe una función RPC en Supabase que centralice la creación,
      // se puede llamar así:
      // return await _client.rpc('iniciar_fichaje', params: {
      //   'p_user_id': userId,
      //   'p_ubicacion': ubicacion ?? '',
      // });

      final Map<String, dynamic> response = await _client
          .from('fichajes')
          .insert(<String, dynamic>{
            'user_id': userId,
            'entrada': DateTime.now().toUtc().toIso8601String(),
            'ubicacion': ubicacion,
            'estado_modificacion': 'original',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      Logger.e('Error en registrarEntrada: $e');
      rethrow;
    }
  }

  /// Finaliza el fichaje activo añadiendo una fecha de salida
  Future<Map<String, dynamic>> registrarSalida({
    required String fichajeId,
    String? ubicacion,
    double? horasTotales,
  }) async {
    try {
      // TODO: Si existe un RPC para calcular las horas totales y hacer la validación:
      // return await _client.rpc('finalizar_fichaje', params: { ... });

      final Map<String, dynamic> response = await _client
          .from('fichajes')
          .update(<String, dynamic>{
            'salida': DateTime.now().toUtc().toIso8601String(),
            if (ubicacion != null) 'ubicacion_salida': ubicacion,
            if (horasTotales != null) 'horas_totales': horasTotales,
          })
          .eq('fichaje_id', fichajeId) // o 'id', dependiendo de tu PK
          .select()
          .single();

      return response;
    } catch (e) {
      Logger.e('Error en registrarSalida: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. OPERACIONES SOBRE PAUSAS (Descansos, Comidas)
  // ---------------------------------------------------------------------------

  /// Inicia una pausa asociada a un fichaje activo
  Future<Map<String, dynamic>> iniciarPausa({
    required String fichajeId,
    required String tipoPausa,
  }) async {
    try {
      // TODO: Las pausas también podrían tener su propia función RPC en Supabase:
      // return await _client.rpc('iniciar_pausa', params: { ... });

      final Map<String, dynamic> response = await _client
          .from('fichajes_pausas')
          .insert(<String, dynamic>{
            'fichaje_id': fichajeId,
            'tipo': tipoPausa,
            'inicio': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      Logger.e('Error en iniciarPausa: $e');
      rethrow;
    }
  }

  /// Finaliza una pausa activa
  Future<Map<String, dynamic>> finalizarPausa({
    required String pausaId, // Asumo que existe un Identificador primario pausa_id (o 'id')
  }) async {
    try {
      final Map<String, dynamic> response = await _client
          .from('fichajes_pausas')
          .update(<String, dynamic>{
            'fin': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('pausa_id', pausaId) // o 'id'
          .select()
          .single();

      return response;
    } catch (e) {
      Logger.e('Error en finalizarPausa: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. METODOS GENÉRICOS DE RPC (Para funciones custom)
  // ---------------------------------------------------------------------------
  
  /// Llamada genérica a cualquier función RPC en caso de que todo el tracking de
  /// fichajes dependa 100% de la lógica de Base de Datos y no de inserts directos.
  Future<dynamic> callRpc(String rpcName, {Map<String, dynamic>? params}) async {
    try {
      final dynamic response = await _client.rpc(rpcName, params: params);
      return response;
    } catch (e) {
      Logger.e('Error callRpc "$rpcName": $e');
      rethrow;
    }
  }
}
