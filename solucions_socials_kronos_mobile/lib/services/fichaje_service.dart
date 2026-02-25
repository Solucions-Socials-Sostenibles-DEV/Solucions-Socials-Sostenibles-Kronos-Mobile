import 'package:intl/intl.dart';
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

  /// Obtiene el estado actual del dashboard para determinar qué botones mostrar
  Future<Map<String, dynamic>> getDashboardStatus(String empleadoId) async {
    try {
      final String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Buscar si hay fichaje hoy
      final List<dynamic> fichajesHoy = await _client
          .from('fichajes')
          .select()
          .eq('empleado_id', empleadoId)
          .eq('fecha', hoy)
          .limit(1);

      if (fichajesHoy.isEmpty) {
        return <String, dynamic>{
          'estado': 'SIN_FICHAJE', // Mostrar botón [FICHAR ENTRADA]
          'fichaje': null,
          'pausaActiva': null,
        };
      }

      final Map<String, dynamic> fichaje = fichajesHoy.first as Map<String, dynamic>;
      final String fichajeId = fichaje['id'].toString();

      // 2. Si ya tiene salida
      if (fichaje['hora_salida'] != null || fichaje['salida'] != null) {
        return <String, dynamic>{
          'estado': 'FICHAJE_CERRADO', // Mostrar resumen del día
          'fichaje': fichaje,
          'pausaActiva': null,
        };
      }

      // 3. Está abierto, buscar pausa activa
      final Map<String, dynamic>? pausaActiva = await getActivePausa(fichajeId);

      if (pausaActiva != null) {
        return <String, dynamic>{
          'estado': 'PAUSA_ACTIVA', // Mostrar botón [FINALIZAR PAUSA], bloquear salida
          'fichaje': fichaje,
          'pausaActiva': pausaActiva,
        };
      }

      // 4. Está abierto y sin pausa
      return <String, dynamic>{
        'estado': 'FICHAJE_ABIERTO', // Mostrar [INICIAR PAUSA] y [FICHAR SALIDA]
        'fichaje': fichaje,
        'pausaActiva': null,
      };
      
    } catch (e) {
      Logger.e('Error en getDashboardStatus: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. OPERACIONES SOBRE FICHAJES (Entrada / Salida / Auto-cierre)
  // ---------------------------------------------------------------------------

  /// Verifica y cierra automáticamente los fichajes de días anteriores sin salida
  Future<void> verificarYCerrarFichajesOlvidados(String empleadoId) async {
    try {
      final String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Buscar fichajes del empleado, anteriores a hoy, que no tengan salida
      final List<dynamic> olvidados = await _client
          .from('fichajes')
          .select()
          .eq('empleado_id', empleadoId)
          .lt('fecha', hoy)
          .isFilter('salida', null)
          .isFilter('hora_salida', null); // Asegurarse de ambas

      for (final dynamic row in olvidados) {
        final Map<String, dynamic> fichaje = row as Map<String, dynamic>;
        final String idOlvidado = fichaje['id'].toString();

        Logger.i('Cerrando fichaje olvidado: $idOlvidado del día ${fichaje['fecha']}');
        
        // Finalizar pausa si hubiese alguna colgada usando RPC (o si se requiere forzar fin de pausa)
        final Map<String, dynamic>? pausa = await getActivePausa(idOlvidado);
        if (pausa != null) {
           await _client.rpc('finalizar_pausa_fichaje', params: <String, dynamic>{
             'p_pausa_id': pausa['id'] ?? pausa['pausa_id'],
           });
        }

        // Llamar RPC para registrar salida
        await _client.rpc('registrar_salida_fichaje', params: <String, dynamic>{
          'p_fichaje_id': idOlvidado,
        });

        // Marcar como modificado/olvidado (si el RPC no lo hace por defecto)
        await _client
            .from('fichajes')
            .update(<String, dynamic>{'es_modificado': true})
            .eq('id', idOlvidado);
      }
    } catch (e) {
      Logger.e('Error en verificarYCerrarFichajesOlvidados: $e');
      // No re-lanzamos para que no bloquee el login, solo se loguea.
    }
  }

  /// Registra un nuevo fichaje de entrada
  Future<Map<String, dynamic>> registrarEntrada({
    required String empleadoId,
    required String userId,
    double? latitud,
    double? longitud,
    String? textoUbicacion,
  }) async {
    try {
      final String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Comprobar primero que el empleado no tenga ya un fichaje creado para el día de hoy.
      final List<dynamic> fichajesHoy = await _client
          .from('fichajes')
          .select()
          .eq('empleado_id', empleadoId)
          .eq('fecha', hoy)
          .limit(1);

      if (fichajesHoy.isNotEmpty) {
        throw Exception('El empleado ya tiene un fichaje registrado hoy.');
      }

      // 2. Insertar el nuevo registro
      final Map<String, dynamic> response = await _client
          .from('fichajes')
          .insert(<String, dynamic>{
            'empleado_id': empleadoId,
            'fecha': hoy,
            'hora_entrada': null, // El trigger de supabase usará now()
            'created_by': userId,
            'es_modificado': false,
            if (latitud != null) 'ubicacion_lat': latitud,
            if (longitud != null) 'ubicacion_lng': longitud,
            if (textoUbicacion != null) 'ubicacion_texto': textoUbicacion,
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
  Future<void> registrarSalida({
    required String fichajeId,
  }) async {
    try {
      // 1. Obtener el fichaje actual para verificar fecha y salida
      // Asumimos que la columna primaria se llama 'id' o 'fichaje_id'. 
      // Si falla .eq('id', ...), ajustar al nombre correcto.
      final List<dynamic> fichajes = await _client
          .from('fichajes')
          .select()
          .eq('id', fichajeId)
          .limit(1);

      if (fichajes.isEmpty) {
        throw Exception('El fichaje de hoy no existe o el ID es inválido.');
      }

      final Map<String, dynamic> fichaje = fichajes.first as Map<String, dynamic>;
      final String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      if (fichaje['fecha'] != hoy) {
         throw Exception('El fichaje no corresponde al día de hoy.');
      }
      
      // Comprobar tanto 'hora_salida' como 'salida' para asegurar
      if (fichaje['hora_salida'] != null || fichaje['salida'] != null) {
         throw Exception('El fichaje de hoy ya tiene registrada la salida.');
      }

      // 2. Que no haya pausas activas
      final Map<String, dynamic>? pausaActiva = await getActivePausa(fichajeId);
      if (pausaActiva != null) {
        throw Exception('Debes finalizar tu pausa actual antes de registrar la salida.');
      }

      // 3. Llamar a la función RPC de Supabase
      await _client.rpc('registrar_salida_fichaje', params: <String, dynamic>{
        'p_fichaje_id': fichajeId,
      });

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
    String? descripcion,
  }) async {
    try {
      // 1. Verificar tener un fichaje abierto (sin hora de salida)
      final List<dynamic> fichajes = await _client
          .from('fichajes')
          .select()
          .eq('id', fichajeId) // O 'fichaje_id' según la BD
          .limit(1);

      if (fichajes.isEmpty) {
        throw Exception('El fichaje no existe.');
      }
      final Map<String, dynamic> fichaje = fichajes.first as Map<String, dynamic>;
      if (fichaje['hora_salida'] != null || fichaje['salida'] != null) {
        throw Exception('No puedes iniciar una pausa en un fichaje ya cerrado.');
      }

      // 2. Verificar que no haya otra pausa activa
      final Map<String, dynamic>? pausaActiva = await getActivePausa(fichajeId);
      if (pausaActiva != null) {
        throw Exception('Ya tienes una pausa activa, finalízala primero.');
      }

      // 3. Insertar la nueva pausa en la base de datos
      final Map<String, dynamic> response = await _client
          .from('fichajes_pausas')
          .insert(<String, dynamic>{
            'fichaje_id': fichajeId,
            'tipo': tipoPausa,
            'inicio': null, // Usa now() del servidor por trigger
            if (descripcion != null) 'descripcion': descripcion,
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
  Future<void> finalizarPausa({
    required String pausaIdActiva,
  }) async {
    try {
      // Importante: Para mostrar las "horas trabajadas" en tiempo real tras finalizar,
      // la UI/Provider local tendrá que restar la duración de la pausa al tiempo 
      // transcurrido. El cálculo oficial se hace al cerrar el fichaje en base de datos.
      
      await _client.rpc('finalizar_pausa_fichaje', params: <String, dynamic>{
        'p_pausa_id': pausaIdActiva,
      });

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
