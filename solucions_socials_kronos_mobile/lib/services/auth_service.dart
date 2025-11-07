import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final String trimmedUsername = username.trim();
    // 1) Intentar directamente como si fuera email (por si el usuario introduce su email)
    try {
      if (trimmedUsername.contains('@')) {
        await _client.auth.signInWithPassword(
          email: trimmedUsername,
          password: password,
        );
        return;
      }
    } catch (_) {
      // Ignorar y continuar con la resolución por tablas
    }

    // 2) Resolver email a partir del nombre de usuario en tablas comunes
    final String? email = await _resolveEmailForUsername(trimmedUsername);
    if (email == null) {
      throw const AuthException('Usuario no encontrado');
    }
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;

  Future<String?> _resolveEmailForUsername(String username) async {
    // 0) Intentar RPC si existe (recomendado por RLS)
    try {
      final dynamic result = await _client.rpc(
        'resolve_email_for_username',
        params: <String, dynamic>{'p_username': username},
      );
      if (result is String && result.contains('@')) {
        Logger.d('Email resuelto vía RPC para usuario "$username"');
        return result;
      }
    } catch (_) {
      // Si no existe la función o no hay permisos, seguimos con consultas directas
    }

    const List<String> candidateTables = <String>[
      'user_profiles',
      'profiles',
      'users',
    ];
    const List<String> candidateUsernameColumns = <String>[
      'username',
      'user',
      'nick',
      'name',
    ];

    for (final String table in candidateTables) {
      for (final String column in candidateUsernameColumns) {
        try {
          final List<dynamic> rows = await _client
              .from(table)
              .select('email')
              .ilike(column, username)
              .limit(1);
          if (rows.isNotEmpty) {
            final dynamic value = rows.first['email'];
            if (value is String && value.contains('@')) {
              Logger.d(
                'Email resuelto en $table.$column para usuario "$username"',
              );
              return value;
            }
          }
        } catch (_) {
          // Puede fallar por RLS/tabla inexistente; probamos siguiente combinación
        }
      }
    }
    return null;
  }
}
