import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../utils/roles.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene la lista de todos los perfiles de usuario
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final List<dynamic> response = await _client
          .from('user_profiles')
          .select()
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.e('Error al obtener usuarios: $e');
      rethrow;
    }
  }

  /// Actualiza los datos de un usuario (Nombre y Rol)
  Future<void> updateUser(String userId, String name, String role) async {
    try {
      final String canonicalRole = RoleUtils.toCanonical(role);
      
      // Actualizar perfil público
      await _client
          .from('user_profiles')
          .update({
            'name': name.trim(),
            'role': canonicalRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
          
      // NOTA: No podemos actualizar metadata de auth de OTRO usuario desde el cliente
      // a menos que tengamos una Edge Function o permisos especiales.
      // Por ahora confiamos en que user_profiles es la fuente de verdad para la UI.
      
      Logger.d('Usuario actualizado correctamente: $userId');
    } catch (e) {
      Logger.e('Error al actualizar usuario: $e');
      rethrow;
    }
  }

  /// Elimina un usuario (de la tabla user_profiles)
  /// Para eliminarlo de Auth se requeriría una Edge Function con service_role key
  Future<void> deleteUser(String userId) async {
    try {
      await _client.from('user_profiles').delete().eq('id', userId);
      Logger.d('Usuario eliminado de user_profiles: $userId');
    } catch (e) {
      Logger.e('Error al eliminar usuario: $e');
      rethrow;
    }
  }

  /// Intenta cambiar la contraseña de un usuario
  /// ESTO FALLARÁ SI NO HAY PERMISOS SUFICIENTES (RLS/Auth Policies)
  /// Se deja implementado por si se configura un RPC o policy que lo permita
  Future<void> updateUserPassword(String userId, String newPassword) async {
    try {
      // Usar RPC helper para actualizar contraseña (requiere ejecutar script SQL en Supabase)
      await _client.rpc('admin_update_password', params: {
        'target_user_id': userId,
        'new_password': newPassword,
      });
      Logger.d('Contraseña actualizada para: $userId');
    } catch (e) {
      Logger.e('Error al actualizar contraseña: $e');
      if (e.toString().contains('function not found') || e.toString().contains('404')) {
        throw Exception('Falta configurar la función SQL "admin_update_password" en Supabase.');
      }
      rethrow;
    }
  }
}
