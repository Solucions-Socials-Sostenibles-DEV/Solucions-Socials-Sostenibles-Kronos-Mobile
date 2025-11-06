// =====================================================
// CONFIGURACIÓN DE SUPABASE - ARCHIVO DE EJEMPLO
// =====================================================
// 
// INSTRUCCIONES:
// 1. Copia este archivo a supabase_config.dart
// 2. Reemplaza los valores con tus credenciales reales
// 3. NO commitees supabase_config.dart (está en .gitignore)
//
// Las credenciales están en:
// ../KRONOS DESKTOP/Solucions-Socials-Sostenibles-Kronos/src/config/supabase.js

class SupabaseConfig {
  // URL de tu proyecto Supabase
  static const String url = 'https://tu-proyecto-id.supabase.co';
  
  // Anon key de Supabase (pública pero mejor no committearla)
  static const String anonKey = 'tu-anon-key-aqui';
  
  // OPCIONAL: Usar variables de entorno (recomendado para producción)
  // static String get url => Platform.environment['SUPABASE_URL'] ?? 'https://...';
  // static String get anonKey => Platform.environment['SUPABASE_ANON_KEY'] ?? '...';
}

